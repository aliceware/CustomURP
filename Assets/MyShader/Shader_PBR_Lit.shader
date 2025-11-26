Shader "Custom/PBR/Lit"
{
    Properties
    {
        
        [Main(PBR, _, on, off)] _pbr("PBR", float) = 0
        
        [Title(BaseColor)]
        [Sub(PBR)]_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        //[Sub(PBR)]_BaseTex ("BaseTex", 2D) = "white" {}
        
        // [Sub(PBR)]_ORMTex ("ORMTex", 2D) = "white" {}
        [Sub(PBR)]_Metallic("Metallic", Range(0, 1)) = 1.0
        [Sub(PBR)]_Roughness("Roughness", Range(0, 1)) = 1.0

        
        // [Sub(PBR)]_IrrandianceCube("Irrandiance Map",Cube) = "Skybox" {}
        [Sub(PBR)]_IBLPrefilteredSpecularMap("IBL Prefiltered Specular Map",Cube) = "Skybox" {}
        [Sub(PBR)]_BRDFLut("BRDF Lut",2D) = "white" {}
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
            // 只包含光照计算文件即可
            #include "Assets/MyShader/Common/PBRLitPass.hlsl"
            
            // CBUFFER_START(UnityPerMaterial)
            //     float4 _MainTex_ST;
            //     float4 _Diffuse;
            // CBUFFER_END

            // TEXTURE2D(_MainTex);
            // SAMPLER(sampler_MainTex);
            // 声明顶点着色器和像素着色器
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
    // GUI引入
    CustomEditor "LWGUI.LWGUI"
}
