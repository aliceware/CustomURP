#ifndef CARTOON_LIT_AVATAR_FORWARDBASE_PASS
#define CARTOON_LIT_AVATAR_FORWARDBASE_PASS

#include "./SceneObject-LitCloud.hlsl"
#include "./ScreenDoorTransparencyHLSL.hlsl"
#include "./AtmosphereCommon.hlsl"

struct AvatarLightInfo
{
    float3 lightDir;
    half3 lightCol;
    half3 darkCol;
    half shadowAttenuation;
};

AvatarLightInfo InitLightInfo(float3 positionWS)
{
    AvatarLightInfo info;
    half3 lightOutShadow = _LightOutShadow.a == 0 ? 1 : _LightOutShadow.rgb;
    half3 darkOutShadow = _DarkOutShadow.a == 0 ? 1 : _DarkOutShadow.rgb;
    if(_AvatarLightDir.w == 0){
        //no avatar light controller
        Light mainLight = GetMainLight();
        info.lightDir = mainLight.direction;
        info.shadowAttenuation = 1;
    }
    else if(_AvatarLightDir.w == 1){
        //default avatar light controller
        info.lightDir = _AvatarLightDir.xyz;
        info.shadowAttenuation = _AvatarLightColor.a;
    }
    
    info.shadowAttenuation = GetCloudShadow(positionWS, info.shadowAttenuation, 1);
    info.shadowAttenuation = saturate(info.shadowAttenuation);
    info.lightCol = lerp(_LightInShadow.xyz, lightOutShadow.xyz, info.shadowAttenuation);
    info.darkCol = lerp(_DarkInShadow.xyz, darkOutShadow.xyz, info.shadowAttenuation);
    return info;
}

struct Attributes
{
    float4 positionOS   : POSITION;
    half2  uv           : TEXCOORD0;
    float3 normalOS     : NORMAL;
    float4 tangentOS   : TANGENT;
    float4 vertexColor  : COLOR0;
};

struct Varings {
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    float3 normalWS      : TEXCOORD1;
    float3 viewDir       : TEXCOORD2;
    float3 positionWS   : TEXCOORD3;
    float4 tangentWS : TEXCOORD4;
    float4 positionNDC  : TEXCOORD5;
    float3 positionVS   : TEXCOORD6;
    float4 vertexColor  : COLOR0;
    half  screendepth               : TEXCOORD7;
#ifdef _FOG_ON
    half4 fogFactor : TEXCOORD8;
#endif
};

Varings vert(Attributes IN)
{
    Varings o;
    VertexPositionInputs PositionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
    float3 positionWS = PositionInputs.positionWS;
    o.positionCS = PositionInputs.positionCS;
    o.positionVS = PositionInputs.positionVS;
    o.positionNDC = PositionInputs.positionNDC;
    o.uv.xy = TRANSFORM_TEX(IN.uv,_BaseMap);

    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
    o.normalWS = vertexNormalInput.normalWS;
    real sign = real(IN.tangentOS.w) * GetOddNegativeScale();
    o.tangentWS = half4(vertexNormalInput.tangentWS, sign);

    o.viewDir = normalize(_WorldSpaceCameraPos - positionWS);
    o.positionWS = positionWS;
    o.vertexColor = IN.vertexColor;

    o.screendepth = o.positionCS.z/o.positionCS.w;
#ifdef _FOG_ON
    o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.positionCS.z);
#endif
    return o;
}

float3 NPR_Base_Ramp(float lambertRampAO, float rampID)
{
    float rampSampler = 1-rampID - 0.5/_RampCount;
    return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(lambertRampAO, rampSampler)).rgb;
}

half2 AdjustMatcapUV(half3 viewDir, half3 normalWS)
{
    //补偿 world To view 校正
    half3 viewAmendment = mul(UNITY_MATRIX_V, half4(viewDir, 0)).xyz+ half3(0,0,1) ;
    half3 viewNm = mul(UNITY_MATRIX_V, half4(normalWS, 0)).xyz ;
    //向量混合
    half3 viewblend = viewAmendment* dot(viewAmendment, viewNm)/viewAmendment.z - viewNm ;
    // float2 MetalDir = normalize(mul(UNITY_MATRIX_V,normalWS)) * 0.5 + 0.5;
    half2 MetalDir = viewblend.xy*-0.5+0.5;
    return MetalDir;
}

half3 VFXSatAdjust(half3 color, half satValue)
{
	half3 lum = dot(color, half3(0.22, 0.707, 0.071));
	lum = lerp(lum, color.rgb, satValue);
	return lum;
}

#ifdef _FACE
    float GetNPRFaceBias(float2 shadowMap, float3 LightDir)
    {

        float3 Right = normalize(TransformObjectToWorldDir(float3(-1,0,0)));
        float3 Front = normalize(TransformObjectToWorldDir(float3(0,0,1)));

        float ctrl = dot(normalize(Front), normalize(LightDir));
        float ilm = dot(LightDir.xz, Right.xz) > 0 ? shadowMap.r : shadowMap.g;
        return saturate(ctrl+ilm);
    }
#else
    half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = half(1.0))
    {
        half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
        return UnpackNormalScale(n, scale);
    }

    half3 NPR_Base_Specular(half NdotL,half NdotH, half3 normalWS,half3 baseColor,half4 parameter)
    {
        half  SpecularPow = max(parameter.r, 0.01) * _SpecularPow;
        half3 SpecularColor = _SpecularColor.rgb * parameter.b;
        half SpecularContrib = saturate(pow(NdotH, SpecularPow));
        half SpecularAO = saturate(parameter.g - 0.5);

        return SpecularColor * ((SpecularContrib * saturate(NdotL) * SpecularAO));
    }

    half3 NPR_Base_Matcap(half3 MetalTex, half3 Diffuse, half3 lightCol, half4 parameter)
    {
        half3 MetalLight = lerp(Diffuse, lightCol, saturate(MetalTex * 2 - 1));
        half3 MetalDark = lerp(0, Diffuse, saturate(MetalTex * 2));
        half3 MetalFinal = lerp(MetalDark, MetalLight, step(0.5,MetalTex));
        half MatcapAO = saturate(parameter.g - 0.5);
        half MetalStrength = step(0.95, parameter.r) * _MetalIntensity * MatcapAO;
        return lerp( Diffuse, MetalFinal, MetalStrength);
    }
#endif



RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, Varings input)
{
    AvatarLightInfo lightInfo = InitLightInfo(input.positionWS);
    float rampStrength = lerp(_RampStrengthInShadow, 1, lightInfo.shadowAttenuation);

    float3 normalWS = input.normalWS;
#ifndef _FACE
    half3 normalTS = SampleNormal(input.uv.xy, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), 1);
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(normalWS, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, normalWS);
    half3 detailNormalWS = TransformTangentToWorld(normalTS, tangentToWorld);
    normalWS = _EnableNormalMap > 0 ? detailNormalWS : normalWS;
#endif

    float3 lightDir = normalize(lightInfo.lightDir); //主光源方向
    float3 viewDir = input.viewDir;
    float3 halfDir = normalize(lightDir + viewDir);

    half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
#ifdef _COLORGRADE
    half colorPart = 0;
    baseColor = CalColorGrade(baseColor, colorPart);
#else
    baseColor.rgb *= _BaseColorTint.rgb;
#endif
    
    half4 LightMap = half4(0,1,0,1);
    if(_UseLightMap == 1)
    {
        LightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv.xy);
    }

    float NdotV = max(0, dot(normalWS, viewDir));

    float4 scrPos = input.positionNDC;
    float2 screenPos = scrPos.xy / scrPos.w;
    screenPos.xy *= _ScaledScreenParams.xy;

#ifdef _FACE
    half4 ShadowMap = SAMPLE_TEXTURE2D(_FaceShadow, sampler_FaceShadow, input.uv.xy);
    half4 InverseShadowMap = SAMPLE_TEXTURE2D(_FaceShadow, sampler_FaceShadow, float2(1-input.uv.x,input.uv.y));
    half2 shadow = half2(ShadowMap.r, InverseShadowMap.r);
    half bias = GetNPRFaceBias(shadow, lightDir);
    #if _DEPTHSHADOW && RO_OPT_SUBPASS_LOAD
        // hair shadow
        float shadowOffset = _DShadowOffset;
        float shadowStep = _DShadowStep;
        bool isOrtho = (UNITY_MATRIX_P[3][3] == 1.0);
        if(isOrtho){
            shadowOffset *= 5;
            shadowStep = 0;
        }

        float rawD = input.positionNDC.z/input.positionNDC.w;
        float linearEyeTrueDepth = LinearEyeDepth(rawD,_ZBufferParams);
        float3 lightDirVS = lightDir;
        lightDirVS.xz += normalWS.xz*_DShadowNormalOffset;
        lightDirVS = normalize(lightDirVS);
        lightDirVS = normalize(TransformWorldToViewDir(lightDirVS,true));
        lightDirVS *= saturate(linearEyeTrueDepth)*shadowOffset;
        half2 offsetLength = length(lightDirVS.xy);
        lightDirVS.xy = lightDirVS.xy / offsetLength * min(offsetLength, 0.01);

        float3 offsetPosVS = float3(input.positionVS.xy + lightDirVS.xy, input.positionVS.z);
        float4 offsetPosCS = TransformWViewToHClip(offsetPosVS);
        float4 offsetPosVP = ComputeScreenPos(offsetPosCS) / scrPos.w;
        float offsetDepth = SAMPLE_TEXTURE2D(_CameraCharDepthTexture, sampler_CameraCharDepthTexture, offsetPosVP.xy).r;

        float linearEyeOffectDepth = LinearEyeDepth(offsetDepth,_ZBufferParams);
        float depthDiffer = linearEyeOffectDepth - linearEyeTrueDepth;
        depthDiffer = step(shadowStep, depthDiffer);
        bias *= depthDiffer;
    #endif

    half halfLambert = bias;
#else
    float NdotL = dot(normalWS, lightDir);
    float NdotH = max(0, dot(normalWS, halfDir));

    float lambert = NdotL;
    half halfLambert = lambert * 0.5 + 0.5;
#endif

    half AO = saturate(LightMap.g * 2);
    half rampMax = _RampRangeMax + (1.2-_RampRangeMax)*(1 - AO);
    float shadowMinMax = 1.0 / (rampMax - _RampRangeMin);
    float rampArea = (halfLambert * shadowMinMax - _RampRangeMin * shadowMinMax);

    half lambertRampAO = saturate(rampArea);

#ifdef _FACE
    float3 RampColor = NPR_Base_Ramp(lambertRampAO, LightMap.a);
#else
    half lambertRampAOStepRef = lerp(lambertRampAO * (1 - _RampReflectionRange) + _RampReflectionRange, lambertRampAO, saturate(AO*2));
    float3 RampColor = NPR_Base_Ramp(lambertRampAOStepRef, LightMap.a);
#endif

#ifdef _COLORGRADE
    half rampSampler0 = 1-(_GradeRampID+0.5)/_GradeRampCount;
    half rampSampler1 = 1-(_GradeRampID1+0.5)/_GradeRampCount;
    half3 rampColorGrade0 = SAMPLE_TEXTURE2D(_GradeRampMap, sampler_GradeRampMap, float2(lambertRampAO, rampSampler0)).rgb;
    half3 rampColorGrade1 = SAMPLE_TEXTURE2D(_GradeRampMap, sampler_GradeRampMap, float2(lambertRampAO, rampSampler1)).rgb;
    half3 rampColorGrade = lerp(rampColorGrade0, rampColorGrade1, colorPart);
    RampColor = lerp(RampColor, rampColorGrade, baseColor.a);
#endif

    half ambientStr = lerp(_AmbientStrengthInShadow, _AmbientStrength, lightInfo.shadowAttenuation);
    half ambient = smoothstep(_AmbientRange + _AmbientSmooth + 0.001, _AmbientRange, lambertRampAO) * ambientStr;

    half3 lightCol = lerp(lightInfo.lightCol, lightInfo.darkCol, ambient);
    RampColor = lerp(1, RampColor, rampStrength);

    half3 Diffuse;

    float4 FinalColor = 1;

    Diffuse = RampColor * baseColor.rgb * lightCol;

#ifdef _FACE
    FinalColor.rgb = Diffuse;
#else
    float3 Specular = 0;
    half3 MetalTex = 0;
    Specular = NPR_Base_Specular(NdotL,NdotH,normalWS,baseColor.rgb,LightMap) * lightCol;
        
    half2 MetalDir = AdjustMatcapUV(viewDir, normalWS);
    MetalTex = SAMPLE_TEXTURE2D(_MetalTex, sampler_MetalTex, MetalDir.xy).rgb;
    Diffuse = NPR_Base_Matcap(MetalTex, Diffuse, lightCol, LightMap);

    FinalColor.rgb = Diffuse + Specular;
#endif

#ifdef _RIMLIGHT
    //RimLightStart
    float rimOffset = _RimOffset * 0.06;
    float VdotL = max(0, dot(float3(lightDir.x, 0, lightDir.z), viewDir));
    float3 nDirVS = normalize(TransformWorldToViewDir(normalWS,true)) * (1-VdotL);
    nDirVS.y = 0;

    // Cannot preview _CameraDepthTexture in edit mode, sample texture instead of posNDC.z/posNDS.w
    
    // float trueDepth = SAMPLE_TEXTURE2D(_CameraCharDepthTexture, sampler_CameraCharDepthTexture, screenPos).r;
    // float rawD = GET_SUBPASS_LOAD_DEPTH(screenPos);
    float rawD = input.positionNDC.z/input.positionNDC.w;
    float linearEyeTrueDepth = LinearEyeDepth(rawD,_ZBufferParams);

    float3 offsetPosVS = float3(input.positionVS.xy + nDirVS.xy * saturate(linearEyeTrueDepth) * rimOffset, input.positionVS.z);
    float4 offsetPosCS = TransformWViewToHClip(offsetPosVS);
    float4 offsetPosVP = ComputeScreenPos(offsetPosCS) / scrPos.w;
    float offsetDepth = SAMPLE_TEXTURE2D(_CameraCharDepthTexture, sampler_CameraCharDepthTexture, offsetPosVP.xy).r;

    float linearEyeOffectDepth = LinearEyeDepth(offsetDepth,_ZBufferParams);
    float depthDiffer = linearEyeOffectDepth - linearEyeTrueDepth;
    float rimIntensity = smoothstep(0.0,_RimStep,saturate(depthDiffer)) * _RimIntensity * (lambertRampAO > 0.9 ? 1 : 0.5);
    //RimLightEnd
    half3 Rim = lightCol * _RimColor.rgb * rimIntensity;

    FinalColor.rgb += Rim;
#endif

    FinalColor.rgb = VFXSatAdjust(FinalColor.rgb, _SatValue);


#ifdef _VFX_FRES
    half3 vfxFresnel = saturate(pow(1-NdotV, _VFXFresnelPow)) * _VFXFresnelColor * _VFXFresnelIntensity;
    float VFXFrenelFactor = (_VFXFresnel > 0.01) ? _VFXFresnel : saturate((_Time.y - _VFXFrenelStartTime)/(_VFXFrenelDuration));
    if(_VFXFrenelInOut > 0.5)
    {
        VFXFrenelFactor = 1 - VFXFrenelFactor;
    }

    FinalColor.rgb += vfxFresnel * VFXFrenelFactor;
    
    // return SubPassOutputColor(float4(VFXFrenelFactor.xxx, 1), input.positionCS.z);

#endif


    float _HitFactor = (_HitFxIntensity > 0.01) ? _HitFxIntensity : saturate((_Time.y - _HitStartTime)/(0.2));
    float fresnel = 1-saturate(dot(normalWS, viewDir));
    fresnel = pow(fresnel,_HitFXRimPow);
    float hitStrength = saturate(fresnel * _HitFXRimStrength + _HitFXColor.a);
    FinalColor.rgb = lerp(FinalColor.rgb, _HitFXColor.rgb, hitStrength * (1-_HitFactor));

#if !defined(_FACE) && !defined(_COLORGRADE)
    if(_BaseAlphaType == 0)
        FinalColor.a = baseColor.a * _BaseColorTint.a;
    else if(_BaseAlphaType == 1){
        FinalColor.rgb = lerp(FinalColor.rgb, baseColor.rgb * _EmissionIntensity, baseColor.a);
    }
#endif

    #if defined(_DEBUG_BASE)
        FinalColor.rgb = baseColor.rgb;
    #elif defined(_DEBUG_RAMP)
        FinalColor.rgb = RampColor;
    #elif defined(_DEBUG_SCENEGI)
        FinalColor.rgb = lightCol;
    #elif defined(_DEBUG_SPECULAR)
        FinalColor.rgb = Specular;
    #elif defined(_DEBUG_MATCAP)
        FinalColor.rgb = MetalTex;
    #elif defined(_DEBUG_NORMAL)
        FinalColor.rgb = normalWS * 0.5 + 0.5;
    #elif defined(_DEBUG_AO)
        FinalColor.rgb = LightMap.g;
    #elif defined(_DEBUG_ID)
        half debugStep = 0.1 / _RampCount;
        half debugId = saturate(1 - abs(_DebugIDNum / _RampCount - LightMap.a));
        debugId = pow(debugId, 30);
        // debugId = step(0.9, debugId);
        FinalColor.rgb = debugId;
    #elif defined(_DEBUG_RIM)
        // FinalColor.rgb = Rim;
    #endif

    FinalColor.rgb *= _UIColorMask;
    
#ifdef _VFX_DISSOLVE
    half2 dissolveUV = TRANSFORM_TEX(input.uv.xy, _DissolveMap);
    half dissolveVal = tex2D(_DissolveMap, dissolveUV).r;

    float DissolveFactor = (_DissolveFactorTest > 0.01) ? _DissolveFactorTest : saturate((_Time.y - _DissolveStartTime)/(_DissolveDuration));

    if(_DissolveInOut > 0.5)
    {
        DissolveFactor = 1 - DissolveFactor;
    }
    
    if(dissolveVal < DissolveFactor)
    {
        discard;
    }
    
    float EdgeFactor = saturate((dissolveVal - DissolveFactor)/(_DissolveEdgeWidth * DissolveFactor));

    // FinalColor.rgb = DissolveFactor;


    FinalColor.rgb = lerp(FinalColor  * (1 - 5*DissolveFactor), _DissolveEdgeColor * FinalColor, 1 - EdgeFactor);
#endif

#ifdef _VFX_FROZEN
    float2 FrozenDir = AdjustMatcapUV(viewDir, normalWS);
    half4 FrozenMap = tex2D(_FrozenMap, FrozenDir.xy);

    float FrozenFactor = (_FrozenFactorTest > 0.01) ? _FrozenFactorTest : saturate((_Time.y - _FrozenStartTime)/(_FrozenDuration));
    if(_FrozenInOut > 0.5)
    {
        FrozenFactor = 1 - FrozenFactor;
    }

    FinalColor.rgb = lerp(FinalColor.rgb, FrozenMap.rgb, FrozenFactor);

#endif

#ifdef _FOG_ON
    FinalColor.rgb = MixFog(FinalColor.rgb, input.fogFactor);
    // FinalColor.rgb = input.fogFactor;
#endif

#ifdef _SCREEN_DOOR_TRANSPARENCY
    ClipScreenDoorTransparency(_SDAlphaTest, _DisplayStartTime, _DisplayInOut, input.positionWS, screenPos);
#endif

    return SubPassOutputColor(FinalColor, input.positionCS.z);
}

#endif
