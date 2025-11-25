#ifndef T4MBase
#define T4MBase
#include "Assets/Res/Shader/SceneCommon.hlsl"

CBUFFER_START(UnityPerMaterial)
sampler2D _Splat0;
sampler2D _Splat1;
sampler2D _Splat2;
sampler2D _Splat3;
sampler2D _Control;
uniform half4 _Splat0_ST;
uniform half4 _Splat1_ST;
uniform half4 _Splat2_ST;
uniform half4 _Splat3_ST;
uniform half4 _Control_ST;
half _AlbedoScale;
half4 _Color;
//uniform half _LocalHeightFog;
uniform sampler2D _GradientLightmap;
uniform float _LightmapLerp;
CBUFFER_END

struct Attributes
{
	float4 positionOS   : POSITION;
	float3 normalOS     : NORMAL;
	//float2 texcoord     : TEXCOORD0;
};

struct Varyings
{
	//float2 uv           : TEXCOORD0;
	float4 positionCS   : SV_POSITION;
};

float4 GetShadowPositionHClip(Attributes input)
{
	float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
	float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

	float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
	positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
	positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

	return positionCS;
}

Varyings ShadowPassVertex(Attributes input)
{
	Varyings output;
	//output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
	output.positionCS = GetShadowPositionHClip(input);
	return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
	//half4 c = tex2D(_MainTex, input.uv);
	//#if _ALPHATEST_ON
	//	clip(c.a - _Cutoff);
	//#endif
	return 0;
}
#endif
