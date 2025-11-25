#ifndef ATMOSPHERE_COMMON
#define ATMOSPHERE_COMMON

#include "./CommonHLSL.hlsl" 

// scatter
uniform float4 ro_SunDir;
uniform float4 ro_SunColor;

uniform float4 ro_ShadowEdgeColor;

// fog
uniform float4 ro_NearFogColor;
uniform float4 ro_FarFogColor;

#define ro_RadiusFogLerpOffset ro_NearFogColor.w
#define ro_RadiusFogLerpScale ro_FarFogColor.w

sampler2D ro_FogDissolveTex;
uniform float4 ro_FogDissolveTex_ST;

// height fog
uniform float4 ro_heightFogCenter;
uniform float4 ro_heightFogParams;
uniform float4 ro_heightFogParams2;

#define HeightFogDensity ro_heightFogParams2.x 
#define HeightFogFalloff ro_heightFogParams2.y
#define HeightFogExponent ro_heightFogParams2.z

// local height fog
uniform float4 ro_localHeightFogParams;
uniform float4 ro_localHeightFogColor;
uniform float4 ro_localHeightFogFadeParams;

#define ro_EnableLocalHeightFogFade ro_localHeightFogFadeParams.x 

float GetScatterPhase(float vol, float expo)
{
    return pow(saturate(vol), expo);
}

float GetLinearFogFactor(float val)
{
    return val * unity_FogParams.z + unity_FogParams.w;
}

float GetLinearHeightFogFactor(float val)
{
    return val * ro_heightFogParams.z + ro_heightFogParams.w;
}

// 距离雾远近插值
float GetRadiusFogLerpFactor(float val)
{
    return val * ro_RadiusFogLerpScale + ro_RadiusFogLerpOffset;
}

// 高度雾和距离雾混合
float MixLinearHeightFog(float fogFactor, float fogHFactor)
{
    fogFactor = saturate(fogFactor);
    fogHFactor = saturate(fogHFactor);
    return saturate(fogFactor + fogHFactor - fogHFactor * fogFactor);
}

float4 ComputeLinearFogFactor(float3 positionWS, float z)
{
    float clipZ = UNITY_Z_0_FAR_FROM_CLIPSPACE(z);
    float4 fogFactor = 0;
    float radiusDensityFactor = GetLinearFogFactor(clipZ);
    float3 viewDirWS = GetCameraPositionWS() - positionWS.xyz;
    float cameraDensityFactor = GetLinearHeightFogFactor(-viewDirWS.y);
    
    fogFactor.x = MixLinearHeightFog(radiusDensityFactor, cameraDensityFactor);

    half vol = dot(normalize(viewDirWS), ro_SunDir.xyz);
    float scatterFactor = GetScatterPhase(vol, HeightFogExponent);
    scatterFactor *= HeightFogDensity;
    fogFactor.y = scatterFactor;

    fogFactor.z = saturate(GetRadiusFogLerpFactor(clipZ));

    if (ro_localHeightFogParams.x > 0)
    {
        fogFactor.w = 1 - clamp((positionWS.y - ro_localHeightFogParams.y) / ro_localHeightFogParams.z, 0, 1);
        if(ro_EnableLocalHeightFogFade > 0){
            fogFactor.w *= saturate(clipZ * ro_localHeightFogFadeParams.y + ro_localHeightFogFadeParams.z);
        }
    }

    return fogFactor;
}

// 远近雾
float3 GetFogColor(float fogColorFactor)
{
    float3 fogColor = unity_FogColor.rgb;

    // 远近雾
    float4 nearFogColor = ro_NearFogColor;
    float4 farFogColor = ro_FarFogColor;
    fogColor = lerp(nearFogColor.rgb, farFogColor.rgb, fogColorFactor);

    return fogColor;
}


// 混合雾效，带散射
// fogFactor.x = Fog Density Factor
// fogFactor.y = Scatter Fog Factor
// fogFactor.z = Near/Far Fog Lerp Factor
// fogFactor.w = World Height Fog Factor

float3 MixFog(float3 fragColor, float4 fogFactor){
    #if defined(FOG_LINEAR)
        float lerpFactor = fogFactor.x;
        float3 fogColor = GetFogColor(fogFactor.z);
        fogColor = lerp(fogColor, ro_SunColor.rgb, fogFactor.y);
        fragColor = lerp(fogColor, fragColor, lerpFactor);

        float worldHeightFogFactor = fogFactor.w * ro_localHeightFogParams.x;
        fragColor = lerp(fragColor, ro_localHeightFogColor.rgb, worldHeightFogFactor);
    #endif
    return fragColor;
}

float3 MixFogVFX(float3 fragColor, float4 fogFactor, float blendMode = 0){
    #if defined(FOG_LINEAR)
        float lerpFactor = fogFactor.x;
        float3 fogColor = GetFogColor(fogFactor.z);
        fogColor = lerp(fogColor, ro_SunColor.rgb, fogFactor.y);
        fogColor = blendMode == 0 ? fogColor.rgb : fogColor.rgb * fragColor;
        fragColor = lerp(fogColor, fragColor, lerpFactor);

        float worldHeightFogFactor = fogFactor.w * ro_localHeightFogParams.x;
        fogColor = blendMode == 0 ? ro_localHeightFogColor.rgb : ro_localHeightFogColor.rgb * fragColor;
        fragColor = lerp(fragColor, fogColor, worldHeightFogFactor);
    #endif
    return fragColor;
}

#endif