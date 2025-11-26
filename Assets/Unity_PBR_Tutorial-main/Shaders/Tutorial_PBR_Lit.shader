Shader "Tutorial_PBR/Tutorial_PBR_Lit"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white" {}
        _BaseColor("Color", Color) = (0.43,0.71,0.83,1.0)

        //灯光设置
        _DirectionalLightColor ("DirectionalLightColor", Color) = (1,1,1,1)
        _LightIntensity("LightIntensity", Range(0, 10)) = 1.0
        _DirectionalLightDirection("DirectionalLightDirection", Vector) = (1,1,-1,0)

        _Metallic("Metallic", Range(0, 1)) = 1.0
        _Smoothness("Smoothness", Range(0, 1)) = 1.0

        _IrrandianceMap("Irrandiance Map",Cube) = "Skybox" {}
        _IBLPrefilteredSpecularMap("IBL Prefiltered Specular Map",Cube) = "Skybox" {}
        _BRDFLut("BRDF Lut",2D) = "white" {}
    }
    SubShader
    {
        //主要Pass
        Pass
        {
            HLSLPROGRAM

            #include "../ShaderLibrary/PBRLitPass.hlsl"
            #pragma vertex PBRLitPassVertex
            #pragma fragment PBRLitPassFragment

            ENDHLSL
        }
        
        //只是为了让物体在Unity Editor SceneView显示的Pass
//        Pass
//        {
//            Name "DepthOnly"
//            Tags{"LightMode" = "DepthOnly"}
//
//            ZWrite On
//            ColorMask 0
//            Cull Back
//
//            HLSLPROGRAM
//
//            #pragma vertex DepthOnlyVertex
//            #pragma fragment DepthOnlyFragment
//
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
//            ENDHLSL
//        }
    }
}

