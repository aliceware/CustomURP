#ifndef SCENEOBJECT_LIT_BLENDSTONE_SHADOW
#define SCENEOBJECT_LIT_BLENDSTONE_SHADOW

#include "./SceneCommon.hlsl"

struct vIn_PNTU
{
    float4 vertex   : POSITION;
    half2 uv        : TEXCOORD0;
    half3 normal    : NORMAL;
};

struct v2f_ALL_SHADOW
{
    float4 pos      : SV_POSITION;
    half2 uv        : TEXCOORD0;
};

float4 GetShadowPositionHClip(vIn_PNTU input)
{
    float3 positionWS = TransformObjectToWorld(input.vertex.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normal);
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
    #if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}

v2f_ALL_SHADOW ShadowPassVertex(vIn_PNTU input)
{
    v2f_ALL_SHADOW output;
    output.pos = GetShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(v2f_ALL_SHADOW input) : SV_TARGET
{
    return 0;
}

#endif
