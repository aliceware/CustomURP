#ifndef TOON_LIT_PASS_INCLUDED
#define TOON_LIT_PASS_INCLUDED

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


Varings ToonLitPassVertex(Attributes input)
{
    Varings output;
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.uv = input.uv;
    return output;
}

float3 _BaseColor;
float3 _Ambient;
float3 _BackColor;

float _Distance;
float _LowBoard;
float _Highlight;
float _Gloss;

half4 ToonLitPassFragment(Varings input)
    : SV_Target
{
    Light light = GetDirectionalLight();
    float3 normalWS = normalize(input.normalWS);
    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);

    float NdotL = dot(normalWS, light.direction);
    half diffuseRad = smoothstep(_LowBoard, saturate(_LowBoard + _Distance), NdotL);
    float3 diffuse = lerp(_BackColor, _BaseColor, diffuseRad);

    float3 halfDir = normalize(viewDirection + light.direction);
    // Biling-Phong
    float specularRad = pow(max(0, dot(halfDir, normalWS)), _Gloss);
    float3 specular = light.color * step(_Highlight, specularRad);

    float3 ambient = _Ambient;
    return half4(diffuse + specular + ambient, 1.0);
}

float3 _OutlineColor;
float _OutlineStrength;

Varings ToonLitOutlineVertex(Attributes input) {
    Varings output;
    float3 positionOS = input.positionOS.xyz + input.normalOS * _OutlineStrength;
    output.positionCS = TransformObjectToHClip(positionOS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = input.uv;
    return output;
}

half4 ToonLitOutlineFragment(Varings input) : SV_Target{
    return half4(_OutlineColor.xyz, 1.0);
}

#endif