#ifndef RO_OPT_SubPassLoad_Untils_Dep
#define RO_OPT_SubPassLoad_Untils_Dep

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
///Terrain
struct Depth16bit
{
    half depthFront;
    half depthBack;
};

#define depthFactor 3
#define depthFactorBias  256

Depth16bit EncodeDepth16bit(half depth) {
    Depth16bit output;
#ifndef UNITY_REVERSED_Z
    float depthf = 1 - depth;
#else
    float depthf = depth;
#endif
    depthf = saturate(depthf * depthFactor);
    uint depth16bit = floor(depthf * 65535);
    uint depth8bitFront = depth16bit >> 8;
    uint depth8bitBack = depth16bit & 255;
    output.depthFront = 1.0 * depth8bitFront / depthFactorBias;
    output.depthBack = 1.0 * depth8bitBack / depthFactorBias;
    return output;
}

half DecodeDepth16bit(Depth16bit input) {
    uint depth8bitFront = floor(input.depthFront * depthFactorBias);
    depth8bitFront = depth8bitFront << 8;
    uint depth8bitBack = floor(input.depthBack * depthFactorBias);
    uint depth16bit = depth8bitFront | depth8bitBack;
    float depth = 1.0 * depth16bit / 65535.0;
    depth = saturate(depth / depthFactor);
#ifndef UNITY_REVERSED_Z
    depth = 1 - depth;
#endif
    return depth;
}
#endif