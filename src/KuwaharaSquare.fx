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
	static const float GAUSSIAN_WEIGHTS[5] = {0.095766,	0.303053,	0.20236,	0.303053,	0.095766};
	static const float GAUSSIAN_OFFSETS[5] = {-3.2979345488, -1.40919905099, 0, 1.40919905099, 3.2979345488};
	
namespace Kuwahara
{
	texture texColor : COLOR;

	sampler sBackBuffer{Texture = texColor;};

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

	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}
			

	void KuwaharaPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 color : SV_TARGET0)
	{
		float radius = OILIFY_SIZE;
		float n = (OILIFY_SIZE + 1) * (OILIFY_SIZE + 1);
		float3 m[4];
		float3 s[4];
		for (int k = 0; k < 4; ++k) {
			m[k] = float3(0, 0, 0);
			s[k] = float3(0, 0, 0);
		}

		float4 W1 = float4(-radius, -radius, 0 , 0);
		float4 W2 = float4(0, -radius, radius, 0);
		float4 W3 = float4(0, 0, radius, radius);
		float4 W4 = float4(-radius, 0, 0, radius);

		float4 W[4] = {W1, W2, W3, W4};

		for (int k = 0; k < 4; k++) {
			for (int j = W[k].y; j <= W[k].w; j++) {
				for (int i = W[k].x; i <= W[k].z; i++) {
					float3 c = tex2D(sBackBuffer, texcoord + float2(i, j) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
					m[k] += c;
					s[k] += c * c;
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

	technique KuwaharaSquare<ui_tooltip = "KuwaharaSquared is a revised version of the normal kuwahara filter,\n"
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
