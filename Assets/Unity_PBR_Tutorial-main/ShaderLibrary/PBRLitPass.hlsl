#ifndef PBR_LIT_PASS_INCLUDED
#define PBR_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// #include "Light.hlsl"
#include "BRDF.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Varings
{
    float4 positionCS : POSITION;
    float3 positionWS : TEXCOORD2;
    float3 normalWS : TEXCOORD1;
    float2 uv : TEXCOORD0;
};

float3 _BaseColor;
float _Smoothness;
float _Metallic;

samplerCUBE _IrrandianceMap;
TEXTURECUBE(_IBLPrefilteredSpecularMap);
SAMPLER(sampler_IBLPrefilteredSpecularMap);
TEXTURE2D(_BRDFLut);
SAMPLER(sampler_BRDFLut);

float3 DirectLighting(float roughness, float3 albedo, float3 lightColor, float3 f0, float NdotH, float NdotV, float NDotL, float HdotV) {
    float3 directDiffuse = albedo;
    float3 Dterm = DistributionGGX(NdotH, roughness);
    float3 Gterm = GeometrySmith(NdotV, NDotL, roughness);
    float3 Fterm = FresnelTerm(f0, HdotV);
    float coe = max((4 * NdotV * NDotL), 0.001);
    float3 directSpecular = PI * (Dterm * Gterm * Fterm) / coe;

    float kd = (1 - Fterm) * (1 - _Metallic);
    float3 directColor = (kd * directDiffuse + directSpecular) * lightColor * NDotL;

    return directColor;
}

float3 IndirectLighting(float metallic, float roughness, float3 albedo, float3 normalWS, float3 viewDirection, float3 f0, float NdotV) {
    float3 ks = fresnelSchlickRoughness(NdotV, f0, roughness);
    float3 kd = (1.0 - ks) * (1.0 - metallic);

    float3 radiance = SampleSHbyZH(normalWS);
    float3 indirectDiffuse = kd * radiance * albedo;

    float3 reflectionDir = reflect(-viewDirection, normalWS);
    float2 envBRDF = SAMPLE_TEXTURE2D_LOD(_BRDFLut, sampler_BRDFLut, float2(NdotV, roughness), 0.0).rg;
    float3 prefilteredColor = SAMPLE_TEXTURECUBE_LOD(_IBLPrefilteredSpecularMap, sampler_IBLPrefilteredSpecularMap, reflectionDir, roughness * 8);
    float3 indirectSpecular = prefilteredColor * (ks * envBRDF.x + envBRDF.y);

    float3 indirectColor = indirectDiffuse + indirectSpecular;
    return indirectColor;
}

Varings PBRLitPassVertex(Attributes input)
{
    Varings output;
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.uv = input.uv;
    return output;
}


half4 PBRLitPassFragment(Varings input)
    : SV_Target
{
    float3 albedo = _BaseColor.rgb;

    Light light = GetMainLight();
    float3 normalWS = normalize(input.normalWS);
    float3 lightColor = light.color;
    float3 lightDirection = light.direction;
    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);
    float3 halfDir = normalize(viewDirection + lightDirection);

    float NdotH = max(dot(normalWS, halfDir), 0.0);
    float NdotV = max(dot(normalWS, viewDirection), 0.0);
    float NDotL = max(dot(normalWS, lightDirection), 0.0);
    float HdotV = max(dot(halfDir, viewDirection), 0.0);

    float roughness = 1.0 - _Smoothness;
    float3 f0 = lerp(F0_CONST, albedo, _Metallic);

    float3 directColor = DirectLighting(roughness, albedo, lightColor, f0, NdotH, NdotV, NDotL, HdotV);
    float3 indirectColor = IndirectLighting(_Metallic, roughness, albedo, normalWS, viewDirection, f0, NdotV);

    float3 finalColor = indirectColor + directColor;
    return half4(finalColor, 1.0);
}

#endif

