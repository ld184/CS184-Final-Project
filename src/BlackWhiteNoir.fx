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

namespace BlackWhiteNoir
{
	texture texColor : COLOR;
	texture sample_out : COLOR;

	texture2D K0
	{
		// The texture dimensions (default: 1x1).
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT;
		
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

	uniform float LineWidth<
		ui_type = "slider";
		ui_label = "Scale";
		ui_tooltip = "The width for each edge's line, in pixels";
		ui_min = 1; ui_max = 10;
	> = 5;

	uniform float EdgeDetectionAccuracy <
		ui_type = "drag";
		ui_min = 0.0; ui_max = 100.0;
		ui_label = "Edge Detection Accuracy";
	> = 1.0;

	uniform float3 OutlineColor <
		ui_type = "color";
		ui_label = "Outline Color";
	> = float3(0.0, 255.0, 0.0);

	uniform float EdgeSlope <
		ui_type = "drag";
		ui_min = 0.0; ui_max = 10.0;
		ui_label = "Edge Slope";
		ui_tooltip = "Ignores soft edges (less sharp corners) when increased.";
	> = 0.23;

	uniform float OutlineOpacity <
		ui_type = "drag";
		ui_min = 0.0; ui_max = 1.0;
		ui_label = "Outline Opacity";
	> = 1.0;

	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	void ExampleCS0()
	{
	}
	float3 GetEdgeSample(float2 coord, bool EdgeDetectionMode)
	{
		if (EdgeDetectionMode)
		{
			float4 depth = float4(
				ReShade::GetLinearizedDepth(coord + ReShade::PixelSize * float2(1, 0)),
				ReShade::GetLinearizedDepth(coord - ReShade::PixelSize * float2(1, 0)),
				ReShade::GetLinearizedDepth(coord + ReShade::PixelSize * float2(0, 1)),
				ReShade::GetLinearizedDepth(coord - ReShade::PixelSize * float2(0, 1)));

			return normalize(float3(float2(depth.x - depth.y, depth.z - depth.w) * ReShade::ScreenSize, 1.0));
		}
		else
		{
			return tex2D(ReShade::BackBuffer, coord).rgb;
		}
	}

	float CalculateGray(float3 c) {
		return 0.33 * (c.r + c.g + c.b);
	}

	float3 ColorToBlackWhite(float3 color) {
		float threshold = 0.5;
		float gray = CalculateGray(color);
		if (gray > threshold) {
			return float3(1, 1, 1);
		}
		return float3(0, 0, 0);
	}
	
	float random( float2 p )
	{
		return frac(sin(dot(p,float2(12.9898,78.233)))*43758.5453123);
	}

	float3 ColorToDither(float3 color, float2 uv) {
		float gray = CalculateGray(color);
		float rand = random(uv);

		if (rand > gray) {
			return float3(0, 0, 0);
		} else {
			return float3(255, 255, 255);
		}
	}

	void KuwaharaPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 color : SV_TARGET0)
	{
		// calculating whether a pixel value is black/white
		// src: https://t.ly/zyNN
		float threshold = 0.5; 
		float3 c = tex2D(sBackBuffer, texcoord).rgb;
		float gray = CalculateGray(c);
		
		// Sobel operator matrices
		const float3 Gx[3] =
		{
			float3(-1.0, 0.0, 1.0),
			float3(-2.0, 0.0, 2.0),
			float3(-1.0, 0.0, 1.0)
		};
		const float3 Gy[3] =
		{
			float3( 1.0,  2.0,  1.0),
			float3( 0.0,  0.0,  0.0),
			float3(-1.0, -2.0, -1.0)
		};
		
		float3 dotx = 0.0, doty = 0.0;
		
		// Edge detection
		for (int i = 0, j; i < 3; i++)
		{
			j = i - 1;

			dotx += Gx[i].x * GetEdgeSample(texcoord + ReShade::PixelSize * float2(-1, j), false);
			dotx += Gx[i].y * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 0, j), false);
			dotx += Gx[i].z * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 1, j), false);
			
			doty += Gy[i].x * GetEdgeSample(texcoord + ReShade::PixelSize * float2(-1, j), false);
			doty += Gy[i].y * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 0, j), false);
			doty += Gy[i].z * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 1, j), false);
		}
		
		// Boost edge detection
		dotx *= EdgeDetectionAccuracy;
		doty *= EdgeDetectionAccuracy;

		// get eight surrounding pixels 
		int numBlackPixels = 0;
		for (int i = 0, j; i < 3; i++)
		{
			j = i - 1;

			float3 l = GetEdgeSample(texcoord + ReShade::PixelSize * float2(-1, j), false);
			float3 m = GetEdgeSample(texcoord + ReShade::PixelSize * float2( 0, j), false);
			float3 r = GetEdgeSample(texcoord + ReShade::PixelSize * float2( 1, j), false);

			numBlackPixels += ColorToBlackWhite(l).x;
			if (j != 1) { // don't include the original pixel
				numBlackPixels += ColorToBlackWhite(m).x;
			}
			numBlackPixels += ColorToBlackWhite(r).x;
		}
		
		float3 tmpColor = float3(0, 0, 0);

		if (sqrt(dot(dotx, dotx) + dot(doty, doty)) >= EdgeSlope) {
			float3 outlineColor = float3(0, 0, 0);
			// if (numBlackPixels < 4) {
				// outlineColor = float3(255, 255, 255);
			// }
			tmpColor = lerp(c, outlineColor, sqrt(dot(dotx, dotx) + dot(doty, doty)) >= EdgeSlope);
			tmpColor = lerp(c, tmpColor, OutlineOpacity);
		} else {
			// tmpColor = ColorToBlackWhite(c);
			tmpColor = ColorToDither(c, texcoord);
		}

		color = tmpColor;
	}

	
	
	technique KuwaharaCompute<ui_tooltip = "BlackWhiteNoir is a revised version of the normal kuwahara filter,\n"
							  "By: Levy\n\n"
							  "OILIFY_SIZE: Changes the size of the filter used.\n"
							  "OILIFY_ITERATIONS: Ranges from 1 to 8."; enabled = true; timeout = 1; >
	{
		pass
		{
			ComputeShader=ExampleCS0<64, 1, 1>;
			DispatchSizeX = 1;
			DispatchSizeY = 1;
			DispatchSizeZ = 1;
		}
	}

	technique KuwaharaCircle<ui_tooltip = "BlackWhiteNoir is a revised version of the normal kuwahara filter,\n"
							  "By: Levy\n\n"
							  "OILIFY_SIZE: Changes the size of the filter used.\n"
							  "OILIFY_ITERATIONS: Ranges from 1 to 8.";>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = KuwaharaPS;
		}
	}
	
}