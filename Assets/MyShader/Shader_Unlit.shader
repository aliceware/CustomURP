Shader "Custom/Traditional/Unlit"
{
    Properties
    {
//        [Main(PBR)]
        [Main(PBR, _, on, off)] _pbr("PBR", float) = 1
//        [Sub(PBR)]_MainTex ("Texture", 2D) = "white" {}
        [Sub(PBR)]_BaseColor ("Diffuse", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
//        Tags {
//            "RenderPipeline" = "UniversalPipeline"
//            "RenderType"="Opaque"
//            "Queue"="Geometry"
//        }
        
        Pass
        {
//            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM

            #include "Assets/MyShader/Common/UnlitPass.hlsl"
            
            // CBUFFER_START(UnityPerMaterial)
            //     float4 _MainTex_ST;
            //     float4 _Diffuse;
            // CBUFFER_END

            // TEXTURE2D(_MainTex);
            // SAMPLER(sampler_MainTex);

            #pragma vertex vert
            #pragma fragment frag

            // struct Attributes
            // {
            //     float4 vertex : POSITION;
            //     float2 uv : TEXCOORD0;
            // };
            //
            // struct Varyings
            // {
            //     float2 uv : TEXCOORD0;
            //     float4 vertex : SV_POSITION;
            //     
            // };
            //
            //
            //
            // Varyings vert (Attributes v)
            // {
            //     Varyings o;
            //     o.vertex = TransformObjectToHClip(v.vertex);
            //     o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            //     return o;
            // }
            //
            // half4 frag (Varyings i) : SV_Target
            // {
            //     // sample the texture
            //     half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv)* _Diffuse;
            //
            //     return col;
            // }
            ENDHLSL
        }
    }
    CustomEditor "LWGUI.LWGUI"
}
