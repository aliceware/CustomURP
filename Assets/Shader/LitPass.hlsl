//确保只包含一次，避免重复定义
#ifndef TRADITIONAL_LIT_INCLUDE
#define TRADITIONAL_LIT_INCLUDE
//光照计算相关包含文件
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//用到的shader变体定义
#pragma shader_feature_local _DIFFUSE_LAMBERT
#pragma shader_feature_local _DIFFUSE_HALFLAMBERT
#pragma shader_feature_local _SPECULAR_PHONG
#pragma shader_feature_local _SPECULAR_BLINNPHONG
#pragma shader_feature_local _ENVIRONMENT_AMBIENT
#pragma shader_feature_local _ENVIRONMENT_CUBEMAP

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normalOS: NORMAL;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float3 normalWS: NORMAL;
    float3 positionWS: TEXCOORD1;
};
//常量缓冲区
CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float _SpecularPower;
    float4 _Ambient;
    float _EnvironmentIntensity;
    float4 _Cubemap_ST;
CBUFFER_END
//纹理采样放在CBUFFER外部
//注意纹理的采样方法
TEXTURECUBE(_Cubemap);
SAMPLER(sampler_Cubemap);

Varyings vert (Attributes v)
{
    Varyings o;
    o.positionCS = TransformObjectToHClip(v.positionOS);
    o.positionWS = TransformObjectToWorld(v.positionOS);
    o.normalWS = TransformObjectToWorldNormal(v.normalOS);//和普通顶点转换不一样多了一个Normal
    o.uv = v.uv;
    
    return o;
}

half4 frag (Varyings i): SV_TARGET
{
    Light mainlight = GetMainLight();
    float3 lDir = mainlight.direction;
    float3 vDir = normalize(_WorldSpaceCameraPos - i.positionWS);//相机位置获取方法
    float3 rDir = normalize(reflect(-lDir, i.normalWS));
    float3 hDir = (lDir + vDir) * 0.5;
    
    float diffuse = 1.0;
    float specular = 0.0;
    float3 environment = 0.0;
    #if defined (_DIFFUSE_LAMBERT)
        diffuse = saturate(dot(lDir, normalize(i.normalWS)));
    #elif defined (_DIFFUSE_HALFLAMBERT)
        diffuse = saturate(dot(lDir, normalize(i.normalWS))) * 0.5 + 0.5;
    #endif

    #if defined (_SPECULAR_PHONG)
        specular = saturate(dot(rDir, vDir));
    #elif defined (_SPECULAR_BLINNPHONG)
        specular = saturate(dot(hDir, i.normalWS));
    #endif

    #if defined (_ENVIRONMENT_AMBIENT)
        environment = _Ambient;
    #elif defined (_ENVIRONMENT_CUBEMAP)
        float3 cuberDir = normalize(reflect(-rDir, i.normalWS));
        //Cubemap采样需要一个三维向量
        environment = SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, cuberDir);
    #endif
        
    half3 color = (diffuse * _BaseColor + pow(specular, _SpecularPower) + environment * _EnvironmentIntensity) * mainlight.color;
    return half4(color, 1);
}
#endif