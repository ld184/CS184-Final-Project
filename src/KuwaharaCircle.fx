/*
	Oilify Shader for ReShade
	
	By: Lord of Lunacy
	
	This shader applies a Kuwahara filter using an optimized method for extracting the image mean and variance.
	
	Kuwahara filter. (2020, May 01). Retrieved October 17, 2020, from https://en.wikipedia.org/wiki/Kuwahara_filter

	Kyprianidis, J. E., Kang, H., &amp; Dã¶Llner, J. (2009). Image and Video Abstraction by Anisotropic Kuwahara Filtering.
	Computer Graphics Forum, 28(7), 1955-1963. doi:10.1111/j.1467-8659.2009.01574.x
*/
// We need Compute Shader Support
#include "Reshade.fxh"	

#ifndef OILIFY_SIZE
	#define OILIFY_SIZE 8
#endif
#ifndef OILIFY_ITERATIONS
	#define OILIFY_ITERATIONS 1
#endif
#define OILIFY_PASS \
		pass \
		{ \
			VertexShader = PostProcessVS;\
			PixelShader = KuwaharaPS;\
		}\
	
	static const float PI = 3.1415926536;
	static const int K_SIZE = 12;
	static const float GAUSSIAN_WEIGHTS[5] = {0.095766,	0.303053,	0.20236,	0.303053,	0.095766};
	static const float GAUSSIAN_OFFSETS[5] = {-3.2979345488, -1.40919905099, 0, 1.40919905099, 3.2979345488};
	static const int SLICES = 8;
	static bool texge = false;


namespace Kuwahara
{
	texture texColor : COLOR;
	texture sample_out : COLOR;

	texture2D K0
	{
		// The texture dimensions (default: 1x1).
		Width = K_SIZE;
		Height = K_SIZE;
		
		// The number of mipmaps including the base level (default: 1).
		MipLevels = 1;
		
		// The internal texture format (default: RGBA8).
		// Available formats:
		//   R8, R16, R16F, R32F
		//   RG8, RG16, RG16F, RG32F
		//   RGBA8, RGBA16, RGBA16F, RGBA32F
		//   RGB10A2
		Format = R32F;

		// Unspecified properties are set to the defaults shown here.
	};

	storage2D K0Storage
	{
		// The texture to be used as storage.
		Texture = K0;

		// The mipmap level of the texture to fetch/store.
		MipLevel = 0;
	};


	sampler sBackBuffer{Texture = texColor;};
	sampler sK0{Texture = K0;};

	uniform float Sharpness<
		ui_type = "slider";
		ui_label = "Sharpness";
		ui_tooltip = "Higher settings result in a sharper image, while lower values give the\n"
					"image a more simplified look.";
		ui_min = 0; ui_max = 1;
		ui_step = 0.001;
	> = 1;

	uniform bool gen<
		ui_type = "slider";
		ui_label = "Sharpness";
		ui_tooltip = "Higher settings result in a sharper image, while lower values give the\n"
					"image a more simplified look.";
		ui_min = 0; ui_max = 1;
		ui_step = 0.001;
	> = false;

	uniform float Tuning<
		ui_type = "slider";
		ui_label = "Anistropy Tuning";
		ui_tooltip = "Adjusts how elliptical the sampling can become with anisotropy\n"
					"Smaller numbers mean more elliptical. (Use this if the shader looks stretched)";
		ui_min = 0; ui_max = 4;
	> = 2;

	uniform float Scale<
		ui_type = "slider";
		ui_label = "Scale";
		ui_tooltip = "Similar to size it raises the range the effect is applied over, \n"
					"however, the number of samples remains unchanged resulting in a less, \n"
					"detailed image.";
		ui_min = 1; ui_max = 4;
	> = 1;

	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	groupshared float Gss[K_SIZE * K_SIZE];
	groupshared float Gsr[K_SIZE * K_SIZE];
	groupshared float X0[K_SIZE * K_SIZE];

	void ExampleCS0()
	{
		if (!texge) {
			float sigma_r = 0.25 * (K_SIZE - 1);
			float sigma_s = 0.33 * sigma_r;

			for (int i = 0; i < K_SIZE; i++) {
				for (int j = 0; j < K_SIZE; j++) {
					float x_y_angle = atan2(i, j); 
					if (x_y_angle <= PI/SLICES && x_y_angle > -1 * PI/SLICES) {
						// Gsr[i * K_SIZE + j] = (1/(2 * PI * sigma_r * sigma_r))
						// 	* exp(-(i * i + j * j) / (2 * sigma_r * sigma_r));
						// Gss[i * K_SIZE + j] = (1/(2 * PI * sigma_s * sigma_s))
						// 	* exp(-(i * i + j * j) / (2 * sigma_s * sigma_s));
						X0[i * K_SIZE + j] = 1;
					}
				}
			}
			
			for (int i = 0; i < K_SIZE; i++) {
				for (int j = 0; j < K_SIZE; j++) {
					tex2Dstore(K0Storage, float2(i, j), X0[i * K_SIZE + j] 
						* Gss[(K_SIZE * K_SIZE - 1) - (i * K_SIZE + j)]
						* Gsr[i * K_SIZE + j]);
					// tex2Dstore(K0Storage, int2(i, j), float4(0, 0, 0, 0));
				}
			}
			texge=true;
		}
	}

	void KuwaharaPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 color : SV_TARGET0)
	{
		int radius = K_SIZE / 2;

		int q = 8;
		
		float4 m[SLICES];
		float3 s[SLICES];
		
		for (int k = 0; k < SLICES; ++k) {
			m[k] = float4(0, 0, 0, 0);
			s[k] = float3(0, 0, 0);
		}

		float pIn = 2.0 * PI / SLICES;

		float2x2 rotationMatrix = float2x2( 
			cos(pIn), sin(pIn),
      		-sin(pIn), cos(pIn)
		);   
		for (int j = -radius; j <= radius; j++) {
			for (int i = -radius; i <= radius; i++) {
				float2 ijVec = float2(i, j);
				float2 v = 0.5 * ijVec / radius;
				if (dot(v, v) <= 0.25) {
					float3 c = tex2D(sBackBuffer, texcoord + ijVec * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
					for (int k = 0; k < SLICES; k++) {
						float2 v_0to1 = float2(0.5, 0.5) + v;
						float w = tex2D(sK0, v_0to1).x;
						float3 temp = c * w;
						m[k] += float4(temp.x, temp.y, temp.z, w);
						s[k] += c * c * w;
						v = mul(v, rotationMatrix);
					}
				}
			}
		}
		
		float4 o = float4(0, 0, 0, 0);
		for (int k = 0; k < SLICES; k++) {
			m[k].rgb /= m[k][3]; // m[k][3] is the same as m[k].w
			s[k] = abs(s[k] / m[k][3] - m[k].rgb * m[k].rgb);

			float sigma2 = s[k].r + s[k].g + s[k].b;
			float w = 1.0 / (1.0 + pow(255 * sigma2, 0.5 * q));

			o += float4(m[k].rgb * w, w);
		}
		color = o.rgb / o[3];
	}
	
	technique KuwaharaCompute<ui_tooltip = "KuwaharaCircle is a revised version of the normal kuwahara filter,\n"
							  "By: Levy\n\n"
							  "OILIFY_SIZE: Changes the size of the filter used.\n"
							  "OILIFY_ITERATIONS: Ranges from 1 to 8.";>
	{
		pass
		{
			ComputeShader=ExampleCS0<1, 1, 1>;
			DispatchSizeX = 1;
			DispatchSizeY = 1;
		}
	}

	technique KuwaharaCircle<ui_tooltip = "KuwaharaCircle is a revised version of the normal kuwahara filter,\n"
							  "By: Levy\n\n"
							  "OILIFY_SIZE: Changes the size of the filter used.\n"
							  "OILIFY_ITERATIONS: Ranges from 1 to 8.";>
	{		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = KuwaharaPS;
		}
#if OILIFY_ITERATIONS > 1
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 2
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 3
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 4
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 5
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 6
	OILIFY_PASS
#endif
#if OILIFY_ITERATIONS > 7
	OILIFY_PASS
#endif	
	}
}