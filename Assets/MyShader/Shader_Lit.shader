Shader "Custom/Traditional/Lit"
{
    Properties
    {
        
        [Main(PBR, _, on, off)] _pbr("PBR", float) = 1
//        [Sub(PBR)]_MainTex ("Texture", 2D) = "white" {}
        [Sub(PBR)]_BaseColor ("Diffuse", Color) = (1, 1, 1, 1)
        [Title(Diffuse)]
        [KWEnum(PBR, Lambert, _DIFFUSE_LAMBERT, HalfLambert, _DIFFUSE_HALFLAMBERT)] _DiffuseType("Diffuse Type", float) = 0
        [Title(Specular)]
        [KWEnum(PBR, Phong, _SPECULAR_PHONG, BlinnPhong, _SPECULAR_BLINNPHONG)] _SpecularType("Specular Type", float) = 0
        [Sub(PBR)]_SpecularPower ("Specular Power", Range(1, 256)) = 10
        [Title(Environment)]
        [KWEnum(PBR, Ambient, _ENVIRONMENT_AMBIENT, Cubemap, _ENVIRONMENT_CUBEMAP)] _EnvironmentType("Environment Type", float) = 0
        [Sub(PBR)][ShowIf(_EnvironmentType, Equal, 0)] _Ambient("Ambient", color) = (1, 1, 1, 1)
        [Sub(PBR)][ShowIf(_EnvironmentType, Equal, 1)] _Cubemap("Cubemap", Cube) = "Skybox"{}
        [Sub(PBR)]_EnvironmentIntensity("Environment Intensity", Range(0, 1)) = 0.5
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
            #include "Assets/MyShader/Common/litPass.hlsl"
            
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
