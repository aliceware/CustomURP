Shader "WL/PBR"
{
	Properties
	{
		[ImportNormal][ImportTangent]
        [Enum(Opaque, 0, Transparent, 1)]_SurfaceType("Surface Type", float) = 0
	
        [Enum(Off, 0, On, 1)]_ZWriteMode("ZWrite Mode", float) = 1
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("CullMode", float) = 2
		[Toggle] _ALPHATEST("Alpha Test", Float) = 0
		_Cutoff("Cutoff", Range(0, 1)) = 0

		[OpenSRGB]_BaseMap("BaseMap", 2D) = "white" {}
		[HDR]_BaseColor("BaseColor", Color) = (1, 1, 1, 1)

		[Normal]_NormalMap("NormalMap", 2D) = "bump" {}
		_NormalScale("NormalScale", Range(0, 10)) = 1
		[Toggle] _BACKFACE("BackFace Lighting On", Float) = 0

		_Mask0("PBR Mask (Metallic, Smooth, AO, Rim)", 2D) = "white" {}
		_Metallic("MetallicScale", Range(0, 5)) = 1
		_Smoothness("SmoothnessScale", Range(0, 1)) = 1
		_Specular("Specular", Range(0, 1)) = 1
		_Occlusion("Occlusion", Range(0, 1)) = 1

		[AllowNull]_Mask1("Other Mask (Detail, Anisotropic, Twinkle, Laser)", 2D) = "white" {}

		[AllowNull]_Emissionmap("Emissionmap", 2D) = "black" {}
		[HDR]_Emission("Emission Color", Color) = (0, 0, 0, 0)
		
		[Foldout] ColorPanel("色彩调节",Range(0,1)) = 0
		[FoldoutItem]_ColorIntensity("ColorIntensity", Range(0, 3)) = 1
		[FoldoutItem]_Saturation("Saturation", Range(0, 2)) = 1 //饱和度
		[FoldoutItem]_Contrast("Contrast", Range(0, 2)) = 1 //对比度

		[Foldout] SimpleDetailPanel("细节法相",Range(0,1)) = 0
		[FoldoutItem][Toggle] _Simple_Detail("Detail Normal On", Float) = 0
		[FoldoutItem][Normal][AllowNull]_Detailmap("Detailmap", 2D) = "white" {}
		[FoldoutItem]_DetailScale("DetailScale", Range(0, 10)) = 1
		
		[Foldout] AnisotropicPanel("各向异性",Range(0,1)) = 0
		[FoldoutItem][Toggle] _Anisotropic("Anisotropic On", Float) = 0
		[FoldoutItem]_AnisotropicScale("AnisotropicScale", Range(0, 1)) = 1
		[FoldoutItem]_Anisotropy("[1] Anisotropy", Range(0 , 1)) = 0
		[FoldoutItem][HDR]_AnisoColor("[1] Anisotropy Color", Color) = (0, 0, 0, 0)
		[FoldoutItem]_AnisoDirection("[1] Anisotropy Direction (PI)", Range(0 , 1)) = 0

		[FoldoutItem]_Anisotropy2("[2] Anisotropy", Range(0 , 1)) = 0
		[FoldoutItem][HDR]_AnisoColor2("[2] Anisotropy Color", Color) = (0, 0, 0, 0)
		[FoldoutItem]_AnisoDirection2("[2] Anisotropy Direction (PI)", Range(0 , 1)) = 0

		[Foldout] GlobalPanel("自定义环境",Range(0,1)) = 0
		[FoldoutItem][Toggle] _CUSTOM_ENV("Global Cubemap On", Float) = 0
		[FoldoutItem][AllowNull]_EnvCubemap("Global Cubemap (HDR)", Cube) = "grey" {}
		[FoldoutItem]_EnvCubemapRotation("Global Cubemap Rotation", Range(-1, 1)) = 0.335
		[FoldoutItem]_EnvCubemapIntensity("Global Cubemap Intensity", Float) = 1.671
		[FoldoutItem]_EnvBackfaceBrightness("Global Backface Brightness", Range(0, 1)) = 0.3
		[FoldoutItem]_EnvReflIntensity("EnvReflection Intensity", Range(0, 1)) = 0
		[FoldoutItem][HDR]_EnvReflAmbientColor("EnvReflection AmbientColor", Color) = (0.21404, 0.21404, 0.21404, 1.00)
		[FoldoutItem][HDR]_AmbSkyColor("Ambient Sky Color", Color) = (0, 0, 0, 0)
		[FoldoutItem][HDR]_AmbEquatorColor("Ambient Equator Color", Color) = (0, 0, 0, 0)
		[FoldoutItem][HDR]_AmbGroundColor("Ambient Ground Color", Color) = (0, 0, 0, 0)
		[FoldoutItem]_AmbIntensity("Ambient Intensity", Float) = 1.0
		[FoldoutItem][Toggle]_CustomLight("CustomLight", Float) = 0.0
		[FoldoutItem]_CustomLightDir("Custom LightDirection", vector) = (1, 1, 1, 0)
		[FoldoutItem]_CustomLightColor("Custom LightColor", Color) = (1, 1, 1, 0)

		//Hue
		[Foldout] HuePanel("镭射", Range(0, 1)) = 0
		[FoldoutItem][KeywordEnum(None, Simple, Map)] _HUE("Hue Model", Float) = 0
		[FoldoutItem]_HueMap("Hue Map", 2D) = "white" {}
		[FoldoutItem][HDR]_HueColor("Hue Color", Color) = (1.00, 1.00, 1.00, 0.00)
		[FoldoutItem]_HueAngle("Hue Angle", Float) = 0.0	
		[FoldoutItem]_HueSpecPower("Hue SpecPower", Float) = 0.0
		[FoldoutItem]_HueIntansity("Hue Intansity", Float) = 1.0
		[FoldoutItem]_HueSpecScale("Hue Specular Scale", Float) = 1.0
		[FoldoutItem]_HueAlphaBase("Hue Alpha Base", Float) = 1.0

		[Foldout] SparklePanel("亮片",Range(0,1)) = 0
		[FoldoutItem][Toggle] _SPARKLE("Sparkle On", Float) = 0
		[FoldoutItem]_SparkleDependency("Sparkle Dependency", Range(0, 1)) = 0.5
        [FoldoutItem]_SparkleRoughness("亮片光滑度", Range(0, 1)) = 0.5
        [FoldoutItem][AllowNull]_SparkleTex("亮片贴图", 2D) = "white" {}
		[FoldoutItem] _Shape("Shape", Range( 0 , 1)) = 0.5
		[FoldoutItem] _ShapeSmooth("ShapeSmooth", Range( 0 , 1)) = 0.5
		[FoldoutItem] _Tilling("Tilling", Float) = 200
		[FoldoutItem] _Density("Density", Range( 0 , 1)) = 0.3
		[FoldoutItem] _Intensity("Intensity", Float) = 10
		[FoldoutItem] _Noise("Noise", Range( -1 , 1)) = 0.7

		[Toggle]_EnablePlanarShadow("EnablePlanarShadow", Float) = 1.0
		[Toggle]_EnableShadowCaster("EnableShadowCaster", Float) = 1.0
	}

	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }
		LOD 300
		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward" }
			
            Cull [_CullMode]
            ZWrite [_ZWriteMode]
			ColorMask RGBA
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha

			HLSLPROGRAM

			// -------------------------------------
            // Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			//#pragma shader_feature _ _WL_HQ_SHADOW_ON
			#pragma multi_compile _ _ADDITIONAL_LIGHTS

			//
			#pragma multi_compile _ _CUSTOM_HDR_GRADING
			#pragma multi_compile_fragment _ _SHADOWS_SOFT

			// Material 
			//#pragma shader_feature_local _ _RIMLIGHT_ON
			#pragma shader_feature_local_fragment _ _SIMPLE_DETAIL_ON 
			#pragma shader_feature_local_fragment _ _ANISOTROPIC_ON
			#pragma shader_feature_local_fragment _ _ALPHATEST_ON

			//#pragma shader_feature_local_fragment _ _GLOBAL_CUBEMAP_ON
			//#pragma shader_feature_local_fragment _ _AMBIENT_LIGHT_ON
			#pragma shader_feature_local_fragment _ _CUSTOM_ENV_ON

			#pragma shader_feature_local_fragment _SURFACE_TYPE_OPAQUE _SURFACE_TYPE_TRANSPARENT
			//#pragma shader_feature_local_fragment _ _TWINKLE_ON
			#pragma shader_feature_local_fragment _ _SPARKLE_ON
			#pragma shader_feature_local_fragment _ _BACKFACE_ON
			#pragma shader_feature_local_fragment _ _HUE_SIMPLE _HUE_MAP
			//#pragma shader_feature_local _TINT_OFF _TINT_RGB _TINT_RGBA
			#include "X_PBR_Include.hlsl"
			#pragma vertex vert
			#pragma fragment frag
			
			ENDHLSL
		}
		/*UsePass"Hidden/URPDepthOnly/DepthOnly"
		UsePass"Hidden/WL_ShadowCaster/ShadowCaster"
		UsePass"Hidden/URPPlanarShadow/PlanarShadow"*/
	}
	
	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }
		LOD 200
		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward" }
			
            Cull [_CullMode]
            ZWrite [_ZWriteMode]
			ColorMask RGBA
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha

			HLSLPROGRAM

			// -------------------------------------
            // Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			//#pragma shader_feature _ _WL_HQ_SHADOW_ON
			#pragma multi_compile _ _ADDITIONAL_LIGHTS

			//
			#pragma multi_compile _ _CUSTOM_HDR_GRADING

			// Material 
			
			#pragma shader_feature_local_fragment _ _SIMPLE_DETAIL_ON 
			
			#pragma shader_feature_local_fragment _ _ALPHATEST_ON

			
			#pragma shader_feature_local_fragment _ _CUSTOM_ENV_ON

			#pragma shader_feature_local_fragment _SURFACE_TYPE_OPAQUE _SURFACE_TYPE_TRANSPARENT
			
			#pragma shader_feature_local_fragment _ _SPARKLE_ON
			#pragma shader_feature_local_fragment _ _BACKFACE_ON
			#pragma shader_feature_local_fragment _ _HUE_SIMPLE _HUE_MAP
			
			#include "X_PBR_Include.hlsl"
			#pragma vertex vert
			#pragma fragment frag
			
			ENDHLSL
		}
		/*UsePass"Hidden/URPDepthOnly/DepthOnly"
		UsePass"Hidden/WL_ShadowCaster/ShadowCaster"
		UsePass"Hidden/URPPlanarShadow/PlanarShadow"*/
	}
	
	SubShader
	{
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }
		LOD 100
		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward" }
			
            Cull [_CullMode]
            ZWrite [_ZWriteMode]
			ColorMask RGBA
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha

			HLSLPROGRAM

			// -------------------------------------
            // Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			

			//
			#pragma multi_compile _ _CUSTOM_HDR_GRADING

			// Material 
			//#pragma shader_feature_local _ _RIMLIGHT_ON
			#pragma shader_feature_local_fragment _ _SIMPLE_DETAIL_ON 
			#pragma shader_feature_local_fragment _ _ALPHATEST_ON

			#pragma shader_feature_local_fragment _ _CUSTOM_ENV_ON

			#pragma shader_feature_local_fragment _SURFACE_TYPE_OPAQUE _SURFACE_TYPE_TRANSPARENT
			
			#pragma shader_feature_local_fragment _ _BACKFACE_ON
			#pragma shader_feature_local_fragment _ _HUE_SIMPLE _HUE_MAP
			
			#include "X_PBR_Include.hlsl"
			#pragma vertex vert
			#pragma fragment frag
			
			ENDHLSL
		}
		/*UsePass"Hidden/URPDepthOnly/DepthOnly"
		UsePass"Hidden/WL_ShadowCaster/ShadowCaster"
		UsePass"Hidden/URPPlanarShadow/PlanarShadow"*/
	}
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "FoldoutShaderGUI"
}
