// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "RO/SceneObject/Unlit" {
	Properties 
	{
		[HideInInspector]_MainTex ("Albedo", 2D) = "white" {}
		[HideInInspector]_Color("Color", Color) = (1,1,1,1)
		[HideInInspector]_ROAmbientColor("Lightmap Color", Color) = (1,1,1,1)
		[HideInInspector]_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[HideInInspector]_Mode ("__mode", Float) = 0.0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("__src", Float) = 1.0
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("__dst", Float) = 0.0
		[HideInInspector][Toggle]_ZWrite ("Zwrite", Float) = 1.0
		[HideInInspector]_CutX ("__cutx", Float) = 0.0
		[HideInInspector]_CutY ("__cuty", Float) = 0.0
		[HideInInspector]_ZTest ("__ztest", Float) = 4.0		// LEqual
		[Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", Int) = 2

		[CustomHeader(ScreenDoorTransparency)]
		[Toggle(_SCREEN_DOOR_TRANSPARENCY)]_ScreenDoorToggle("纱窗测试", float) = 0
		_SDAlphaTest("纱窗Alpha测试", Range(0,1)) = 1
		_DisplayStartTime("出现消失开始时间", Range(0,1)) = 1
		_DisplayInOut("出现消失标记", Float) = 0

		[HideInInspector]_CrossFadeStart("CrossFadeStart", Float) = 1
		[HideInInspector]_CrossFadeSpeed("CrossFadeSpeed", Float) = 1
		[HideInInspector]_CrossFadeSign("CrossFadeSign", Float) = 1
	}
	
	SubShader 
	{
		Pass 
		{
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull [_Cull]
			ZTest [_ZTest]

			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
			#include "Assets/Res/Shader/AtmosphereCommon.hlsl" 
			#include "./ScreenDoorTransparencyHLSL.hlsl"

			#pragma multi_compile __ _ALPHATEST_ON
			#pragma multi_compile __ _CUT_ON
			#pragma multi_compile __ FOG_LINEAR	
			#pragma multi_compile _ _SCREEN_DOOR_TRANSPARENCY

			//CrossFade
			#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE LOD_FADE_CROSSFADE_NOBRG

			//BRG
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

			uniform float _BrgCrossFadeStart;
			uniform float _BrgCrossFadeSpeed;
			uniform half4 _LightModel_Ambient;

			CBUFFER_START(UnityPerMaterial)
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_ST;
			uniform half4 _Color;
			uniform half4 _ROAmbientColor;
			uniform half _Cutoff;
			uniform half _CutX;
			uniform half _CutY;

			half _SDAlphaTest;
			half _DisplayStartTime;
			half _DisplayInOut;

			float _CrossFadeStart;
			float _CrossFadeSpeed;
			float _CrossFadeSign;
			CBUFFER_END
			
			struct appdata_scene
			{
				float4 vertex : POSITION;
				half4 texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half4 fogFactor : TEXCOORD1;
				float3 positionWS : TEXCOORD2;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert(appdata_scene v) 
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
				o.pos = mul(UNITY_MATRIX_VP, positionWS);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);
				o.positionWS = positionWS.xyz;

				return o;
			}
			
			half4 frag(v2f i) : COLOR 
			{	
				UNITY_SETUP_INSTANCE_ID(i);

				#ifdef LOD_FADE_CROSSFADE
					#if defined(UNITY_DOTS_INSTANCING_ENABLED)
						LODCrossFadeDitheringTransition(i.pos.xyz, _BrgCrossFadeStart, _BrgCrossFadeSpeed, _CrossFadeSign);
					#else
						LODCrossFadeDitheringTransition(i.pos.xyz, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
					#endif
				#elif LOD_FADE_CROSSFADE_NOBRG
					LODCrossFadeDitheringTransition(i.pos.xyz, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
				#endif

				#ifdef _SCREEN_DOOR_TRANSPARENCY
					ClipScreenDoorTransparency(_SDAlphaTest, _DisplayStartTime, _DisplayInOut, i.positionWS.xyz, i.pos.xy);
				#endif

				half4 c = tex2D (_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				c.rgb = MixFog(c.rgb, i.fogFactor);
				
				#if _ALPHATEST_ON
					clip (c.a - _Cutoff);
				#endif				

				return c;			
			}
			ENDHLSL
		}
	} 
	CustomEditor "SceneObjectShaderGUI"
}
