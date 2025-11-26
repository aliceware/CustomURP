#ifndef UNLIT_PASS_INCLUDED
#define UNLIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
};

struct Varings
{
    float4 positionCS : POSITION;
    float2 uv : TEXCOORD0;
};

float4 _BaseColor;

Varings UnlitPassVertex(Attributes input)
{
    Varings output;
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.uv = input.uv;
    return output;
}

half4 UnlitPassFragment(Varings input)
    : SV_Target
{
    return _BaseColor;
}

#endif