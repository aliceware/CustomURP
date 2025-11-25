#ifndef SCENEOBJECT_LIT_CLOUD
#define SCENEOBJECT_LIT_CLOUD

#include "./CommonUtilities.hlsl"

half4 _CloudData;

float4x4 _CloudProjMatrix;
half _CloudDisorderFreq;

#define _CloudSpeed _CloudProjMatrix[3].xy
#define _CloudType _CloudProjMatrix[3].z // 0: no cloud, 1: cloud shadow, 2:underwater caustic
#define _CloudStrength _CloudProjMatrix[3].w

TEXTURE2D(_CloudShadowTex);
SAMPLER(sampler_CloudShadowTex);

half GetCloudShadow(half3 positionWS, float shadowAttenuation, float ao)
{
    if(_CloudType == 0)
        return shadowAttenuation;

    float time = _Time.y % 1000;
    float4 cloudPlanePosition = mul(_CloudProjMatrix, float4(positionWS, 0.0));
    float2 cloudUV = cloudPlanePosition.xy + time * _CloudSpeed;

    cloudUV = frac(cloudUV);
    // cloudUV = clamp((cloudUV-0.5) * _CloudScale, -0.5, 0.5)+0.5;
    half4 cloudRGBA = SAMPLE_TEXTURE2D(_CloudShadowTex, sampler_CloudShadowTex, cloudUV);
    half cloud = ChannelBlend(cloudRGBA, time);

    cloud = _CloudType == 1 ? saturate(cloud-_CloudStrength+1)*shadowAttenuation : cloud*_CloudStrength*ao+shadowAttenuation;
    // cloud = 1;
    return cloud;
}

#endif
