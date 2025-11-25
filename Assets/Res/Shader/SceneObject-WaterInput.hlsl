#ifndef WATER_INPUT_INCLUDED
#define WATER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)

half _MaxDepth;
float _RampOffsetInShadow;
float _DepthDistortion;
half _TransDistMin;
half _TransDistMax;

float _ReflectionStrength;



// float4 _UnderWaterSpecularOffset;
float _Specular;
float _Smoothness;

half _BumpScale;

half _EdgeFoam;

half4 _DitherPattern_TexelSize;

CBUFFER_END

float _UnderWaterReflectionStrength;
float _UnderWaterSpecular;

// half _MaxWaveHeight;
// int _DebugPass;
// half4 _VeraslWater_DepthCamParams;
// float4x4 _InvViewProjection;

// Surface textures
TEXTURE2D(_AbsorptionScatteringRamp); SAMPLER(sampler_AbsorptionScatteringRamp);
TEXTURE2D(_UnderWaterRamp); SAMPLER(sampler_UnderWaterRamp);
TEXTURE2D(_SurfaceMap); SAMPLER(sampler_SurfaceMap);
TEXTURE2D(_FoamMap); SAMPLER(sampler_FoamMap);

TEXTURE2D(_ReflectionTexture);
SAMPLER(sampler_ReflectionTexture);

TEXTURECUBE(_ReflectionCubemap);
SAMPLER(sampler_ReflectionCubemap);

TEXTURECUBE(_UnderWaterReflection);
SAMPLER(sampler_UnderWaterReflection);


struct WaterSurfaceData
{
    half3 absorption;
	half3 scattering;
    half3 normal;
    half  foam;
};

#endif // WATER_INPUT_INCLUDED