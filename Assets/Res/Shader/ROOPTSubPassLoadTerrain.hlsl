#ifndef RO_OPT_SubPassLoad_Terrain
#define RO_OPT_SubPassLoad_Terrain

#include "./ROOPTSubPassLoadUntils.hlsl"

RO_TERRAIN_DECLARE_INPUT;

struct TerrainSubPassOut
{
    half3 directColor;
    half3 indirectColor;
    half depth;
};

TerrainSubPassOut GetTerrainOutput(float2 uv)
{
    TerrainSubPassOut output;
    float4 directColor = GET_TERRAIN_LOAD_COLOR_DEPTH(uv);
    float4 indirectColor = GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(uv);
    Depth16bit depthInput;
    depthInput.depthFront = directColor.w;
    depthInput.depthBack = indirectColor.w;

    float depth = DecodeDepth16bit(depthInput);
    output.directColor = directColor;
    output.indirectColor = indirectColor;
    output.depth = depth;

    return output;
}

half3 BlendTerrainColor(float3 ase_screenPosNorm, half _TerrainBlendRange, half3 directColor, half3 indirectColor, half3 lightColor)
{
    half3 finalColor = 1;
#if defined(RO_TERRAIN_LOAD) 
    float linearEyeTrueDepth = LinearEyeDepth(ase_screenPosNorm.z,_ZBufferParams);
    TerrainSubPassOut terOut = GetTerrainOutput(ase_screenPosNorm.xy );

    float linearEyeTerrainDepth = LinearEyeDepth(terOut.depth,_ZBufferParams);


    float depthDiffer = linearEyeTerrainDepth - linearEyeTrueDepth;

    float factor = saturate(_TerrainBlendRange - depthDiffer);
    directColor = lerp(directColor, terOut.directColor, factor);
    indirectColor = lerp(indirectColor, terOut.indirectColor, factor);
#endif
    finalColor = directColor*lightColor+indirectColor;
    return finalColor;
}
#endif