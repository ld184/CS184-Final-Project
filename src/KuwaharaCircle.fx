/*
	Oilify Shader for ReShade
	
	By: Lord of Lunacy
	
	This shader applies a Kuwahara filter using an optimized method for extracting the image mean and variance.
	
	Kuwahara filter. (2020, May 01). Retrieved October 17, 2020, from https://en.wikipedia.org/wiki/Kuwahara_filter
	
	Kyprianidis, J. E., Kang, H., &amp; Dã¶Llner, J. (2009). Image and Video Abstraction by Anisotropic Kuwahara Filtering.
	Computer Graphics Forum, 28(7), 1955-1963. doi:10.1111/j.1467-8659.2009.01574.x
*/
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
	static const int K_SIZE = 32;
	static const float GAUSSIAN_WEIGHTS[5] = {0.095766,	0.303053,	0.20236,	0.303053,	0.095766};
	static const float GAUSSIAN_OFFSETS[5] = {-3.2979345488, -1.40919905099, 0, 1.40919905099, 3.2979345488};
	
namespace Kuwahara
{
	texture texColor : COLOR;

	sampler sBackBuffer{Texture = texColor;};
	sampler sSampleout{Texture = sample_out};

	uniform float Sharpness<
		ui_type = "slider";
		ui_label = "Sharpness";
		ui_tooltip = "Higher settings result in a sharper image, while lower values give the\n"
					"image a more simplified look.";
		ui_min = 0; ui_max = 1;
		ui_step = 0.001;
	> = 1;

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

	uniform int Slices<
		ui_type = "slider";
		ui_label = "Scale";
		ui_tooltip = "This is the kernel size.";
		ui_min = 1; ui_max = 12;
	> = 8;

	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	void SamplePS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 color : SV_TARGET0)
	{
		float sigma_r = 0.25 * (K_SIZE - 1);
		float sigma_s = 0.33 * sigma_r;

		float g_sigma_r = (1/(2 * PI * sigma_r * sigma_r))
			* exp(-(vpos.x * vpos.x + vpos.y * vpos.y) / (2 * sigma_r * sigma_r));
		float g_sigma_s = (1/(2 * PI * sigma_s * sigma_s))
			* exp(-(vpos.x * vpos.x + vpos.y * vpos.y) / (2 * sigma_s * sigma_s));

		float x_y_angle = atan2(vpos.y, vpos.x);

		

	}

	void KuwaharaPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 color : SV_TARGET0)
	{
		float radius = OILIFY_SIZE;
		
		float4 m[Slices];
		float3 s[Slices];
		
		for (int k = 0; k < Slices; ++k) {
			m[k] = float4(0, 0, 0, 0);
			s[k] = float3(0, 0, 0);
		}

		float pIn = 2.0 * PI / Slices;

		float2x2 rotationMatrix = { 
			cos(pIn), sin(pIn),
            -sin(pIn), cos(pIn)
        };   

		for (int j = -radius; j <= radius; j++) {
			for (int i = -radius; j <= radius; i++) {
				float2 ijVec = float2(i, j);
				float2 v = 0.5 * ijVec / radius;
				if (dot(v, v) <= 0.25) {
					float3 c = tex2D(sBackBuffer, texcoord + ijVec * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
					for (int k = 0; k < Slices; k++) {
						float w = tex2D(sBackBuffer, texcoord + ijVec * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
					}
				}
			}
		}
		
		float min_sigma2 = 1e+2;
		float3 min_color = float3(0, 0, 0);
		for (int k = 0; k < 4; k++) {
			m[k] /= n;
			s[k] = abs(s[k] / n - m[k] * m[k]);

			float sigma2 = s[k].x + s[k].y + s[k].z;
			if (sigma2 < min_sigma2) {
				min_sigma2 = sigma2;
				min_color = m[k];
			}
		}
		color = min_color;
	}

	technique KuwaharaCircle<ui_tooltip = "KuwaharaCircle is a revised version of the normal kuwahara filter,\n"
							  "By: Levy\n\n"
							  "OILIFY_SIZE: Changes the size of the filter used.\n"
							  "OILIFY_ITERATIONS: Ranges from 1 to 8.";>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = SamplePS;
			RenderTarget0 = sample_out;
		}
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
