Shader "Tutorial_PBR/Unity_PBR_Lit"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white" {}
        _BaseColor("Color", Color) = (0.43,0.71,0.83,1.0)

        _Metallic("Metallic", Range(0, 1)) = 1.0
        _Smoothness("Smoothness", Range(0, 1)) = 1.0
    }
    SubShader
    {
        //主要Pass
        Pass
        {
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "../ShaderLibrary/UnityPBRPass.hlsl"
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

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


