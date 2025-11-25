Shader "RO/SceneObject/Lit_BakeSkinAnim" 
{
	Properties
	{
        [CustomHeader(AnimTexture)]
		_AnimTex0("Anim Tex 0", 2D) = "white" {}
		_AnimTex1("Anim Tex 1", 2D) = "white" {}
		_AnimTex2("Anim Tex 2", 2D) = "white" {}
		_Frame("Frame", Range(0.0, 5.0)) = 0.5
		_RandomOffset("Random Offset", Range(0.0, 2.0)) = 1
		_AnimScale("Anim Scale", Range(0.0, 2.0)) = 1

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

		//BRG Lightmap
		[HideInInspector]_ObjectScale ("ObjectScale", Vector) = (0,0,0,0)
		[HideInInspector]_Lightmap ("Lightmap", 2D) = "white" {}
        [HideInInspector]_LightmapST("LightmapST", Vector) = (0,0,0,0)
		[HideInInspector]_Ao ("AO", 2D) = "white" {}

		[HideInInspector]_CrossFadeStart("CrossFadeStart", Float) = 1
		[HideInInspector]_CrossFadeSpeed("CrossFadeSpeed", Float) = 1
		[HideInInspector]_CrossFadeSign("CrossFadeSign", Float) = 1
	}
	SubShader
	{
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
			
			#pragma multi_compile BAKE_SKIN_ANIM
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
			#pragma multi_compile BAKE_SKIN_ANIM
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
			#pragma multi_compile BAKE_SKIN_ANIM

			#include "./MetaSceneObj.hlsl"
			
			ENDHLSL
		}
	} 
	CustomEditor "BigCatEditor.SceneObjectGUI"
}
