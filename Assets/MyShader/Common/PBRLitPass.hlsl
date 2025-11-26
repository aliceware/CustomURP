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

// samplerCUBE _IrradianceCube;
TEXTURECUBE(_IBLPrefilteredSpecularMap);
SAMPLER(sampler_IBLPrefilteredSpecularMap);
TEXTURE2D(_BRDFLut);
SAMPLER(sampler_BRDFLut);

// TEXTURECUBE(_IrradianceTex);
// SAMPLER(sampler_IrradianceTex);

float3 DirectLighting(float3 albedo, float metallic, float roughness, float3 lightColor, float NdotH, float NdotL, float NdotV, float HdotV)
{
    float3 directDiffuse = albedo;
    float DTerm = DistributionGGX(roughness, NdotH);
    float GTerm = GeometrySmith(roughness, NdotV, NdotL);
    float3 FTerm = FresnelTerm(albedo, metallic, HdotV);
    float3 directSpecular = PI * DTerm * GTerm * FTerm / max(4 * NdotL * NdotV * HdotV, 0.001f);
    float kd = (1 - FTerm) * (1 - metallic);
    float3 directColor = (directDiffuse * kd + directSpecular) * lightColor * NdotL;
    return directColor;
}

float3 IndirectLighting(float3 albedo, float metallic, float roughness, float NdotV, float3 vDir, float3 normalWS)
{
    float3 cubeReflectDir = normalize(reflect(-vDir, normalWS));
    // float3 irradiance = texCUBE(_IrradianceCube, cubeReflectDir);
    float3 irradiance = SampleSHbyZH(normalWS);
    
    float ks = FresnelSchlickRoughness(albedo, metallic, NdotV, roughness);
    float kd = (1 - ks) * (1 - metallic);
    float3 indirectDiffuse = kd * albedo * irradiance;
    float3 prefilteredColor = SAMPLE_TEXTURECUBE_LOD(_IBLPrefilteredSpecularMap, sampler_IBLPrefilteredSpecularMap, cubeReflectDir, roughness * 8);
    float2 envBRDF = SAMPLE_TEXTURE2D_LOD(_BRDFLut, sampler_BRDFLut, float2(NdotV, roughness), 0.0).rg;
    float3 indirectSpecular = prefilteredColor * (ks * envBRDF.x + envBRDF.y);
    float3 indirectColor = indirectDiffuse + indirectSpecular;
    return indirectColor;
}

Varyings vert (Attributes v)
{
    Varyings o;
    o.positionCS = TransformObjectToHClip(v.positionOS);
    o.positionWS = TransformObjectToWorld(v.positionOS);
    o.normalWS = TransformObjectToWorldNormal(v.normalOS);//和普通顶点转换不一样多了一个Normal
    // o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
    o.uv = v.uv;
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
    float3 normalWS = normalize(i.normalWS);// 记得归一化！！！否则阴影是方块的
    
    float NdotL = saturate(dot(normalWS, lDir));
    float NdotH = saturate(dot(normalWS, hDir));
    float NdotV = saturate(dot(normalWS, vDir));
    float HdotV = saturate(dot(hDir, vDir));

    float4 baseTex = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.uv);
    float3 albedo = _BaseColor;
    // float4 ORMTex = SAMPLE_TEXTURE2D(_ORMTex, sampler_ORMTex, i.uv);
    // float ao = ORMTex.r;
    // float roughness = ORMTex.g;
    // float metallic = ORMTex.b;
    
    float3 directColor = DirectLighting(albedo, _Metallic, _Roughness, mainlight.color, NdotH, NdotL, NdotV, HdotV);
   
    float3 indirectColor = IndirectLighting(albedo, _Metallic, _Roughness, NdotV, vDir, normalWS);
    
    float3 finalColor = directColor + indirectColor;
    return half4(finalColor, 1);

    
}
#endif