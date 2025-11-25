#ifndef SCENEOBJECT_LIT_FORWARDBASE
#define SCENEOBJECT_LIT_FORWARDBASE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "./SceneCommon.hlsl"
#include "./ROOPTSubPassLoadTerrain.hlsl"
#include "./SceneObject-Lighting.hlsl"
#include "./SceneObject-LitCloud.hlsl"
#include "./ScreenDoorTransparencyHLSL.hlsl"
#include "./Editor-MinimapHelper.hlsl"

struct a2v
{
    float4 vertex    : POSITION; 
    float3 normalOS  : NORMAL;
    float4 tangentOS : TANGENT;
    half4  texcoord  : TEXCOORD0;
#ifndef LIT_PROBE
    half4  texcoord1 : TEXCOORD1;
#endif
#ifdef BAKE_SKIN_ANIM
    float2 boneInfluences : TEXCOORD2; 
    float2 boneIds  : TEXCOORD3; 
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos						: SV_POSITION;
    half2 uv						: TEXCOORD1;
    half4 fogFactor					: TEXCOORD2;

    half3 normalWS					: TEXCOORD3;
    float3 positionWS				: TEXCOORD4;
    float3 viewDirWS				: TEXCOORD5;

    half2  lmap	    				: TEXCOORD6;

    half4 tangentWS					: TEXCOORD8;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

v2f vert(a2v v)
{
    v2f o = (v2f)0;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    
#ifdef BAKE_SKIN_ANIM
    float3 originWS = mul(UNITY_MATRIX_M, float4(0,0,0,1)).xyz;
    float timeOffset = RandomSeed(originWS) * _RandomOffset;
    float4x4 skinMatrix = CalculateSkinMatrix(v.boneIds, v.boneInfluences, timeOffset, _Frame);
    float4 skinVertex = mul(skinMatrix, v.vertex);
    v.vertex = lerp(v.vertex, skinVertex, _AnimScale);

    float3 skinNormal = mul((float3x3) skinMatrix, v.normalOS.xyz);
    v.normalOS.xyz = lerp(v.normalOS.xyz, skinNormal, _AnimScale);
#endif

    float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
    
    o.pos = mul(UNITY_MATRIX_VP, positionWS);
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

    o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);

    //#ifdef _ADDITIONAL_LIGHTS
    o.positionWS	= positionWS.xyz;
    //#endif
    o.viewDirWS = GetCameraPositionWS() - positionWS.xyz;

#if defined(UNITY_DOTS_INSTANCING_ENABLED)
    #ifndef LIT_PROBE
        o.normalWS = TransformObjectToWorldNormalForBRG(v.normalOS.xyz, (float3x3) UNITY_MATRIX_M, _ObjectScale.xyz);
    #else
        o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
    #endif
#else
    o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
#endif

    real sign = real(v.tangentOS.w) * GetOddNegativeScale();
    half3 tangentWS = real3(TransformObjectToWorldDir(v.tangentOS.xyz));
    o.tangentWS = half4(tangentWS, sign);

#ifndef LIT_PROBE
#if defined(UNITY_DOTS_INSTANCING_ENABLED)
    o.lmap = v.texcoord1.xy * _LightmapST.xy + _LightmapST.zw;
#elif LIGHTMAP_ON_NOBRG || LIGHTMAP_ON_INDIRECT || LIGHTMAP_ON
    o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
#endif
    
    return o;
}

//half4 frag(v2f i) : SV_Target
RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
{
    UNITY_SETUP_INSTANCE_ID(i);

    LODCrossFade(i.pos, _BrgCrossFadeStart, _BrgCrossFadeSpeed, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
    ClipScreenDoorTransparency(_SDAlphaTest, _DisplayStartTime, _DisplayInOut, i.positionWS.xyz, i.pos.xy);

    half4 baseColor = tex2D(_MainTex, i.uv);
    baseColor.rgb *= _Color.rgb;
    half4 hlodc = baseColor;
    #if _ALPHATEST_ON
        clip(baseColor.a - _Cutoff);
    #endif

    half3 normalTS;
    half smoothness = 0;
    half specular = 0;
    half3 normalWS = NormalizeNormalPerPixel(i.normalWS);
    if(_EnableNormalMap){
        UnpackNormalData(i.uv, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), normalTS, smoothness, specular, _NormalScale);
        half3 unpackedNormalWS = UnpackTangentNormal(normalWS, normalTS, i.tangentWS);
        normalWS = unpackedNormalWS;
    }

    float3 viewDirWS = i.viewDirWS;
    float3 viewDirectionWS = SafeNormalize(viewDirWS);
   
#ifdef LIT_PROBE
    LightInfo info = InitLightInfoProbe(i.positionWS, normalWS);
#else
    LightInfo info = InitLightInfo(i.lmap, normalWS, length(viewDirWS));
#endif
    half3 lm = info.lm;
    half ambientAO = info.ambientAO;

float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
Light mainLight = GetMainLight(shadowCoord);
#if defined(UNITY_DOTS_INSTANCING_ENABLED) || (LIGHTMAP_ON_NOBRG && LIGHTMAP_ON)
    mainLight.shadowAttenuation *= info.shadow;
#endif

#if DEBUG_NOAOMAP
    ambientAO = CalAmbientAO(normalWS);
#endif
    
#ifndef LIGHTMAP_ON
    #ifdef _ADDITIONAL_LIGHTS
        lm.rgb = GetAddLightResult(lm.rgb, i.positionWS, normalWS);
    #endif
#endif
    
    half3 lightColor = lerp(ro_ShadowEdgeColor.rgb * mainLight.color.rgb, mainLight.color.rgb, mainLight.shadowAttenuation);

    //cloudShadow
    half cloudShadow = GetCloudShadow(i.positionWS.xyz, mainLight.shadowAttenuation, ambientAO);
    mainLight.shadowAttenuation = cloudShadow;
    lightColor *= mainLight.shadowAttenuation;


    half NdotL = saturate(dot(normalWS, mainLight.direction));
    BRDFData brdfData;
    InitBRDFData(baseColor.rgb, smoothness, specular, brdfData);
#if LOD_HIGH_SHADER
    half3 directColor = LightingDirect(brdfData, normalWS, viewDirectionWS, mainLight);
    half3 indirectColor = LightingIndirect(brdfData, normalWS, viewDirectionWS, lm.rgb, ambientAO);
#else
    half3 directColor = LightingDirectLOD(brdfData, normalWS, viewDirectionWS, mainLight);
    half3 indirectColor = LightingIndirectLOD(brdfData, normalWS, viewDirectionWS, lm.rgb, ambientAO);
#endif

    half4 c = 1;
    c.rgb = BlendTerrainColor(i.pos, _TerrainBlendRange, directColor, indirectColor, lightColor);
    if(_BaseAlphaType == 1)
        c.rgb = lerp(c.rgb, baseColor.rgb * _EmissionIntensity, baseColor.a);
    else
        c.a = baseColor.a;


    c.rgb = MixFog(c.rgb, i.fogFactor);

#if DEBUG_LIGHTMAP
    c.rgb = lm.rgb + ambient;
#endif
#if DEBUG_MINIMAP
c.rgb = MinimapColor(baseColor.rgb, i.positionWS);
c.a = 1;
#endif
    // c.rgb = mainLight.shadowAttenuation;

    return SubPassOutputColor(c, i.pos.z);
}

#endif
