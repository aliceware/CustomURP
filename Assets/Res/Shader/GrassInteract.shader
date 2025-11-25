Shader "RO/GrassInteract" 
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
	}
		SubShader
		{
			Pass
			{
				Blend SrcAlpha One

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
					half4  texcoord  : TEXCOORD0;
					half4 texcoord1   : TEXCOORD1;
					half4 color		 : COLOR;
				};

				struct v2f
				{
					float4 pos						: SV_POSITION;
					half2 uv						: TEXCOORD1;
					half4  screenPos				: TEXCOORD2;
					half4 positionWS				: TEXCOORD3;
					half4 vertexColor 				: TEXCOORD4;
					half3 center					: TEXCOORD5;
				};

				v2f vert(a2v v)
				{
					v2f o = (v2f)0;
					o.positionWS = mul(UNITY_MATRIX_M, v.vertex);
					
					o.pos = mul(unity_MatrixVP_OP, o.positionWS);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

					float4 screenPos = ComputeScreenPos(o.pos);
					o.screenPos = screenPos;
					o.vertexColor = v.color;
					o.center = v.texcoord1.xyz;
					return o;   
				}

				half4 frag(v2f i) : SV_Target
				//RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
				{
					float4 screenPos = i.screenPos;
					float4 ase_screenPosNorm = screenPos / screenPos.w;
	
					
					//float depth = GET_SUBPASS_LOAD_DEPTH(ase_screenPosNorm.xy);
	
					float4 color;

					float4 mainTex = tex2D(_MainTex, i.uv);
					color.rg = i.uv;
					float range = 1 - saturate(length(i.uv - 0.5) + 0.5);
					
					float alpha = mainTex.a * i.vertexColor.a;
	
					return float4(i.center.xyz, alpha);
				//	float3 colorT = GET_TERRAIN_LOAD_COLOR_DEPTH(ase_screenPosNorm.xy).rgb;
				//	float3 colorT2 = GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(ase_screenPosNorm.xy).rgb;
    //return float4(colorT2, 1);

					//return SubPassOutputColor(c, i.screendepth);
				}
				ENDHLSL 
			}
		} 
}
