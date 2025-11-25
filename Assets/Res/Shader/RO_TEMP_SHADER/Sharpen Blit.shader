Shader "RO/Sharpen Blit"
{
	SubShader
	{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
		LOD 100
		ZTest Always ZWrite Off Cull Off

		Pass
		{
			Name "Blit"

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct a2v
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
			};

			struct v2f
			{
				half4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			float Intensity;

			TEXTURE2D_X(_MainTex);
			SAMPLER(sampler_LinearClamp);
			float4 _MainTex_TexelSize;

			v2f Vertex(a2v input)
			{
				v2f output;
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
				output.uv = UnityStereoTransformScreenSpaceTex(input.uv);
				return output;
			}

			half4 Fragment(v2f input) : SV_Target
			{
				half4 col = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv);

				half4 col1 = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv + float2(0, _MainTex_TexelSize.y));
				if (col1.a < 0.005)
				{
					col1 = col;
				}
				half4 col2 = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv + float2(0, -_MainTex_TexelSize.y));
				if (col2.a < 0.005)
				{
					col2 = col;
				}
				half4 col3 = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv + float2(-_MainTex_TexelSize.x, 0));
				if (col3.a < 0.005)
				{
					col3 = col;
				}
				half4 col4 = SAMPLE_TEXTURE2D_X(_MainTex, sampler_LinearClamp, input.uv + float2(_MainTex_TexelSize.x, 0));
				if (col4.a < 0.005)
				{
					col4 = col;
				}

				half4 col5 = (col + col1 + col2 + col3 + col4) / 5;

				col = lerp(col5, col, Intensity);
				return col;
			}
			ENDHLSL
		}
	}
}
