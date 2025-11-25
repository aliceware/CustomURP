#ifndef SCENEOBJECT_LIT_SIMPLETREE_PREZ_SHADOW
#define SCENEOBJECT_LIT_SIMPLETREE_PREZ_SHADOW

#include "Assets/Res/Shader/SceneCommon.hlsl"

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
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
    output.pos = GetShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(v2f_ALL_SHADOW input) : SV_TARGET
{
    half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
#if _ALPHATEST_ON
    clip(c.a - 0.3);
#endif
    return 0;
}

#endif
