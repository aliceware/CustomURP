// 项目名 + 文件名 + 后缀
#ifndef BRDF_INCULDED
#define BRDF_INCULDED

#define PI 3.1415926
#define F0_CONST float3(0.04, 0.04, 0.04)
#define HALF_MIN 6.103515625e-5
#endif

// SH Coefficient
#define SH_0 float3(0.6385443, 0.7995847, 1.086517)
#define SH_1_1 float3(-0.006982066, 0.09033936, 0.2683517)
#define SH_10 float3(-0.0254237, -0.04046909, -0.07033964)
#define SH_11 float3(0.01321067, 0.02133152, 0.03752187)
#define SH_2_2 float3(0.00555649, 0.008058622, 0.0135842)
#define SH_2_1 float3(-0.01209977, -0.01827955, -0.03137401)
#define SH_20 float3(0.03305284, 0.04568866, 0.05569947)
#define SH_21 float3(-0.00970444, -0.01411674, -0.02039855)
#define SH_22 float3(0.04648884, 0.06349165, 0.0737313)


float3 SampleSH9(float3 normal)
{
    float3 res = SH_0 * 0.28209479f;

    float factor = normal.y;
    res.r += SH_1_1.r * factor * 0.48860251f;
    res.g += SH_1_1.g * factor * 0.48860251f;
    res.b += SH_1_1.b * factor * 0.48860251f;

    factor = normal.z;
    res.r += SH_10.r * factor * 0.48860251f;
    res.g += SH_10.g * factor * 0.48860251f;
    res.b += SH_10.b * factor * 0.48860251f;

    factor = normal.x;
    res.r += SH_11.r * factor * 0.48860251f;
    res.g += SH_11.g * factor * 0.48860251f;
    res.b += SH_11.b * factor * 0.48860251f;

    factor = normal.x * normal.y;
    res.r += SH_2_2.r * factor * 1.09254843f;
    res.g += SH_2_2.g * factor * 1.09254843f;
    res.b += SH_2_2.b * factor * 1.09254843f;

    factor = normal.y * normal.z;
    res.r += SH_2_1.r * factor * 1.09254843f;
    res.g += SH_2_1.g * factor * 1.09254843f;
    res.b += SH_2_1.b * factor * 1.09254843f;

    factor = -normal.x * normal.x - normal.y * normal.y + 2 * normal.z * normal.z;
    res.r += SH_20.r * factor * 0.31539157f;
    res.g += SH_20.g * factor * 0.31539157f;
    res.b += SH_20.b * factor * 0.31539157f;

    factor = normal.z * normal.x;
    res.r += SH_21.r * factor * 1.09254843f;
    res.g += SH_21.g * factor * 1.09254843f;
    res.b += SH_21.b * factor * 1.09254843f;

    factor = normal.x * normal.x - normal.y * normal.y;
    res.r += SH_22.r * factor * 0.54627421f;
    res.g += SH_22.g * factor * 0.54627421f;
    res.b += SH_22.b * factor * 0.54627421f;

    return res;
}

// ZH Coefficient
#define ZH_0 float3(0.6398811, 0.8012261, 1.088889)
#define ZH_1_1 float3(-0.01216536, 0.1336363, 0.4001575)
#define ZH_10 float3(-0.03809208, -0.06049462, -0.1050574)
#define ZH_11 float3(0.02112741, 0.03367615, 0.05849077)
#define ZH_2_2 float3(0.02163913, 0.03360078, 0.05913819)
#define ZH_2_1 float3(-0.03851316, -0.0606267, -0.1079541)
#define ZH_20 float3(0.1313344, 0.182004, 0.2227593)
#define ZH_21 float3(-0.03890901, -0.05660862, -0.08179242)
#define ZH_22 float3(0.183555, 0.2514126, 0.2932353)

// ZH to SH Coefficient
#define ZH_TO_SH_00 1.0 * PI
#define ZH_TO_SH_01 2.0 / 3.0 * PI
#define ZH_TO_SH_02 1.0 / 4.0 * PI

float3 SampleSHbyZH(float3 normal)
{
    float3 res = SH_0 * ZH_TO_SH_00 * 0.28209479f;

    float factor = normal.y;
    res.r += ZH_1_1.r * factor * ZH_TO_SH_01 * 0.48860251f;
    res.g += ZH_1_1.g * factor * ZH_TO_SH_01 * 0.48860251f;
    res.b += ZH_1_1.b * factor * ZH_TO_SH_01 * 0.48860251f;

    factor = normal.z;
    res.r += ZH_10.r * factor * ZH_TO_SH_01 * 0.48860251f;
    res.g += ZH_10.g * factor * ZH_TO_SH_01 * 0.48860251f;
    res.b += ZH_10.b * factor * ZH_TO_SH_01 * 0.48860251f;

    factor = normal.x;
    res.r += ZH_11.r * factor * ZH_TO_SH_01 * 0.48860251f;
    res.g += ZH_11.g * factor * ZH_TO_SH_01 * 0.48860251f;
    res.b += ZH_11.b * factor * ZH_TO_SH_01 * 0.48860251f;

    factor = normal.x * normal.y;
    res.r += ZH_2_2.r * factor * ZH_TO_SH_02 * 1.09254843f;
    res.g += ZH_2_2.g * factor * ZH_TO_SH_02 * 1.09254843f;
    res.b += ZH_2_2.b * factor * ZH_TO_SH_02 * 1.09254843f;

    factor = normal.y * normal.z;
    res.r += ZH_2_1.r * factor * ZH_TO_SH_02 * 1.09254843f;
    res.g += ZH_2_1.g * factor * ZH_TO_SH_02 * 1.09254843f;
    res.b += ZH_2_1.b * factor * ZH_TO_SH_02 * 1.09254843f;

    factor = -normal.x * normal.x - normal.y * normal.y + 2 * normal.z * normal.z;
    res.r += ZH_20.r * factor * ZH_TO_SH_02 * 0.31539157f;
    res.g += ZH_20.g * factor * ZH_TO_SH_02 * 0.31539157f;
    res.b += ZH_20.b * factor * ZH_TO_SH_02 * 0.31539157f;

    factor = normal.z * normal.x;
    res.r += ZH_21.r * factor * ZH_TO_SH_02 * 1.09254843f;
    res.g += ZH_21.g * factor * ZH_TO_SH_02 * 1.09254843f;
    res.b += ZH_21.b * factor * ZH_TO_SH_02 * 1.09254843f;

    factor = normal.x * normal.x - normal.y * normal.y;
    res.r += ZH_22.r * factor * ZH_TO_SH_02 * 0.54627421f;
    res.g += ZH_22.g * factor * ZH_TO_SH_02 * 0.54627421f;
    res.b += ZH_22.b * factor * ZH_TO_SH_02 * 0.54627421f;

    //漫反射的 C/PI 的1/PI移到了这里。
    return res / PI;
}

// roughness在每个公式里都要平方
float DistributionGGX(float roughness, float NdotH)
{
    roughness = roughness * roughness;
    float a_aquare = max(roughness * roughness, HALF_MIN);// UnityTrick 保证始终有高光
    float b = NdotH * NdotH * (a_aquare - 1.0) + 1.0;
    float donum = PI * b * b;
    
    return a_aquare / donum;

}

float SchlickGGX(float roughness, float cosTheta)
{
    roughness = roughness * roughness;
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
float3 FresnelTerm(float3 albedo, float metallic, float HdotV)
{
    
    float3 F0 = F0_CONST * (1 - metallic) + albedo * metallic;// 金属高光颜色是Albedo，非金属是F0_CONST
    float3 F = F0 + (1.0 - F0) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV);
    return F;
}

float3 FresnelSchlickRoughness(float3 albedo, float metallic, float HdotV, float roughness)// 大佬复现的是NdotV
{
    float3 F0 = F0_CONST * (1 - metallic) + albedo * metallic;// 金属高光颜色是Albedo，非金属是F0_CONST
    float3 F = F0 + (max(1.0f - roughness, F0) - F0) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV) * (1.0 - HdotV);
    return F;

} 
