#ifndef SCENEOBJECT_LIT_BLENDSTONE_INPUT
#define SCENEOBJECT_LIT_BLENDSTONE_INPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

uniform sampler2D _GrassDiffuse;
uniform sampler2D _MainTex;
                
TEXTURE2D(_GrassNormal);
SAMPLER(sampler_GrassNormal);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_Lightmap);
SAMPLER(sampler_Lightmap);

TEXTURE2D(_Ao);
SAMPLER(sampler_Ao);

float _BrgCrossFadeStart;
float _BrgCrossFadeSpeed;

CBUFFER_START(UnityPerMaterial)
uniform half4 _MainTex_ST;
uniform half4 _NormalMap_ST;
uniform half4 _GrassDiffuse_ST;
uniform half4 _GrassNormal_ST;
uniform half4 _Color;
uniform half _DetailBlendIntensity;
uniform half _Cutoff;
uniform half _TerrainBlendRange;

float3 _BlendDir;
float _BlendSoft;
float _BlendOffset;
float _BlendIntensity;
float _BlendHeightOffset;
half _EnableDetailBump;
half _DetailBumpScale;

half _SDAlphaTest;
half _DisplayStartTime;
half _DisplayInOut;

float4 _ObjectScale;
float4 _LightmapST;

float _CrossFadeStart;
float _CrossFadeSpeed;
float _CrossFadeSign;
half _NormalMapScale;

CBUFFER_END

#if defined(UNITY_DOTS_INSTANCING_ENABLED)
UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _ObjectScale)
    UNITY_DOTS_INSTANCED_PROP(float4, _LightmapST)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
			
#define _ObjectScale     UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _ObjectScale)
#define _LightmapST     UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LightmapST)
#endif

#endif
