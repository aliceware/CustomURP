Shader "RO/SceneObject/Lit_Probe" 
{
	Properties
	{
        [CustomHeader(BaseTexture)]
        [Enum(None, 0, Emission, 1, Transparent, 2, CutOut, 3)] _BaseAlphaType ("Base Alpha Type", Float) = 0
		[MainTexture]_MainTex("Albedo", 2D) = "white" {}
		[ShowIf(_BaseAlphaType, Equal, 3)]_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [ShowIf(_BaseAlphaType, Equal, 1)]_EmissionIntensity ("Emission Intensity", Float) = 1
		_Color("Color", Color) = (1,1,1,1)
        [ShowIf(_BaseAlphaType, Equal, 4)]_ScatterRadius ("Scatter Radius", Float) = 4
        [ShowIf(_BaseAlphaType, Equal, 4)]_ScatterIntensity ("Scatter Intensity", Float) = 1

		[CustomHeader(NormalMap)]
		[Enum(NoNormal, 0, Specular, 2)]_EnableNormalMap("Normal Map Alpha Type", Float) = 0
		_NormalMap("Normal Map(RG:Normal|B:Rough|A:Metallic)", 2D) = "white" {}
		_NormalScale("Normal Scale", Range(0.0, 2.0)) = 1

        [CustomHeader(Blend)]
		_TerrainBlendRange("Terrain Blend Range", Range(0.0, 2.0)) = 1
		[Toggle]_ZWrite("ZWrite", Float)	= 1.0
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Int)		= 2

		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("__src", Float) = 1.0
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("__dst", Float) = 0.0

		[CustomHeader(ScreenDoorTransparency)]
        [Toggle(_SCREEN_DOOR_TRANSPARENCY)]_ScreenDoorToggle("纱窗测试", float) = 0
        _SDAlphaTest("纱窗Alpha测试", Range(0,1)) = 1
        _DisplayStartTime("出现消失开始时间", Range(0,1)) = 1
        _DisplayInOut("出现消失标记", Float) = 0

        //BRG ShadowMask
        [HideInInspector]_TreeLightProbeTex("TreeLightProbeTex", 3D) = "white" { }
        [HideInInspector]_TreeLightProbeST("TreeLightProbeST", Vector) = (0, 0, 0, 0)
        [HideInInspector]_TreeBoundsMax("TreeBoundsMax", Vector) = (0, 0, 0, 0)
        [HideInInspector]_TreeBoundsMin("TreeBoundsMin", Vector) = (0, 0, 0, 0)

		[HideInInspector]_CrossFadeStart("CrossFadeStart", Float) = 1
		[HideInInspector]_CrossFadeSpeed("CrossFadeSpeed", Float) = 1
		[HideInInspector]_CrossFadeSign("CrossFadeSign", Float) = 1
	}

	SubShader
	{
		LOD 200

        HLSLINCLUDE
		#pragma multi_compile LIT_PROBE
		#include_with_pragmas "./SceneObject-LitInput.hlsl"
        ENDHLSL

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


			#include_with_pragmas "./SceneObject-LitForwardBasePragma.hlsl"
			#include "./SceneObject-LitForwardBase.hlsl"

			ENDHLSL
		}
		
		Pass
		{ 
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}
			
			ZWrite On
			ZTest LEqual
			Cull[_Cull]

			HLSLPROGRAM
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment
			#include "./SceneObject-LitShadow.hlsl"
			ENDHLSL
		}
		
		Pass
		{
			Name "Meta"
			Tags{"LightMode" = "Meta"}

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex ROVertexMeta
			#pragma fragment ROFragmentMeta

			#pragma shader_feature _ALPHATEST_ON

			#include "./MetaSceneObj.hlsl"
			
			ENDHLSL
		}
	}

	SubShader
	{
		LOD 0

        HLSLINCLUDE
		#include_with_pragmas "./SceneObject-LitInput.hlsl"
        ENDHLSL

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
			
			#pragma multi_compile LOD_HIGH_SHADER
			#include_with_pragmas "./SceneObject-LitForwardBasePragma.hlsl"
			#include "./SceneObject-LitForwardBase.hlsl"

			ENDHLSL
		}
		
		Pass
		{ 
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}
			
			ZWrite On
			ZTest LEqual
			Cull[_Cull]

			HLSLPROGRAM
			#pragma shader_feature _ALPHATEST_ON
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment
			#include "./SceneObject-LitShadow.hlsl"
			ENDHLSL
		}
		
		Pass
		{
			Name "Meta"
			Tags{"LightMode" = "Meta"}

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex ROVertexMeta
			#pragma fragment ROFragmentMeta

			#pragma shader_feature _ALPHATEST_ON

			#include "./MetaSceneObj.hlsl"
			
			ENDHLSL
		}
	}

	CustomEditor "BigCatEditor.SceneObjectGUI"
}
