#ifndef SCENEOBJECT_LIT_SIMPLETREE_PREZ_INPUT
#define SCENEOBJECT_LIT_SIMPLETREE_PREZ_INPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);

TEXTURE2D(_RampTex);
SAMPLER(sampler_RampTex);

TEXTURE2D(_ShadowMask);
SAMPLER(sampler_ShadowMask);

TEXTURE2D(_PreBakeLightmap);
SAMPLER(sampler_PreBakeLightmap);

TEXTURE3D(_TreeLightProbeTex);
SAMPLER(sampler_TreeLightProbeTex);

sampler2D _WindNoiseTex;
half4 _SheenColorNear;
half4 _SheenColorFar;
float4 _SheenParams;
#define _SheenDistNear _SheenParams.x
#define _SheenDistFar _SheenParams.y
#define _SheenScatterMin _SheenParams.z
#define _SheenPower _SheenParams.w

 // wind tilingoffset
float4 _WindTexTiling;
// wind params
half4 _WindParams1;
#define _WindAngle _WindParams1.x
#define _WindSpeed _WindParams1.y
#define _WindBendStrength _WindParams1.z
#define _WindNoise _WindParams1.w
            
// wind params cont.
half4 _WindParams2;
#define _WindMask _WindParams2.x
#define _WindSheenInten _WindParams2.y
#define _WindDisorderFreq _WindParams2.z

#define _AmbientSkySaturate 0.2
#define _AmbientSkyIntensity 1.0
#define _AmbientEquatorSaturate 0.6
#define _AmbientEquatorIntensity 1.0
#define _AmbientGroundSaturate 0.2
#define _AmbientGroundIntensity 1.0

uniform float _BrgCrossFadeStart;
uniform float _BrgCrossFadeSpeed;

CBUFFER_START(UnityPerMaterial)
uniform float4 _WindNoiseTex_ST;
uniform half _SwingStrength;
uniform half _SwingFreq;
uniform half _WindNoiseDistortion;

uniform half4 _MainTex_ST;
uniform half4 _RimColor;
uniform half _RimIntensity;
uniform half _RimRange;
uniform half _RimSmooth;

uniform half _LTLambert;
uniform half _LTPower;
uniform half _LTScale;
uniform half _Ramp_ID;

uniform half _DirAreaMin;
uniform half _DirAreaMax;
uniform half3 _LightColor;
uniform half3 _DarkColor;

uniform half _ShadowStrength;
uniform half _BakeNormalLambert;

half _CutOffset;
half _NormalFadeOffset;

float _CrossFadeStart;
float _CrossFadeSpeed;
float _CrossFadeSign;

float4 _TreeBoundsMax;
float4 _TreeBoundsMin;
float4 _TreeLightProbeST;

CBUFFER_END

#if defined(UNITY_DOTS_INSTANCING_ENABLED)
    UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
        UNITY_DOTS_INSTANCED_PROP(float4, _TreeBoundsMax)
        UNITY_DOTS_INSTANCED_PROP(float4, _TreeBoundsMin)
        UNITY_DOTS_INSTANCED_PROP(float4, _TreeLightProbeST)
    UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

    #define _TreeBoundsMax     UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _TreeBoundsMax)
    #define _TreeBoundsMin     UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _TreeBoundsMin)
    #define _TreeLightProbeST  UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _TreeLightProbeST)
#endif

#endif
