Shader "RO/SceneObject/SceneObj_PreZ"
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
		// 0:Off 1:Front 2:Back
		_Cull("Cull", Int) = 2
	}
	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" }
		Pass
		{
			ZWrite True
			Cull [_Cull]
			ZTest LEqual
			Offset 0.5, 0.5
			ColorMask 0

			Name "ForwardLit_PreZ"
			Tags{"LightMode" = "UniversalForward" }

			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag

			#include "Assets/Res/Shader/CommonHLSL.hlsl" 

			uniform sampler2D _MainTex;
			CBUFFER_START(UnityPerMaterial)
			uniform half4 _MainTex_ST;
			CBUFFER_END

			struct a2v
			{
				float4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o = (v2f)0;

				float4 positionWS = mul(UNITY_MATRIX_M,v.vertex);
				o.pos = mul(UNITY_MATRIX_VP, positionWS);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				clip(tex2D(_MainTex, i.uv).a - 0.5);
				return 0;
			}
			ENDHLSL
		}
	}
}