#ifndef CARTOON_LIT_AVATAR_SHADOW_PASS
#define CARTOON_LIT_AVATAR_SHADOW_PASS

#include "./ScreenDoorTransparencyHLSL.hlsl"

struct a2v {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};
struct v2f {
    float4 vertex : SV_POSITION;
    float4 positionNDC  : TEXCOORD0;
};
v2f vert(a2v v)
{
    v2f o = (v2f)0;
    float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
    half3 normalWS = TransformObjectToWorldNormal(v.normal);
    worldPos = ApplyShadowBias(worldPos, normalWS, _LightDirection);

    o.positionNDC =  TransformWorldToHClip(worldPos);
    o.vertex = TransformWorldToHClip(worldPos);
    #ifdef _VFX_DISSOLVE
        o.vertex = 0;
    #endif
    return o;
}
real4 frag(v2f i) : SV_Target
{
    #ifdef _SCREEN_DOOR_TRANSPARENCY
    float4 scrPos = i.positionNDC;
    float2 screenPos = scrPos.xy / scrPos.w;
    screenPos.xy *= _ScaledScreenParams.xy;
    ClipScreenDoorTransparency(_SDAlphaTest, _DisplayStartTime, _DisplayInOut, i.vertex.xyz, screenPos);
    #endif
    return 0;
}

#endif
