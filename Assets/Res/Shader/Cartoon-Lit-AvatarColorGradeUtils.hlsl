#ifndef CARTOON_LIT_AVATAR_COLORGRADE_UTILS
#define CARTOON_LIT_AVATAR_COLORGRADE_UTILS

half4 CalColorGrade(half4 ColorGradeInfo, out half colorPart)
{
    half remap = ColorGradeInfo.r;
    half remap0 = Remap(remap, 0, _GradeColorHalfPos, 0, 0.5);
    if(remap > _GradeColorHalfPos)
        remap0 = Remap(remap, _GradeColorHalfPos, 1, 0.5, 1);
    half remap1 = Remap(remap, 0, _GradeColorHalfPos, 0, 0.5);
    if(remap > _GradeColorHalfPos)
        remap1 = Remap(remap, _GradeColorHalfPos, 1, 0.5, 1);
    half remap02 = remap0*remap0;
    half remap12 = remap1*remap1;

    half factor00 = saturate(_GradeFade*remap02 + (-0.5*_GradeFade-2)*remap0 + 1);
    half factor02 = saturate(_GradeFade*remap02 + (-1.5*_GradeFade+2)*remap0 + (0.5*_GradeFade-1));
    half factor01 = 1-factor00-factor02;

    half factor10 = saturate(_GradeFade*remap12 + (-0.5*_GradeFade-2)*remap1 + 1);
    half factor12 = saturate(_GradeFade*remap12 + (-1.5*_GradeFade+2)*remap1 + (0.5*_GradeFade-1));
    half factor11 = 1-factor10-factor12;

    half4 gradeColor = ColorGradeInfo;

    half3 gradeColor0 = _GradeColor0 * factor00 + _GradeColor1 * factor01 + _GradeColor2*factor02;
    half3 gradeColor1 = _GradeColor10 * factor10 + _GradeColor11 * factor11 + _GradeColor12*factor12;
    colorPart = _UseColorGrade > 0 ? ColorGradeInfo.b : 0;
    gradeColor.rgb = lerp(gradeColor0, gradeColor1, colorPart);

    half gradeShadow = ColorGradeInfo.g;
    // soft light from photoshop
    half3 gradeDark = (gradeColor.rgb * gradeShadow)/0.5 + gradeColor.rgb*gradeColor.rgb*(1 - gradeShadow*2);
    half3 gradeLight = (gradeColor.rgb * (1-gradeShadow))/0.5 + sqrt(gradeColor.rgb)*(gradeShadow*2 - 1);
    gradeColor.rgb = gradeShadow > 0.5 ? gradeLight : gradeDark;

    half gradeMask = ColorGradeInfo.a;
    half3 originColorGamma = pow(abs(ColorGradeInfo.rgb), 2.2);
    gradeColor.rgb = lerp(originColorGamma, gradeColor.rgb, gradeMask);

    return gradeColor;
}

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

#endif
