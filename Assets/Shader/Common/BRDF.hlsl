// 项目名 + 文件名 + 后缀
#ifndef BRDF_INCULDED
#define BRDF_INCULDED

#define PI 3.1415926
#define F0_CONST float3(0.04, 0.04, 0.04)
#define HALF_MIN 6.103515625e-5
#endif

// roughness在每个公式里都要平方

float DistributionGGX(float roughness, float NdotH)
{
    // roughness = roughness * roughness;
    float a_aquare = max(roughness * roughness, HALF_MIN);// UnityTrick 保证始终有高光
    float b = NdotH * NdotH * (a_aquare - 1.0) + 1.0;
    float donum = PI * b * b;
    
    return a_aquare / donum;

}

float SchlickGGX(float roughness, float cosTheta)
{
    // roughness = roughness * roughness;
    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    float num = cosTheta;
    float denom = cosTheta * (1.0 - k) + k;
    return num / (denom + 1e-5f);// 保证分母不为0
}

float GeometrySmith(float roughness, float NdotV, float NdotL)
{
    return SchlickGGX(roughness, NdotL) * SchlickGGX(roughness, NdotV);
}

// 菲涅尔项是三维向量
// float3 FresnelTerm(float3 albedo, float metallic, float HdotV)
// {
//     
//     float3 F0 = F0_CONST * metallic + albedo * (1 - metallic);
//     float3 F = F0 + (1.0 - F0) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV);
//     return F;
// }

float3 FresnelTerm(float3 F0, float cosA)
{
    half t = pow(1 - cosA, 5.0);
    return F0 + (1 - F0) * t;
}