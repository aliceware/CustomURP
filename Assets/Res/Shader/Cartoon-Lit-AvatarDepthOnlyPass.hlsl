#ifndef CARTOON_LIT_AVATAR_DEPTH_PASS
#define CARTOON_LIT_AVATAR_DEPTH_PASS

struct a2v
{
    float4 vertex : POSITION;
    half4 texcoord : TEXCOORD0;
};

struct v2f
{
    float4 pos : SV_POSITION;
    half2 uv : TEXCOORD1;
};

v2f DepthOnlyVertex(a2v v)
{
    v2f o = (v2f)0;

    float4 positionWS = mul(UNITY_MATRIX_M,v.vertex);
    o.pos = mul(UNITY_MATRIX_VP, positionWS);
    o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);

    return o;
}

half4 DepthOnlyFragment(v2f input) : SV_Target
{
    half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
#if !defined(_FACE) && !defined(_COLORGRADE)
    if(_BaseAlphaType == 0)
        clip(baseColor.a - 0.1);
#endif
    return 0;
}

#endif
