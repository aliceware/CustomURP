//确保只包含一次，避免重复定义
#ifndef PBR_LIT_INCLUDE
#define PBR_LIT_INCLUDE
//光照计算相关包含文件
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "BRDF.hlsl"
//用到的shader变体定义


struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normalOS: NORMAL;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float3 normalWS: NORMAL;
    float3 positionWS: TEXCOORD1;
};
//常量缓冲区
CBUFFER_START(UnityPerMaterial)
    float4 _BaseTex_ST;
    float4 _ORMTex_ST;
    float4 _BaseColor;
    float _Metallic;
    float _Roughness;
CBUFFER_END
//纹理采样放在CBUFFER外部
//注意纹理的采样方法
TEXTURE2D(_BaseTex);
SAMPLER(sampler_BaseTex);
TEXTURE2D(_ORMTex);
SAMPLER(sampler_ORMTex);

Varyings vert (Attributes v)
{
    Varyings o;
    o.positionCS = TransformObjectToHClip(v.positionOS);
    o.positionWS = TransformObjectToWorld(v.positionOS);
    o.normalWS = TransformObjectToWorldNormal(v.normalOS);//和普通顶点转换不一样多了一个Normal
    o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
    // o.uv = v.uv;
    return o;
}

half4 frag (Varyings i): SV_TARGET
{
    Light mainlight = GetMainLight();
    float3 lDir = mainlight.direction;
    float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);//相机位置获取方法
    // reflect的定义和正直觉相反
    float3 rDir = normalize(reflect(-lDir, i.normalWS));//Phong里的rDir是镜面反射方向
    float3 hDir = normalize(lDir + vDir);// 半程向量要归一化
    
    float NdotL = saturate(dot(i.normalWS, lDir));
    float NdotH = saturate(dot(i.normalWS, hDir));
    float NdotV = saturate(dot(i.normalWS, vDir));
    float HdotV = saturate(dot(hDir, vDir));

    float4 baseTex = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.uv);
    float3 albedo = baseTex.rgb * _BaseColor;
    // float4 ORMTex = SAMPLE_TEXTURE2D(_ORMTex, sampler_ORMTex, i.uv);
    // float ao = ORMTex.r;
    // float roughness = ORMTex.g;
    // float metallic = ORMTex.b;

    
    float3 directDiffuse = albedo;
    float3 f0 = lerp(F0_CONST, albedo, _Metallic);
    float DTerm = DistributionGGX(_Roughness, NdotH);
    float GTerm = GeometrySmith(_Roughness, NdotV, NdotL);
    // float3 FTerm = FresnelTerm(albedo, _Metallic, HdotV);
    float3 FTerm = FresnelTerm(f0, HdotV);
    float3 directspecular = PI * DTerm * GTerm * FTerm / max(4 * NdotL * NdotV, 0.001);//防止分母为0

    float kd = (1 - FTerm) * (1 - _Metallic);
    
    
    float3 directColor = (directDiffuse * kd + directspecular) * mainlight.color * NdotL;
    
    float3 indirectDiffuse = 0;
    float3 indirectspecular = 0;    
    float3 indirectColor = indirectDiffuse + indirectspecular;
    
    float3 finalColor = directColor + indirectColor;
    //finalColor = directDiffuse * mainlight.color * NdotL;
    return half4(finalColor, 1);
}
#endif