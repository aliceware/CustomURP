#ifndef WL_LIGHTING
#define WL_LIGHTING

#include "Common/WLCore.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Common/WLLitInput.hlsl"
#include "Common/Vfx.hlsl"

// If lightmap is not defined than we evaluate GI (ambient + probes) from SH
// We might do it fully or partially in vertex to save shader ALU
#if !defined(LIGHTMAP_ON)
// TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
#if defined(SHADER_API_GLES) || !defined(_NORMALMAP)
    // Evaluates SH fully in vertex
#define EVALUATE_SH_VERTEX
#elif !SHADER_HINT_NICE_QUALITY
    // Evaluates L2 SH in vertex and L0L1 in pixel
#define EVALUATE_SH_MIXED
#endif
    // Otherwise evaluate SH fully per-pixel
#endif

#ifdef LIGHTMAP_ON
#define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
#define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
#define OUTPUT_SH(normalWS, OUT)
#else
#define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
#define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
#define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

// Renamed -> LIGHTMAP_SHADOW_MIXING
#if !defined(_MIXED_LIGHTING_SUBTRACTIVE) && defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK)
#define _MIXED_LIGHTING_SUBTRACTIVE
#endif


// Light GetMainLightHQShadow(float3 positionWS)
// {
//     Light light = GetMainLight();
//     light.shadowAttenuation = HighQualityRealtimeShadow(positionWS);
//     return light;
// }


///////////////////////////////////////////////////////////////////////////////
//                         BRDF Functions                                    //
///////////////////////////////////////////////////////////////////////////////

#define kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

struct BRDFData
{
    half3 diffuse;
    half3 specular;
    half reflectivity;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;

    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness^2 - 1.0
};

half ReflectivitySpecular(half3 specular)
{
#if defined(SHADER_API_GLES)
    return specular.r; // Red channel - because most metals are either monocrhome or with redish/yellowish tint
#else
    return max(max(specular.r, specular.g), specular.b);
#endif
}

half OneMinusReflectivityMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in kDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = kDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline void InitializeBRDFDataDirect(half3 diffuse, half3 specular, half reflectivity, half oneMinusReflectivity, half smoothness, inout half alpha, out BRDFData outBRDFData)
{
    outBRDFData.diffuse = diffuse;
    outBRDFData.specular = specular;
    outBRDFData.reflectivity = reflectivity;
    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    //u_xlat16_67
    outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN_SQRT);
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;
    outBRDFData.grazingTerm = saturate(1.0f + reflectivity);
    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;

#ifdef _ALPHAPREMULTIPLY_ON
    outBRDFData.diffuse *= alpha;
    alpha = alpha * oneMinusReflectivity + reflectivity; // NOTE: alpha modified and propagated up.
#endif
}

inline void InitializeBRDFData(half3 albedo, half metallic, half3 specular, half smoothness, inout half alpha, out BRDFData outBRDFData)
{
#ifdef _SPECULAR_SETUP
    half reflectivity = ReflectivitySpecular(specular);
    half oneMinusReflectivity = 1.0 - reflectivity;
    half3 brdfDiffuse = albedo * (half3(1.0h, 1.0h, 1.0h) - specular);
    half3 brdfSpecular = specular;
#else
    half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    half reflectivity = smoothness - oneMinusReflectivity;
    half3 brdfDiffuse = albedo * oneMinusReflectivity;
    half3 brdfSpecular = lerp(kDielectricSpec.rgb, albedo, metallic);
#endif

    InitializeBRDFDataDirect(brdfDiffuse, brdfSpecular, reflectivity, oneMinusReflectivity, smoothness, alpha, outBRDFData);
}


// Computes the specular term for EnvironmentBRDF
half3 EnvironmentBRDFSpecular(BRDFData brdfData, half fresnelTerm)
{
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    return surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
}

half3 EnvironmentBRDF(BRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
{
    half3 c = indirectDiffuse * brdfData.diffuse;
    c += indirectSpecular * EnvironmentBRDFSpecular(brdfData, fresnelTerm);
    return c;
}

// Environment BRDF without diffuse for clear coat
half3 EnvironmentBRDFClearCoat(BRDFData brdfData, half clearCoatMask, half3 indirectSpecular, half fresnelTerm)
{
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    return indirectSpecular * EnvironmentBRDFSpecular(brdfData, fresnelTerm) * clearCoatMask;
}

// Computes the scalar specular term for Minimalist CookTorrance BRDF
// NOTE: needs to be multiplied with reflectance f0, i.e. specular color to complete
half DirectBRDFSpecular(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    //u_xlat3
    float3 halfDir = SafeNormalize(float3(lightDirectionWS)+float3(viewDirectionWS));
    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
    // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    return specularTerm;
}


#if _ANISOTROPIC_ON

float3 GetAnisotropicColor(BRDFData brdfData, half3 normalWS, half3 tangentWS, half3 bitangentWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    lightDirectionWS = float3(-0.18549, 0.45839, 0.86918);
    normalWS *= float3(-1, 1, -1);
    float3 halfDir = SafeNormalize(float3(lightDirectionWS)-float3(viewDirectionWS));
    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    float2 anisotropy1 = brdfData.roughness / (1.0f - float2(_Anisotropy, _Anisotropy2) * 0.99f);
    anisotropy1 = max(anisotropy1, 0.01f);
    float2 anisotropy2 = brdfData.roughness / saturate(float2(_Anisotropy, _Anisotropy2) + 0.3f);
    anisotropy2 = max(anisotropy2, 0.01f);
    float2 anisotropicAngle = float2(_AnisoDirection, _AnisoDirection2) * PI;
    
    float2 cosA = cos(anisotropicAngle);
    float2 nSinA = sin(-anisotropicAngle);

    float3 aniso1 = nSinA.x * bitangentWS - cosA.x * tangentWS;
    aniso1 = normalize(aniso1 - dot(aniso1, normalWS) * normalWS);
    float3 aniso2 = normalize(normalWS.yzx * aniso1.zxy - normalWS.zxy * aniso1.yzx);
    float AoH1 = dot(aniso1, halfDir);
    float AoH2 = dot(aniso2, halfDir);
    float2 anisotropic1P2 = anisotropy1 * anisotropy1;
    float2 anisotropic1P4 = anisotropic1P2 * anisotropic1P2;
    AoH1 = AoH1 * AoH1 / anisotropic1P4.x;
    float2 anisotropic2P2 = anisotropy2 * anisotropy2;
    float2 anisotropic2P4 = anisotropic2P2 * anisotropic2P2;
    AoH2 = AoH2 * AoH2 / anisotropic2P4.x;
    float AoH = min(AoH1 + AoH2 + NoH * NoH, 500.0);
    float2 anisotropicP4 = anisotropic1P2 * anisotropic2P2;
    float anisoTerm1 = 1.0f / (AoH * AoH * anisotropicP4.x * PI);

    aniso1 = nSinA.y * bitangentWS - cosA.y * tangentWS;
    aniso1 = normalize(aniso1 - dot(aniso1, normalWS) * normalWS);
    aniso2 = normalize(normalWS.yzx * aniso1.zxy - normalWS.zxy * aniso1.yzx);
    AoH1 = dot(aniso1, halfDir);
    AoH2 = dot(aniso2, halfDir);
    AoH1 = AoH1 * AoH1 / anisotropic1P4.y;
    AoH2 = AoH2 * AoH2 / anisotropic2P4.y;
    AoH = min(AoH1 + AoH2 + NoH * NoH, 500.0);
    float anisoTerm2 = 1.0f / (AoH * AoH * anisotropicP4.y * PI);
    float3 anisotropicCol = (anisoTerm1 * _AnisoColor.xyz + anisoTerm2 * _AnisoColor2.xyz) * 2 / (max(0.1h, LoH * LoH) * brdfData.normalizationTerm);
    return min(anisotropicCol * brdfData.specular, float3(10.0, 10.0, 10.0));
}

#endif


// Samples SH L0, L1 and L2 terms
half3 SampleSH(half3 normalWS)
{
    // LPPV is not supported in Ligthweight Pipeline
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    return max(half3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
}

// SH Vertex Evaluation. Depending on target SH sampling might be
// done completely per vertex or mixed with L2 term per vertex and L0, L1
// per pixel. See SampleSHPixel
half3 SampleSHVertex(half3 normalWS)
{
#if defined(EVALUATE_SH_VERTEX)
    return SampleSH(normalWS);
#elif defined(EVALUATE_SH_MIXED)
    // no max since this is only L2 contribution
    return SHEvalLinearL2(normalWS, unity_SHBr, unity_SHBg, unity_SHBb, unity_SHC);
#endif

    // Fully per-pixel. Nothing to compute.
    return half3(0.0, 0.0, 0.0);
}

// SH Pixel Evaluation. Depending on target SH sampling might be done
// mixed or fully in pixel. See SampleSHVertex
half3 SampleSHPixel(half3 L2Term, half3 normalWS)
{
#if defined(EVALUATE_SH_VERTEX)
    return L2Term;
#elif defined(EVALUATE_SH_MIXED)
    half3 L0L1Term = SHEvalLinearL0L1(normalWS, unity_SHAr, unity_SHAg, unity_SHAb);
    half3 res = L2Term + L0L1Term;
#ifdef UNITY_COLORSPACE_GAMMA
    res = LinearToSRGB(res);
#endif
    return max(half3(0, 0, 0), res);
#endif

    // Default: Evaluate SH fully per-pixel
    return SampleSH(normalWS);
}

#if defined(UNITY_DOTS_INSTANCING_ENABLED)
#define LIGHTMAP_NAME unity_Lightmaps
#define LIGHTMAP_INDIRECTION_NAME unity_LightmapsInd
#define LIGHTMAP_SAMPLER_NAME samplerunity_Lightmaps
#define LIGHTMAP_SAMPLE_EXTRA_ARGS lightmapUV, unity_LightmapIndex.x
#else
#define LIGHTMAP_NAME unity_Lightmap
#define LIGHTMAP_INDIRECTION_NAME unity_LightmapInd
#define LIGHTMAP_SAMPLER_NAME samplerunity_Lightmap
#define LIGHTMAP_SAMPLE_EXTRA_ARGS lightmapUV
#endif

// Sample baked lightmap. Non-Direction and Directional if available.
// Realtime GI is not supported.
half3 SampleLightmap(float2 lightmapUV, half3 normalWS)
{
#ifdef UNITY_LIGHTMAP_FULL_HDR
    bool encodedLightmap = false;
#else
    bool encodedLightmap = true;
#endif

    half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);

    // The shader library sample lightmap functions transform the lightmap uv coords to apply bias and scale.
    // However, universal pipeline already transformed those coords in vertex. We pass half4(1, 1, 0, 0) and
    // the compiler will optimize the transform away.
    half4 transformCoords = half4(1, 1, 0, 0);

#if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
    return SampleDirectionalLightmap(TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME),
        TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_INDIRECTION_NAME, LIGHTMAP_SAMPLER_NAME),
        LIGHTMAP_SAMPLE_EXTRA_ARGS, transformCoords, normalWS, encodedLightmap, decodeInstructions);
#elif defined(LIGHTMAP_ON)
    return SampleSingleLightmap(TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME), LIGHTMAP_SAMPLE_EXTRA_ARGS, transformCoords, encodedLightmap, decodeInstructions);
#else
    return half3(0.0, 0.0, 0.0);
#endif
}

// We either sample GI from baked lightmap or from probes.
// If lightmap: sampleData.xy = lightmapUV
// If probe: sampleData.xyz = L2 SH terms
#if defined(LIGHTMAP_ON)
#define SAMPLE_GI(lmName, shName, normalWSName) SampleLightmap(lmName, normalWSName)
#else
#define SAMPLE_GI(lmName, shName, normalWSName) SampleSHPixel(shName, normalWSName)
#endif

half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion, samplerCUBE _EnvCubemap, float4 _EnvCubemap_HDR)
{
#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradiance = texCUBElod(_EnvCubemap, half4(reflectVector, mip));

#if defined(UNITY_USE_NATIVE_HDR)
    half3 irradiance = encodedIrradiance.rgb;
#else
    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, _EnvCubemap_HDR);
#endif

    return irradiance * occlusion;
#endif // GLOSSY_REFLECTIONS

    return _GlossyEnvironmentColor.rgb * occlusion;
}

half3 SubtractDirectMainLightFromLightmap(Light mainLight, half3 normalWS, half3 bakedGI)
{
    // Let's try to make realtime shadows work on a surface, which already contains
    // baked lighting and shadowing from the main sun light.
    // Summary:
    // 1) Calculate possible value in the shadow by subtracting estimated light contribution from the places occluded by realtime shadow:
    //      a) preserves other baked lights and light bounces
    //      b) eliminates shadows on the geometry facing away from the light
    // 2) Clamp against user defined ShadowColor.
    // 3) Pick original lightmap value, if it is the darkest one.


    // 1) Gives good estimate of illumination as if light would've been shadowed during the bake.
    // We only subtract the main direction light. This is accounted in the contribution term below.
    half shadowStrength = GetMainLightShadowStrength();
    half contributionTerm = saturate(dot(mainLight.direction, normalWS));
    half3 lambert = mainLight.color * contributionTerm;
    half3 estimatedLightContributionMaskedByInverseOfShadow = lambert * (1.0 - mainLight.shadowAttenuation);
    half3 subtractedLightmap = bakedGI - estimatedLightContributionMaskedByInverseOfShadow;

    // 2) Allows user to define overall ambient of the scene and control situation when realtime shadow becomes too dark.
    half3 realtimeShadow = max(subtractedLightmap, _SubtractiveShadowColor.xyz);
    realtimeShadow = lerp(bakedGI, realtimeShadow, shadowStrength);

    // 3) Pick darkest color
    return min(bakedGI, realtimeShadow);
}

half3 GlobalIllumination(BRDFData brdfData,
    half3 bakedGI, half occlusion,
    half3 normalWS, half3 viewDirectionWS,
    samplerCUBE _EnvCubemap, float4 _EnvCubemap_HDR,
    half _EnvCubemapRotation, half _EnvCubemapIntensity)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    // 对反射方向旋转
    half angle = _EnvCubemapRotation * 6.28f;
    half conAngle = cos(angle);
    half sinAngle = sin(angle);

    half x = dot(half2(conAngle, -sinAngle), reflectVector.xz);
    half z = dot(half2(sinAngle, conAngle), reflectVector.xz);
    half y = reflectVector.y;
    reflectVector = half3(x, y, z);
    half noV = 1.0f -saturate(dot(normalWS, viewDirectionWS));
    half fresnelTerm = Pow4(noV);
    half3 indirectDiffuse = bakedGI;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion, _EnvCubemap, _EnvCubemap_HDR) * _EnvCubemapIntensity;
    half3 color = EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);

    return color;
}


void MixRealtimeAndBakedGI(inout Light light, half3 normalWS, inout half3 bakedGI)
{
#if defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE)
    bakedGI = SubtractDirectMainLightFromLightmap(light, normalWS, bakedGI);
#endif
}

// Backwards compatiblity
void MixRealtimeAndBakedGI(inout Light light, half3 normalWS, inout half3 bakedGI, half4 shadowMask)
{
    MixRealtimeAndBakedGI(light, normalWS, bakedGI);
}


half3 LightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir)+float3(viewDir));
    half NdotH = saturate(dot(normal, halfVec));
    half modifier = pow(NdotH, smoothness);
    half3 specularReflection = specular.rgb * modifier;
    return lightColor * specularReflection;
}

/// 光源部分修改，加入了背光控制。
half3 LightingPhysicallyBased(BRDFData brdfData,
    half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
    half3 normalWS, half3 viewDirectionWS, half3 tangentWS, half3 bitangentWS,
    bool specularHighlightsOff,
    half _EnvBackfaceBrightness, half occlusion, half anisotropicMask, half3 sparkle)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (NdotL + (1 - NdotL) * _EnvBackfaceBrightness * occlusion);
    float directbrdfspecular = DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
    float3 brdfSpecular = directbrdfspecular * brdfData.specular;
    float3 anisotropicColor = float3(0,0,0);
#if _ANISOTROPIC_ON
    anisotropicColor = GetAnisotropicColor(brdfData, normalWS, tangentWS, bitangentWS, lightDirectionWS, viewDirectionWS);
    brdfSpecular = lerp(brdfSpecular, anisotropicColor, anisotropicMask);
#endif
    half3 brdf = brdfData.diffuse + brdfSpecular*(1.0h+sparkle);
    return brdf * radiance;
}


half3 LightingPhysicallyBased(BRDFData brdfData,
    Light light,
    half3 normalWS, half3 viewDirectionWS, half3 tangentWS, half3 bitangentWS,
    bool specularHighlightsOff,
    half _EnvBackfaceBrightness, half occlusion, half anisotropicMask, half3 sparkle)
{
    return LightingPhysicallyBased(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, tangentWS, bitangentWS, specularHighlightsOff, _EnvBackfaceBrightness, occlusion, anisotropicMask, sparkle);
}



///////////////////////////////////////////////////////////////////////////////
//                      Fragment Functions                                   //
//       Used by ShaderGraph and others builtin renderers                    //
///////////////////////////////////////////////////////////////////////////////
half4 UniversalFragmentPBR(CustomInputData inputData, CustomPBRSurfaceData surfaceData,
    samplerCUBE _EnvCubemap, float4 _EnvCubemap_HDR,
    half _EnvBackfaceBrightness, half _EnvCubemapRotation, half _EnvCubemapIntensity, half3 tangentWS, half3 bitangentWS)
{
#ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif

    BRDFData brdfData;

    // NOTE: can modify alpha
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

//#if _WL_HQ_SHADOW_ON
//    Light mainLight = GetMainLightHQShadow(inputData.positionWS);
#if _MAIN_LIGHT_SHADOWS_SCREEN
    Light mainLight = GetMainLight(inputData.shadowCoord);
#else
	Light mainLight = GetMainLight();
#endif

//return mainLight.distanceAttenuation*mainLight.shadowAttenuation;

    half3 color = GlobalIllumination(brdfData,
        inputData.bakedGI, surfaceData.occlusion,
        inputData.normalWS, inputData.viewDirectionWS,
        _EnvCubemap, _EnvCubemap_HDR,
        _EnvCubemapRotation, _EnvCubemapIntensity);

    #ifdef _CUSTOM_ENV_ON
		mainLight.direction = lerp(mainLight.direction,normalize(_CustomLightDir.xyz),_CustomLight);
        mainLight.color = lerp(mainLight.color,_CustomLightColor,_CustomLight);
        mainLight.distanceAttenuation = 1.0;//mainLight.shadowAttenuation = 1.0;
	#endif

    [branch]if(mainLight.distanceAttenuation > 0)
    {
      color += LightingPhysicallyBased(brdfData,
          mainLight,
          inputData.normalWS, inputData.viewDirectionWS, tangentWS, bitangentWS,
          specularHighlightsOff,
          _EnvBackfaceBrightness, surfaceData.occlusion, surfaceData.specular.x,surfaceData.sparkle);
    }
    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex) {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        [branch]if(light.distanceAttenuation > 0)
        {
            color += LightingPhysicallyBased(brdfData,
                light,
                inputData.normalWS, inputData.viewDirectionWS, tangentWS, bitangentWS,
                specularHighlightsOff,
                _EnvBackfaceBrightness, surfaceData.occlusion, surfaceData.specular.x,0);
        }
    }
    #endif


// Dissolve
#if defined(_DISSOLVE_ON) || defined(_GRADIENTDISSOLVE_ON)
    Dissolve(surfaceData.dissolve, 0.0h, inputData.positionWS, inputData.positionWSPivol, color.rgb, surfaceData.alpha);
#else

#endif

    return half4(color, surfaceData.alpha);
}

half4 UniversalFragmentPBR(CustomInputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission,half3 sparkle, half alpha,
    samplerCUBE _EnvCubemap, float4 _EnvCubemap_HDR,
    half _EnvBackfaceBrightness,
    half _EnvCubemapRotation, half _EnvCubemapIntensity, half3 tangentWS, half3 bitangentWS, half4 dissolve)
{
    CustomPBRSurfaceData s;
    s.albedo = albedo;
    s.metallic = metallic;
    //AnisotropicSpecular
    s.specular = specular;
    s.smoothness = smoothness;
    s.occlusion = occlusion;
    s.emission = emission;
    s.alpha = alpha;
    s.clearCoatMask = 0.0;
    s.clearCoatSmoothness = 1.0;
    s.sparkle = sparkle;
    s.dissolve = dissolve;
    return UniversalFragmentPBR(inputData, s, _EnvCubemap, _EnvCubemap_HDR, _EnvBackfaceBrightness, _EnvCubemapRotation, _EnvCubemapIntensity, tangentWS, bitangentWS);
}

#endif
