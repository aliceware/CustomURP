#ifndef SceneBase
#define SceneBase
#include "./SceneCommon.hlsl"

CBUFFER_START(UnityPerMaterial)
uniform sampler2D _MainTex;
samplerCUBE _CubeMap;
uniform sampler2D _GradientLightmap;
//uniform sampler2D	_SoftEdgeTex;
//uniform float4 _SoftEdgeParam;
//uniform half4 _SoftEdgeParam2;

uniform half4 _MainTex_ST;
uniform half4 _Color;
uniform half _Cutoff;
// uniform float _LightmapLerp;
//uniform half		_EnableSoftEdge;
//uniform half _LocalHeightFog;
//uniform half4 _RimColor;
CB_ANIM_DECLARE
CBUFFER_END


#ifdef SCREEN_DOOR
uniform half _TransparencyStart;
uniform half _TransparencyOffset;
#endif

struct vIn_PNTU
{
	VS_DECLARE
    half2 uv : TEXCOORD0;
    half3 normal : NORMAL;
};

struct v2f_ALL_SHADOW
{
    float4 pos : SV_POSITION;
    half2 uv : TEXCOORD0;
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
    half4 c = tex2D(_MainTex, input.uv);
#if _ALPHATEST_ON
		clip(c.a - 0.3);
#endif
    return 0;
}
#endif
