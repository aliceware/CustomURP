#ifndef FXCOMMON_HLSL_INCLUDED
#define FXCOMMON_HLSL_INCLUDED

#include "./AtmosphereCommon.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/Particles/ParticlesUnlitInput.hlsl"

uniform sampler2D _MainTex;
uniform sampler2D _MaskTex;
uniform sampler2D _NoiseTex;
uniform sampler2D _DisTex;

CBUFFER_START(UnityPerMaterial)

uniform half _globalOpacity;

uniform half4 _MainTex_ST;
uniform half4 _MaskTex_ST;
uniform half4 _NoiseTex_ST;
uniform half4 _DisTex_ST;

uniform half _Tex01Type;
uniform half _Tex01RemapMin;
uniform half _Tex01RemapMax;
uniform half _Tex01ColorInten;
uniform half _Tex01PanU;
uniform half _Tex01PanV;
uniform half _Tex01AlphaInten;

uniform half _Tex02Type;
uniform half _Tex02Inten;
uniform half _Tex02PanU;
uniform half _Tex02PanV;

uniform half _Tex03Type;
uniform half _Tex03DissolveOffset;
uniform half _Tex03RemapMin;
uniform half _Tex03RemapMax;
uniform half _Tex03ColorInten;
uniform half _Tex03AlphaInten;
uniform half _Tex03SideWidth;

uniform half _Tex04Type;
uniform half _Tex04Inten;
uniform half _Tex04OffsetStep;
uniform half _Tex04TurbStrength;

uniform half _Fres;
uniform half _FresPow;
uniform half _FresAlphaInten;
uniform half _FresAlphaAdd;
uniform half _FresRemapMin;
uniform half _FresRemapMax;
uniform half _FresSideInten;

uniform half _Sin;
uniform half _SinRemapMin;
uniform half _SinRemapMax;
uniform half _SinRate;

uniform half4 _TintColor;
uniform half4 _MainTexColorR;
uniform half4 _MainTexColorG;
uniform half4 _MainTexColorB;
uniform half4 _DisCol;
uniform half4 _DisColB;
uniform half4 _FresCol;

uniform half _Mode;

uniform half _MainTexWrap;
uniform half _NoiseTexWrap;
uniform half _DisTexWrap;
uniform half _MaskTexWrap;

uniform float _SoftFadeNear;
uniform float _SoftFadeFar;
CB_ANIM_DECLARE
CBUFFER_END


struct appdata_effect
{
    VS_DECLARE
    half4 uv : TEXCOORD0;
    half4 uv1 : TEXCOORD1;
    half4 color : COLOR;
    float3 normal : NORMAL;
};

struct v2f
{
    float4 pos : SV_POSITION;
    half4 uv : TEXCOORD0;// texcoord: xy(uv);z(mask offset);w(dissolve)
    half4 uv1 : TEXCOORD1;// texcoord1: xy(uv);zw(main/dissolve uv)

    half4 color   : COLOR;
    float3 viewDirWS : TEXCOORD2;
    float4 normalWS : TEXCOORD3;
    float4 positionNDC : TEXCOORD4;
    half4  fogFactor  : TEXCOORD5;
};



v2f vert(appdata_effect v)
{
    VS_SKINNING_NORMAL(v)
    v2f o;
    VertexPositionInputs PositionInputs = GetVertexPositionInputs(v.vertex.xyz);
    float3 positionWS = PositionInputs.positionWS;
    o.pos = PositionInputs.positionCS;
    o.positionNDC = PositionInputs.positionNDC;
    float deltaTime = _Time.y % 100.0f;
    half2 custom1 = v.uv.zw;
    half2 custom2 = v.uv1.zw;

    half2 colPan = half2(_Tex01PanU, _Tex01PanV);
    half2 noisePan = half2(_Tex02PanU, _Tex02PanV);

    if (_Tex01Type > 0){
        o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
        o.uv.xy += deltaTime * colPan;
        o.uv.xy += custom2;
    }

    if (_Tex02Type > 0)
    {
        o.uv.zw = TRANSFORM_TEX(v.uv.xy, _NoiseTex);
        o.uv.zw += deltaTime * noisePan;
    }

    if (_Tex03Type > 0)
    {
        o.uv1.xy = TRANSFORM_TEX(v.uv.xy, _DisTex);
        o.uv1.xy += deltaTime * colPan;
        o.uv1.xy += custom2;
    }

    if (_Tex04Type > 0)
    {
        o.uv1.zw = TRANSFORM_TEX(v.uv.xy, _MaskTex);
        half offset = 0;
        if(_Tex04Type > 2.5){//step
            offset = round(custom1.x) * _Tex04OffsetStep;
            if(_Tex04Type < 3.5)//stepU
                o.uv1.z += offset;//3
            else//stepV
                o.uv1.w += offset;//4
        }
        else{//offset
            offset = custom1.x + _Tex04OffsetStep;
            if(_Tex04Type < 1.5)//offsetU
                o.uv1.z += offset;//1
            else//offsetV
                o.uv1.w += offset;//2
        }
    }



    o.color = v.color;
    o.color.rgb = o.color.rgb;

    float3 viewDirWS = SafeNormalize(GetCameraPositionWS() - positionWS.xyz);
    o.viewDirWS.xyz = viewDirWS;
    o.normalWS.xyz = normalize(mul((half3x3)UNITY_MATRIX_M, v.normal));

    o.normalWS.w = custom1.y;

    o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);
    return o;
}

half4 frag(v2f i) : COLOR
{
    float2 mainUV = i.uv.xy;
    float2 disUV = i.uv1.xy;
    float2 maskUV = i.uv1.zw;
    half noise = 1;
    half3 mainCol = 1;
    half alpha = 1;
    half3 finalCol = 1;

    float fresnel = 1-saturate(dot(i.normalWS.xyz, i.viewDirWS.xyz));
    fresnel = pow(fresnel,_FresPow);

    if (_Tex02Type > 0)
    {
        half2 noiseUV = i.uv.zw;
        if (_NoiseTexWrap > 0)
        {
            noiseUV = saturate(noiseUV);
        }
        noise = tex2D(_NoiseTex, noiseUV).r * _Tex02Inten;
        if(_Tex02Type < 1.5){
            //turbulence
            mainUV += noise;
            disUV += noise;
            maskUV += noise * _Tex04TurbStrength;
        }
    }

    if (_Tex01Type > 0){
        if (_MainTexWrap > 0)
        {
            mainUV = saturate(mainUV + half2(0, -1));
        }
        half4 mainMap = tex2D(_MainTex, mainUV);
        if(_Tex01Type > 1.5){
            mainMap.rgb = mainMap.r * _MainTexColorR + mainMap.g * _MainTexColorG + mainMap.b * _MainTexColorB;
        }
        mainCol *= mainMap.rgb;
        alpha *= saturate(mainMap.a * _Tex01AlphaInten);
    }

    if (_Tex02Type > 1.5)
    {
        if(_Tex02Type < 2.5){
            //multiply
            mainCol *= noise;
            alpha *= noise;
        }
        else{
            //add
            mainCol += noise;
            alpha += noise;
        }
        finalCol = mainCol;
    }


    if(_Tex04Type > 0)
    {
        if (_MaskTexWrap > 0)
        {
            maskUV = saturate(maskUV);
        }
        alpha *= tex2D(_MaskTex, maskUV).r * _Tex04Inten;
    }


    if (_Fres > 0)//fresAlpha
    {
        half fresAlpha = fresnel * _FresAlphaInten;
        fresAlpha += _FresAlphaAdd;
        alpha *= fresAlpha;
    }

    mainCol = Remap(mainCol.rgb,0,1,_Tex01RemapMin,_Tex01RemapMax);
    finalCol = max(mainCol,0) * _TintColor.rgb;
    mainCol = saturate(mainCol);

    if (_Tex03Type > 0)
    {
        float curve = 1-clamp(i.normalWS.w,-0.01,1) + _Tex03DissolveOffset; //custom1.y
        if (_DisTexWrap > 0)
        {
            disUV = saturate(disUV + half2(0, -1));
        }
        half dis = tex2D(_DisTex, disUV).r;
        half disAlpha;
        half dis0 = lerp(1, dis, curve * 2);
        dis0 = curve < 0.5 ? dis0 : dis;
        if(_Tex03Type > 1.5)
        {
            //hard dissolve
            disAlpha = step(curve, dis * alpha);

            half edge = step(curve + _Tex03SideWidth,dis * alpha);
            edge = saturate(disAlpha - edge);

            disAlpha = disAlpha * dis0;

            half side = saturate(Remap(dis * alpha,0,1,_Tex03RemapMin,_Tex03RemapMax));
            half3 sideCol = lerp(_DisColB.rgb,_DisCol.rgb,side) * _Tex03ColorInten;
            finalCol = lerp(finalCol,sideCol,edge);
        }
        else
        {
            //soft dissolve
            disAlpha = saturate(dis0 - curve);
        }
        disAlpha = saturate(disAlpha * _Tex03AlphaInten);
        alpha *= disAlpha;
    }

    if (_Fres > 0)
    {
        half3 fresCol = fresnel * mainCol;
        fresCol = saturate(Remap(fresCol,0,1,_FresRemapMin,_FresRemapMax));
        finalCol = lerp(finalCol,_FresCol.rgb * _FresSideInten,fresCol);
    }

    if (_Sin > 0)
    {
        float sinTime = sin(_Time.y % 100.0f * _SinRate);
        sinTime = Remap(sinTime,-1,1,_SinRemapMin,_SinRemapMax);
        alpha *= sinTime;
    }

    alpha *= _globalOpacity;

    half4 c = i.color;
    c.rgb *= finalCol * _Tex01ColorInten;
    c.a *= alpha;
    c.a = saturate(c.a);
    #if defined(_SOFTPARTICLES_ON)
        c = SOFT_PARTICLE_MUL_ALBEDO(c, half(SoftParticles(_SoftFadeNear, _SoftFadeFar, i.positionNDC)));
    #endif
    //clip(c.a - 0.001);

    c.rgb = MixFog(c.rgb, i.fogFactor);

    return c;
}
#endif
