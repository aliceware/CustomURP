Shader "RO/SceneObject/Water_Lod"
{
	Properties
	{
        [CustomHeader(RampTexture)]
		_AbsorptionScatteringRamp("Color Ramp", 2D) = "black"{}
		_RampOffsetInShadow("Ramp Offset In Shadow", Range(0,1)) = 0.2
		_MaxDepth("MaximumVisibility", Float) = 73
		_DepthDistortion("Depth Distortion", Range(0,300)) = 150
        [MinMaxSlider(_TransDistMin, _TransDistMax)] _TransDist("Transparent Distance", Range(0, 5000)) = 0
        [HideInInspector] _TransDistMin("Transparent Distance Min", Range(0, 5000)) = 1000
        [HideInInspector] _TransDistMax("Transparent Distance Max", Range(0, 5000)) = 3000

        [CustomHeader(Reflection)]
		_ReflectionCubemap("Reflection Cubemap", Cube) = "black"{}
		_ReflectionStrength("Reflection Strength", Range(0,1)) = 1

        [CustomHeader(Lighting)]
		_Specular("Specular", Range(0,1)) = 0.95
		_Smoothness("Smoothness", Range(0,1)) = 0.95

        [CustomHeader(Bump)]
		_SurfaceMap ("Surface Bump Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Range(0, 2)) = 0.2//fine detail multiplier

        [CustomHeader(Foam)]
		_FoamMap ("Foam Map", 2D) = "white" {}
		_EdgeFoam("Edge Foam Amount", Range(0, 1)) = 1//fine detail multiplier

        [CustomHeader(Debug)]
		[KeywordEnum(Off, SSS, Refraction, Reflection, Normal, Fresnel, Foam, WaterDepth)] _Debug ("Debug mode", Float) = 0

        [CustomHeader(Bake)]
		_Color("Lightmap Color", Color) = (1,1,1,0.5)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent-100" "RenderPipeline" = "UniversalPipeline" }
		ZWrite On
		ZClip  False

		Pass
		{
			Name "WaterShading"
			Tags{"LightMode" = "UniversalForward"}
			Blend SrcAlpha OneMinusSrcAlpha 
			Cull Back

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			/////////////////SHADER FEATURES//////////////////
			// #pragma shader_feature _REFLECTION_CUBEMAP _REFLECTION_PROBES _REFLECTION_PLANARREFLECTION
			// #pragma shader_feature _REFLECTION_PLANARREFLECTION
			// #pragma multi_compile _ USE_STRUCTURED_BUFFER
			#pragma multi_compile __ FOG_LINEAR
			#pragma shader_feature _DEBUG_OFF _DEBUG_SSS _DEBUG_REFRACTION _DEBUG_NORMAL _DEBUG_FRESNEL _DEBUG_FOAM _DEBUG_WATERDEPTH _DEBUG_REFLECTION
						
			// -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _LODWATER

			//BRG
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

			////////////////////INCLUDES//////////////////////
			#include "SceneObject-WaterCommon.hlsl"

			//non-tess
			#pragma vertex WaterVertex
			#pragma fragment WaterFragment

			ENDHLSL
		}
	}
    CustomEditor "BigCatEditor.LWGUI"
}
