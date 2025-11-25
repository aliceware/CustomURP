Shader "RO/OverlayPassTest" 
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
	}
		SubShader
		{
			Pass
			{
			Blend One Zero


				Name "ForwardLit"
				Tags{"LightMode" = "OverlayPass"}
  
				HLSLPROGRAM 
				#pragma vertex vert  
				#pragma fragment frag
				
				#pragma multi_compile _ALPHATEST_ON

				#include "./SceneBase.hlsl"
				//#include "./ROOPTSubPassLoadUntils.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

				//FRAMEBUFFER_INPUT_FLOAT(0); 

				//sampler2D _FetchDepthTexture;

				//RO_FRAMEBUFFER_DECLARE_INPUT;
				//RO_TERRAIN_DECLARE_INPUT;
				float4x4 unity_MatrixVP_OP;

				struct a2v 
				{
					float4 vertex    : POSITION; 
					float3 normalOS  : NORMAL;
					half4  texcoord  : TEXCOORD0;
					half4  texcoord1 : TEXCOORD1;
				};

				struct v2f
				{
					float4 pos						: SV_POSITION;
					half2 uv						: TEXCOORD1;
					half4 fogFactor					: TEXCOORD2;

					half3 normalWS					: TEXCOORD3;
					//#ifdef _ADDITIONAL_LIGHTS
					float3 positionWS				: TEXCOORD4;
					//#endif
					float3 viewDirWS				: TEXCOORD5;

					#ifdef LIGHTMAP_ON
						half2 lmap					: TEXCOORD6;
					#else
						half3 vertexSH			    : TEXCOORD6;
					#endif
					
						half4 shadowCoord			: TEXCOORD7;

					#ifdef SCREEN_DOOR
						half4 screenPos				: TEXCOORD8;
					#endif
	

					half4  screenPos				: TEXCOORD9;
		
					};

				v2f vert(a2v v)
				{
					v2f o = (v2f)0;
					half4 positionWS = mul(UNITY_MATRIX_M,v.vertex);
					
					o.pos = mul(unity_MatrixVP_OP, positionWS);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

					#ifndef _NO_FOG_ON
						o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);
					#endif

					//#ifdef _ADDITIONAL_LIGHTS
						o.positionWS	= positionWS.xyz;
					//#endif
					o.viewDirWS = GetCameraPositionWS() - positionWS.xyz;

					o.normalWS		= mul((half3x3)UNITY_MATRIX_M, v.normalOS);

					o.shadowCoord	= TransformWorldToShadowCoord(positionWS.xyz);

					#if LIGHTMAP_ON
						o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					#else
						OUTPUT_SH(SafeNormalize(o.normalWS), o.vertexSH);
					#endif

					#ifdef SCREEN_DOOR
						o.screenPos = ComputeScreenPos(o.pos);
					#endif
	

	

					float4 screenPos = ComputeScreenPos(o.pos);
					o.screenPos = screenPos;

					return o;   
				}

				half4 frag(v2f i) : SV_Target
				//RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
				{
					float4 screenPos = i.screenPos;
					float4 ase_screenPosNorm = screenPos / screenPos.w;
	
	
					//float depth = GET_SUBPASS_LOAD_DEPTH(ase_screenPosNorm.xy);
	
					//float4 color = GET_SUBPASS_LOAD_COLOR_DEPTH(ase_screenPosNorm.xy);
	
					return float4(0, 1, 0, 1);
				//	float3 colorT = GET_TERRAIN_LOAD_COLOR_DEPTH(ase_screenPosNorm.xy).rgb;
				//	float3 colorT2 = GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(ase_screenPosNorm.xy).rgb;
    //return float4(colorT2, 1);

					//return SubPassOutputColor(c, i.screendepth);
				}
				ENDHLSL 
			}
		} 
}
