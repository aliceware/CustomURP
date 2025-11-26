Shader "Tutorial_PBR/Tutorial_Toon_Lit"
{
    Properties
    {
        _BaseMap("Texture",2D) = "white" {}
        _BaseColor("Color", Color) = (0.43,0.71,0.83,1.0)

        //灯光设置
        _DirectionalLightColor ("DirectionalLightColor", Color) = (1,1,1,1)
        _LightIntensity("LightIntensity", Range(0, 10)) = 1.0
        _DirectionalLightDirection("DirectionalLightDirection", Vector) = (1,1,-1,0)

        _Gloss("Gloss", Range(1.0, 256)) = 20
        _Highlight("High Light", Range(0.1, 1)) = 0.2

        _BackColor("BackColor", Color) = (1,1,1,1)
        _Ambient("Ambient", Color) = (0.1,0.1,0.1,1)
        _Distance("Distance", Range(0,1)) = 1
        _LowBoard("Low Board", Range(0, 1)) = 0.2

        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineStrength("Outline Strength", Range(0, 0.5)) = 0.02
    }
    SubShader
    {
        //主要Pass
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM

            #include "../ShaderLibrary/ToonLitPass.hlsl"
            #pragma vertex ToonLitPassVertex
            #pragma fragment ToonLitPassFragment

            ENDHLSL
        }

        Pass{
            Name "Outline"
            Cull Front

            Tags{"LightMode" = "SRPDefaultUnlit"}

            HLSLPROGRAM
            #include "../ShaderLibrary/ToonLitPass.hlsl"
            #pragma vertex ToonLitOutlineVertex
            #pragma fragment ToonLitOutlineFragment

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


