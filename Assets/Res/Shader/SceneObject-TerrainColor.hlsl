#ifndef TERRAIN_COLOR_INCLUDED
#define TERRAIN_COLOR_INCLUDED
            
TEXTURE2D_ARRAY(_CtrBcTex);
SAMPLER(sampler_CtrBcTex);
int _CtrBcTexIndices[9];
float4 _CtrBcMinPosition;

float _EnableTerrainColor;

float3 HSV2RGB( float3 c ){
    float3 rgb = clamp( abs(fmod(c.x*6.0+float3(0.0,4.0,2.0),6)-3.0)-1.0, 0, 1);
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * lerp( float3(1,1,1), rgb, c.y);
}

float3 RGB2HSV(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

half3 SampleTerrainCtrBc(float3 positionWS, half grey)
{
    half3 ctrBc = SAMPLE_TEXTURE2D_ARRAY(_CtrBcTex, sampler_CtrBcTex, frac(positionWS.xz / 256), 0).rgb;
    // half3 ctrBc = tex2D(_CtrBcTex, uv).rgb;
    half3 gradeDark = (ctrBc.rgb * grey)/0.5 + ctrBc.rgb*ctrBc.rgb*(1 - grey*2);
    half3 gradeLight = (ctrBc.rgb * (1-grey))/0.5 + sqrt(ctrBc.rgb)*(grey*2 - 1);
    ctrBc.rgb = grey > 0.5 ? gradeLight : gradeDark;
    return ctrBc.rgb;
}

half3 SampleTerrainCtrBc(float3 positionWS, half3 rgbColor)
{
    if(_EnableTerrainColor > 0){
        half3 ctrBc = SAMPLE_TEXTURE2D_ARRAY(_CtrBcTex, sampler_CtrBcTex, frac(positionWS.xz / 256), 0).rgb;
        half3 ctrHsv = RGB2HSV(ctrBc);
        ctrHsv += (rgbColor - 0.5)*0.2;
        // ctrHsv.yz = saturate(ctrHsv);
        // ctrHsv.x = frac(ctrHsv);
        rgbColor = HSV2RGB(ctrHsv);
        // rgbColor = ctrBc;
    }
    return rgbColor;
}

#endif // TERRAIN_COLOR_INCLUDED