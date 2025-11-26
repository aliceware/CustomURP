Shader "Tutorial_PBR/Tutorial_Tranditional_Lit"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white" {}
        _BaseColor("Color", Color) = (0.43,0.71,0.83,1.0)

        //灯光设置
        _DirectionalLightColor ("DirectionalLightColor", Color) = (1,1,1,1)
        _LightIntensity("LightIntensity", Range(0, 10)) = 1.0
        _DirectionalLightDirection("DirectionalLightDirection", Vector) = (1,1,-1,0)
        
        //Keywords的使用方法：
        //https://docs.unity3d.com/6000.0/Documentation/ScriptReference/MaterialPropertyDrawer.html

        //直接漫反射配置
        [KeywordEnum(Lambert, HalfLambert)] _DiffuseType("Diffuse Type", Float) = 0
        //直接高光配置
        [KeywordEnum(Phong, BlinnPhong)] _SpecularType("Specular Type", Float) = 0
        _Gloss("Gloss", Range(1.0, 256)) = 20

        //环境光配置
        [KeywordEnum(Color, CubeMap)] _AmbientType("Ambient Type", Float) = 0
        _Ambient("Ambient", Color) = (0.1,0.1,0.1,1)
        _Environment("Environment HDR", Cube) = "Skybox" {}
        _EnvironmentStrength("Environment Strength", Range(0, 1)) = 0.5
    }
    SubShader
    {
        //主要Pass
        Pass
        {
            HLSLPROGRAM

            #include "../ShaderLibrary/TranditionalLitPass.hlsl"
            #pragma shader_feature _DIFFUSETYPE_LAMBERT _DIFFUSETYPE_HALFLAMBERT 
            #pragma shader_feature _SPECULARTYPE_PHONG _SPECULARTYPE_BLINNPHONG 
            #pragma shader_feature _AMBIENTTYPE_COLOR _AMBIENTTYPE_CUBEMAP 
            #pragma vertex TranditionalLitPassVertex
            #pragma fragment TranditionalLitPassFragment

            ENDHLSL
        }
        
        //只是为了让物体在Unity Editor SceneView显示的Pass
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}


