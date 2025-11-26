#ifndef UNLIT_PASS_INCLUDE
#define UNLIT_PASS_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

struct Attributes
{
    float4 vertex: POSITION;
    float2 uv: TEXCOORD0;
};

struct Varyings
{
    float4 vertex: POSITION;
    float2 uv: TEXCOORD0;
};

float4 _BaseColor;

Varyings vert (Attributes v)
{
    Varyings o;
    o.vertex = TransformObjectToHClip(v.vertex);
    o.uv = v.uv;
    return o;
}

half4 frag (Varyings i): SV_TARGET
{
    return _BaseColor;
}
#endif