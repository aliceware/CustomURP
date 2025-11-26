#ifndef TRANDITIONAL_LIT_PASS_INCLUDED
#define TRANDITIONAL_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

#include "Light.hlsl"

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

float4 _BaseColor;
float _Gloss;

float3 _Ambient;
samplerCUBE _Environment;
float _EnvironmentStrength;

Varings TranditionalLitPassVertex(Attributes input)
{
    Varings output;
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.uv = input.uv;
    return output;
}

half4 TranditionalLitPassFragment(Varings input)
    : SV_Target
{
    Light light = GetDirectionalLight();
    float3 normalWS = normalize(input.normalWS);
    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);

    float3 diffuse = 1;
//直接光 漫反射模型
#if _DIFFUSETYPE_LAMBERT
    diffuse = max(dot(normalWS, light.direction), 0.0) * light.color * _BaseColor.xyz;
#elif _DIFFUSETYPE_HALFLAMBERT
    float nDotl = dot(normalWS, light.direction);
    diffuse = (nDotl * 0.5 + 0.5) * light.color * _BaseColor.xyz;
#endif

    float3 specular = 0;
//直接光 高光模型
#if _SPECULARTYPE_PHONG
    // 反射向量
    float3 reflectDir = normalize(reflect(-light.direction, normalWS));
    // Phong
    specular = light.color * pow(max(0, dot(reflectDir, viewDirection)), _Gloss);
#elif _SPECULARTYPE_BLINNPHONG
    // 半程向量
    float3 halfDir = normalize(viewDirection + light.direction);
    // Biling-Phong
    specular = light.color * pow(max(0, dot(halfDir, normalWS)), _Gloss);
#endif

    float3 ambient = 0;
//间接光 漫反射模型
#if _AMBIENTTYPE_COLOR
    // 环境光
    ambient = _Ambient;
#elif _AMBIENTTYPE_CUBEMAP
    //天空盒
    float3 cubeReflectDir = normalize(reflect(-viewDirection, normalWS));
    ambient = texCUBE(_Environment, cubeReflectDir) * _EnvironmentStrength;
#endif

//间接光 高光模型
//传统光照模型中，这一项缺失，直接不考虑。
    return half4(diffuse + specular + ambient, 1.0);
}

#endif