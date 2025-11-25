Shader "RO/Editor/Lit-VertexColor" 
{
	Properties
	{
        _BaseTex("BaseTexture", 2D) = "white"{}

	}

	SubShader

	    {
            Tags{"LightMode" = "UniversalForward" "Queue" = "Transparent"}

            Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
            ZClip  False
			Cull Off

		Pass
		{
           

			
			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag

			#include "./SceneBase.hlsl"

			CBUFFER_START(UnityPerMaterial)

            sampler2D _BaseTex;
            float4 _BaseTex_ST;


			CBUFFER_END
			
			struct a2v 
			{
                VS_DECLARE
				float3 normal : NORMAL;
				half4 color : COLOR;
                float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos						 : SV_POSITION;
				float3  normalWS 				 : TEXCOORD2;
				half4 color : COLOR;
                float2 uv : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
                v2f o = (v2f)0;
                float4 posWS = mul(UNITY_MATRIX_M, v.vertex);
                o.pos = mul(UNITY_MATRIX_VP, posWS);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.color = v.color;
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
                Light light = GetMainLight();
                
                half ndotl = saturate(dot(i.normalWS, light.direction));
                half4 base = tex2D(_BaseTex, i.uv);

                half3 c = light.color * ndotl * base.rgb * i.color;
				return half4(c, base.a); 
			}
			ENDHLSL
		}

	}
}
