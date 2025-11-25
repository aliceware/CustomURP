#ifndef EDITOR_MINIMAP_HELPER
#define EDITOR_MINIMAP_HELPER

#include "./SceneCommon.hlsl" 
half3 MinimapColor(half3 baseColor, float3 positionWS)
{
    half3 c = baseColor.rgb;
    c.rgb = baseColor.rgb;
    c.rgb = frac((positionWS.y)/500);
    // c.rgb = frac((positionWS.y-152)/320);
    float starter = 150;
    float r = frac((positionWS.y-starter)/20);
    r = step(r, 0.95);
    float g = frac((positionWS.y-starter+5)/20);
    g = step(g, 0.95);
    float b = frac((positionWS.y-starter+10)/20);
    b = step(b, 0.95);
    float a = frac((positionWS.y-starter+15)/20);
    a = step(a, 0.95);
    // c.rgb = 0;
    c.rgb = half3(r,g,b)*0.75+0.25*a;
    c.rgb = baseColor.rgb;
    return c;
}

#endif
