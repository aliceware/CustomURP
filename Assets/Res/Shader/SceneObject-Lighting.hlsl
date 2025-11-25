#ifndef SCENEOBJECT_Lighting_INPUT
#define SCENEOBJECT_Lighting_INPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "./CommonHLSL.hlsl"

half3 UnpackNormalmapRG(half4 packedNormal, half scale = 1.0)
{
    half3 normal;
    normal.xy = packedNormal.xy * 2.0 - 1.0;
    normal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));
    normal.xy *= scale;
    return normal;
}

inline void UnpackNormalData(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), out half3 normalTS, out half smoothness, out half specular, half scale = 1.0)
{
    half4 bump = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);

    normalTS = UnpackNormalmapRG(bump, scale);
    smoothness = bump.z;
    specular = bump.a;
}

half3 UnpackTangentNormal(half3 normalWS, half3 normalTS, half4 tangentWS)
{
    float sgn = tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(normalWS, tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangent.xyz, normalWS);
    half3 unpackedNormalWS = TransformTangentToWorld(normalTS, tangentToWorld);
    return unpackedNormalWS;
}

float FetchOcclusionProbe(float3 positionWS, float4 boundsMax, float4 boundsMin, float4 scaleOffset, TEXTURE3D_PARAM(probeTex, sampler_probeTex))
{
    float s = boundsMax.w;
    float t = boundsMin.w;
    float3 step = boundsMax.xyz - boundsMin.xyz;
    float3 offset = positionWS - boundsMin.xyz;
    float3 uvw = offset / step;
    if (scaleOffset.z == 0 && scaleOffset.w == 0)
    {
        uvw = float3(uvw.x, uvw.z, uvw.y * scaleOffset.y + scaleOffset.x);
    }
    else
    {
        uvw = float3(uvw.x * scaleOffset.y + scaleOffset.x, uvw.z * scaleOffset.w + scaleOffset.z, uvw.y);
    }
    return SAMPLE_TEXTURE3D(probeTex, sampler_probeTex, uvw);
}

uniform half3 _IndirectColor;

struct LightInfo
{
    half3 lm;
    half ambientAO;
    half shadow;
};
#ifndef TERRAIN_LIGHT
#ifndef LIT_PROBE
LightInfo InitLightInfo(half2 lightmapUV, half3 normalWS, half distFalloff)
{
    LightInfo info;
    #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(_Lightmap, sampler_Lightmap, lightmapUV));
        info.lm = lm.rgb;
        info.shadow = lm.a;
        half normalAmbientAO = CalAmbientAO(normalWS);
        #if BRG_WITHOUT_AO
            info.ambientAO = normalAmbientAO;
        #else
            half4 ambientColor = SAMPLE_TEXTURE2D(_Ao, sampler_Ao, lightmapUV);
            info.ambientAO = lerp(ambientColor.r, normalAmbientAO, smoothstep(50, 60, distFalloff));
        #endif
    #elif LIGHTMAP_ON_INDIRECT
        half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, lightmapUV));
        info.lm = lm.rgb+_IndirectColor * lm.a;
        info.shadow = 1;
        info.ambientAO = lm.a;
    #elif LIGHTMAP_ON_NOBRG && LIGHTMAP_ON
        half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, lightmapUV));
        info.lm = lm.rgb;
        info.shadow = lm.a;
        half4 ambientColor = SAMPLE_TEXTURE2D_LIGHTMAP(unity_ShadowMask, samplerunity_ShadowMask, lightmapUV);
        half ambientAO = ambientColor.r;
        half normalAmbientAO = CalAmbientAO(normalWS);
        info.ambientAO = lerp(ambientAO, normalAmbientAO, smoothstep(50, 60, distFalloff));
    #elif LIGHTMAP_ON
        half4 lm = DecodeLightmapForEditor(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, lightmapUV));
        info.lm = lm.rgb;
        info.shadow = lm.a;
        info.ambientAO = CalAmbientAO(normalWS);
    #else
        info.lm = _IndirectColor;
        info.shadow = 1;
        info.ambientAO = CalAmbientAO(normalWS);
    #endif
    return info;
}
#else
LightInfo InitLightInfoProbe(half3 positionWS, half3 normalWS)
{
    LightInfo info;
    info.lm = _IndirectColor;
    info.ambientAO = CalAmbientAO(normalWS);
    #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        info.shadow = FetchOcclusionProbe(positionWS, _TreeBoundsMax, _TreeBoundsMin, _TreeLightProbeST, TEXTURE2D_ARGS(_TreeLightProbeTex, sampler_TreeLightProbeTex));
    #else
        info.shadow = 1;
    #endif
    return info;
}
#endif
#endif

inline void InitBRDFData(half3 albedo, half smoothness, half specular, out BRDFData brdfData)
{
    half alpha = 1;
    InitializeBRDFData(albedo, 0, half3(1,1,1), smoothness, alpha, brdfData);
    brdfData.specular *= specular;
}

half3 LightingDirect(BRDFData brdfData, half3 normalWS, half3 viewDirectionWS, Light light){
    half3 lightDirectionWS = light.direction;

    half NdotL = saturate(dot(normalWS, lightDirectionWS));

    half3 brdf = brdfData.diffuse;

    float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
    float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));

    float NoH = saturate(dot(float3(normalWS), halfDir));
    half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));

    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

#if REAL_IS_HALF
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif


    brdf += brdfData.specular * specularTerm;
    // return specularTerm;
    return brdf * NdotL;

    // return pbr;
}

half3 LightingDirectLOD(BRDFData brdfData, half3 normalWS, half3 viewDirectionWS, Light light){
    half3 lightDirectionWS = light.direction;

    half NdotL = saturate(dot(normalWS, lightDirectionWS));

    half3 brdf = brdfData.diffuse;

    return brdf * NdotL;

    // return pbr;
}

TEXTURECUBE(_ReflectCubemap);
SAMPLER(sampler_ReflectCubemap);

uniform half _ReflectIntensity;

half3 LightingIndirect(BRDFData brdfData, half3 normalWS, half3 viewDirectionWS, half3 bakedGI, half ambientAO){
    half3 ambient = CalRealtimeAmbient(ambientAO, normalWS);
    
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half fresnelTerm = Pow4(1.0 - NoV);
    half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
    // half mip = 0;
    half3 reflect = half4(SAMPLE_TEXTURECUBE_LOD(_ReflectCubemap, sampler_ReflectCubemap, reflectVector, mip)).rgb * _ReflectIntensity;
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    reflect = reflect * half3(surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm)) * ambientAO;

    half3 indirectGI = ambient + bakedGI + reflect;
    return brdfData.albedo * indirectGI;
}

half3 LightingIndirectLOD(BRDFData brdfData, half3 normalWS, half3 viewDirectionWS, half3 bakedGI, half ambientAO){
    half3 ambient = CalRealtimeAmbient(ambientAO, normalWS);

    half3 indirectGI = ambient + bakedGI;
    return brdfData.albedo * indirectGI;
}

#endif
