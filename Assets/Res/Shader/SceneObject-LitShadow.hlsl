#ifndef SCENEOBJECT_LIT_SHADOW
#define SCENEOBJECT_LIT_SHADOW

#include "./SceneCommon.hlsl"

struct vIn_PNTU
{
    float4 vertex   : POSITION;
    half3 normal    : NORMAL;
    half2 uv        : TEXCOORD0;
#ifdef BAKE_SKIN_ANIM
    float2 boneInfluences : TEXCOORD2; 
    float2 boneIds  : TEXCOORD3; 
#endif
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
    
#ifdef BAKE_SKIN_ANIM
    float3 originWS = mul(UNITY_MATRIX_M, float4(0,0,0,1)).xyz;
    float timeOffset = RandomSeed(originWS)*_RandomOffset;
    float4x4 skinMatrix = CalculateSkinMatrix(input.boneIds, input.boneInfluences, timeOffset, _Frame);
    float4 skinVertex = mul(skinMatrix, input.vertex);
    input.vertex = lerp(input.vertex, skinVertex, _AnimScale);
#endif

    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
    output.pos = GetShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(v2f_ALL_SHADOW input) : SV_TARGET
{
    half4 c = tex2D(_MainTex, input.uv);
    #if _ALPHATEST_ON
    clip(c.a - 0.3);
    #endif
    return 0;
}

#endif
