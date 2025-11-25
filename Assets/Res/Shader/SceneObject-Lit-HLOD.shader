Shader "RO/SceneObject/Lit-HLOD" 
{
	Properties
	{
		[HideInInspector]_Mode("__mode", Float) = 0.0
		[HideInInspector]_SrcBlend("__src", Float) = 1.0
		[HideInInspector]_DstBlend("__dst", Float) = 0.0
		[HideInInspector]_ZWrite("__zw", Float)	= 1.0
		[HideInInspector]_Cull("Cull", Int)		= 2

		[HideInInspector]_CrossFadeStart("CrossFadeStart", Float) = 1
		[HideInInspector]_CrossFadeSpeed("CrossFadeSpeed", Float) = 1
		[HideInInspector]_CrossFadeSign("CrossFadeSign", Float) = 1
	}

	SubShader
	{
		Pass
		{
			Blend[_SrcBlend][_DstBlend] 
			ZWrite[_ZWrite]
			Cull[_Cull]

			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
				
			#pragma multi_compile __ FOG_LINEAR
			#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE

			#include "./SceneBase.hlsl"

			CBUFFER_START(UnityPerMaterial)

			float _CrossFadeStart;
			float _CrossFadeSpeed;
			float _CrossFadeSign;

			CBUFFER_END
			
			struct a2v 
			{
				VS_DECLARE
				float3 normal : NORMAL;
				half4 color : COLOR;
			};

			struct v2f
			{
				float4 pos						 : SV_POSITION;
				half4 fogFactor				 	 : TEXCOORD1;
				float3  normalWS 				 : TEXCOORD2;
				half4 color : COLOR;
			};

			v2f vert(a2v v)
			{
				VS_SKINNING_NORMAL(v)
				v2f o = (v2f)0;
				half4 positionWS = mul(UNITY_MATRIX_M,v.vertex);
					
				o.pos = mul(UNITY_MATRIX_VP, positionWS);
				
				#ifndef _NO_FOG_ON
					o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);
				#else
					#ifdef LOCAL_HEIGHT_FOG
						o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);
					#endif
				#endif
				o.normalWS = TransformObjectToWorldNormal(v.normal.xyz);
				o.color = v.color;
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				#ifdef LOD_FADE_CROSSFADE
					LODCrossFadeDitheringTransition(i.pos.xyz, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
				#endif

				half3 normalWS = NormalizeNormalPerPixel(i.normalWS);
				half4 c = pow(abs(i.color), 2.2);

				Light mainLight = GetMainLight();
				half NdotL = saturate(dot(normalWS, mainLight.direction));
				half3 lightColor = mainLight.color.rgb;

				half ambientAOHLOD = CalAmbientAO(normalWS);
                half3 ambientHLOD = CalRealtimeAmbient(ambientAOHLOD, normalWS);
	            half3 outPutHLOD = NdotL*lightColor*1 + ambientHLOD + i.color.a*1.5; 

	            c.rgb *= outPutHLOD.rgb;

				// half3 radiance = lightColor * NdotL;
				// half3 outPut = radiance;
				// half ambientAO = CalAmbientAO(normalWS);

                // half3 ambient = CalRealtimeAmbient(ambientAO, normalWS);
	            // outPut += ambient+ c.a;
				// c.rgb *= outPut;
				
				#ifdef FOG_LINEAR
					c.rgb = MixFog(c.rgb, i.fogFactor);
				#endif

				return c; 
			}
			ENDHLSL
		}

		//Pass
		//{ 
		//	Name "ShadowCaster"
		//	Tags{"LightMode" = "ShadowCaster"}
		//	
		//	ZWrite On
		//	ZTest LEqual
		//	Cull[_Cull]

		//	HLSLPROGRAM
		//	#pragma multi_compile __ _ALPHATEST_ON
		//	#pragma vertex ShadowPassVertex
		//	#pragma fragment ShadowPassFragment
		//	#include "./SceneBase.hlsl"
		//	ENDHLSL
		//}
	}
}
