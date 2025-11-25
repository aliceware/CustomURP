#ifndef SCENEOBJECT_LIT_INPUT
#define SCENEOBJECT_LIT_INPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
sampler2D _MainTex;

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

#ifdef LIT_PROBE
TEXTURE3D(_TreeLightProbeTex);
SAMPLER(sampler_TreeLightProbeTex);
#else
TEXTURE2D(_Lightmap);
SAMPLER(sampler_Lightmap);

TEXTURE2D(_Ao);
SAMPLER(sampler_Ao);
#endif

#ifdef LIT_CRYSTAL
TEXTURE2D(_ParallaxMap);
SAMPLER(sampler_ParallaxMap);

TEXTURE2D(_CausticMap);
SAMPLER(sampler_CausticMap);

TEXTURECUBE(_CubeMap);
SAMPLER(sampler_CubeMap);
#endif

float _BrgCrossFadeStart;
float _BrgCrossFadeSpeed;

CBUFFER_START(UnityPerMaterial)
half4 _MainTex_ST;
half4 _Color;
half _Cutoff;
half _NormalScale;
half _TerrainBlendRange;
half _EmissionIntensity;
half _ScatterRadius;
half _ScatterIntensity;
int _BaseAlphaType;

#ifdef LIT_PROBE
float4 _TreeBoundsMax;
float4 _TreeBoundsMin;
float4 _TreeLightProbeST;
#else
float4 _ObjectScale;
float4 _LightmapST;
#endif

half _SDAlphaTest;
half _DisplayStartTime;
half _DisplayInOut;

float _CrossFadeStart;
float _CrossFadeSpeed;
float _CrossFadeSign;
half _EnableNormalMap;
#ifdef BAKE_SKIN_ANIM
half _Frame;
half _RandomOffset;
half _AnimScale;
#endif
#ifdef LIT_CRYSTAL
half3 _CubeColor;
half _RimInten;
half _ParallaxScale;
#endif
CBUFFER_END



#ifdef LIT_PROBE
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
#else
    #if defined(UNITY_DOTS_INSTANCING_ENABLED)
    UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
        UNITY_DOTS_INSTANCED_PROP(float4, _ObjectScale)
        UNITY_DOTS_INSTANCED_PROP(float4, _LightmapST)
    UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
    
    #define _ObjectScale     UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _ObjectScale)
    #define _LightmapST     UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LightmapST)
    #endif
#endif

#endif
