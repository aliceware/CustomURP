Shader "Tutorial_PBR/Tutorial_Unlit"
{
    Properties
    {        
        _BaseMap("Texture",2D) = "white" {}
        _BaseColor("Color", Color) = (0.43,0.71,0.83,1.0)
    }
    SubShader
    {

        Pass
        {
            HLSLPROGRAM

            #include "../ShaderLibrary/UnlitPass.hlsl"

            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            ENDHLSL
        }


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
