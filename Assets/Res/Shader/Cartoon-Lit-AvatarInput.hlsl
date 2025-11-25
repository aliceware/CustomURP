#ifndef CARTOON_LIT_AVATAR_INPUT
#define CARTOON_LIT_AVATAR_INPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// #define RampCount 5
#define _AmbientRange 0.8
#define _AmbientSmooth 0.1
#define _AmbientStrength 0.2
#define _AmbientStrengthInShadow 1
#define _RampStrengthInShadow 0.6

#pragma multi_compile _ _SCREEN_DOOR_TRANSPARENCY
#pragma multi_compile _ _VFX_DISSOLVE
#pragma multi_compile _ _VFX_FROZEN
#pragma multi_compile _ _VFX_FRES

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_LightMap);
SAMPLER(sampler_LightMap);
TEXTURE2D(_RampTex);
SAMPLER(sampler_RampTex);
TEXTURE2D(_OutlineMap);
SAMPLER(sampler_OutlineMap);

TEXTURE2D(_CameraCharDepthTexture);
SAMPLER(sampler_CameraCharDepthTexture);

#ifndef _FACE
    TEXTURE2D(_NormalMap);
    SAMPLER(sampler_NormalMap);
    
	TEXTURE2D(_MetalTex);
	SAMPLER(sampler_MetalTex);
#endif

#ifdef _FACE
	TEXTURE2D(_FaceShadow);
	SAMPLER(sampler_FaceShadow);
#endif

#ifdef _COLORGRADE
    TEXTURE2D(_GradeRampMap);
    SAMPLER(sampler_GradeRampMap);
#endif


CBUFFER_START(UnityPerMaterial)

    half4 _AvatarLightDir;
    half4 _AvatarLightColor;
    half4 _AmbientLightColor;

#if !defined(_FACE) && !defined(_COLORGRADE)
    half _BaseAlphaType;
#endif

    float _EmissionIntensity;

    half4 _BaseColorTint;
    half4 _BaseMap_ST;
    half4 _LightMap_ST;
#ifndef _FACE
    half4 _MetalTex_ST;
    half _EnableNormalMap;
    float _SpecularPow;
    half4 _SpecularColor;
    float _MetalIntensity;
    half _RimOffset;
    half _RimStep;
    half4 _RimColor;
    half _RimIntensity;
#endif

    half _HitStartTime;
    float _HitFxIntensity;
    half4 _HitFXColor;
    float _HitFXRimPow;
    float _HitFXRimStrength;

    half _RampRangeMin;
    half _RampRangeMax;
    half _RampReflectionRange;

#ifdef _FACE
    half _DShadowStep;
    half _DShadowOffset;
    half _DShadowNormalOffset;
#endif
    

    half _UseLightMap;
    half _RampCount;

    half4 _OutlineColor;
    float _OutlineThickness;
    float _OutlineType;

#ifdef _COLORGRADE
    half _UseColorGrade;
    half _GradeFade;
    half3 _GradeColor0;
    half3 _GradeColor1;
    half3 _GradeColor2;
    half3 _GradeColor10;
    half3 _GradeColor11;
    half3 _GradeColor12;
    half _GradeRampID;
    half _GradeRampID1;
    half _GradeColorHalfPos;
    half _GradeColor1HalfPos;
    half _GradeRampCount;
#endif

    half _UIColorMask;
    half _SatValue;


    half _DissolveFactorTest;
    half _DissolveInOut;
    half _DissolveEdgeWidth;
    sampler2D _DissolveMap;
    half4 _DissolveMap_ST;
    half3 _DissolveEdgeColor;
    half3 _DissolveColor;
    half _DissolveDuration;
    half _DissolveStartTime;

    half _FrozenStartTime;
    half _FrozenDuration;
    half _FrozenFactorTest;
    half _FrozenInOut;
    sampler2D _FrozenMap;

    half _VFXFresnel;
    half _VFXFresnelPow;
    half3 _VFXFresnelColor;
    half _VFXFrenelStartTime;
    half _VFXFrenelDuration;
    half _VFXFrenelInOut;
    half _VFXFresnelIntensity;

    half _SDAlphaTest;
    half _SDCameraClip;
    half _DisplayStartTime;
    half _DisplayInOut;
    
CBUFFER_END

#ifndef _DEBUG_OFF
    half _DebugIDNum;
#endif

    half4 _LightInShadow;
    half4 _LightOutShadow;
    half4 _DarkInShadow;
    half4 _DarkOutShadow;
    float3 _LightDirection;


#endif
