#ifndef ScreenDoorTransparency
#define ScreenDoorTransparency

#include "./CommonHLSL.hlsl"

void LODCrossFade(float4 positionCS, float brgFadeStart, float brgFadeSpeed, float crossFadeStart, float crossFadeSpeed, float crossFadeSign)
{
    #ifdef LOD_FADE_CROSSFADE
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
            LODCrossFadeDitheringTransition(positionCS, brgFadeStart, brgFadeSpeed, crossFadeSign);
        #else
            LODCrossFadeDitheringTransition(positionCS, crossFadeStart, crossFadeSpeed, crossFadeSign);
        #endif
    #elif LOD_FADE_CROSSFADE_NOBRG
        LODCrossFadeDitheringTransition(positionCS.xyz, crossFadeStart, crossFadeSpeed, crossFadeSign);
    #endif
}

void ClipScreenDoorTransparency(half SDAlphaTest, half displayStartTime, half displayInOut, float3 positionWS, float2 screenPos)
{
#ifdef _SCREEN_DOOR_TRANSPARENCY
float4x4 thresholdMatrix =
            {
            1.0,  9.0,  3.0,  11.0,
            13.0, 5.0,  15.0, 7.0,
            4.0,  12.0, 2.0,  10.0,
            16.0, 8.0,  14.0, 6.0
            };
            float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };

            float DisplayFactor = (SDAlphaTest > 0 && SDAlphaTest < 1) ? SDAlphaTest : saturate((_Time.y - displayStartTime)/(1));
            if(displayInOut > 0.5)
            {
                DisplayFactor = 1 - DisplayFactor;
            }
            

            half3 playerLocation = _PlayerLocation + half3(0,1.5,0);
            half3 Cam2PlayerDir = normalize(_WorldSpaceCameraPos - playerLocation);
            half3 Cam2SelfrDir = normalize(_WorldSpaceCameraPos - positionWS);
            half3 Self2Player = normalize(positionWS - playerLocation);

            half OcclusionTest = smoothstep(0.6, 1, saturate(dot(Self2Player,Cam2PlayerDir)));

            
            half OcclusionClip = lerp(1, 0.5, OcclusionTest * smoothstep(0.5, 1, saturate(dot(Cam2PlayerDir, Cam2SelfrDir))));


            clip(min(DisplayFactor,OcclusionClip) - thresholdMatrix[fmod(screenPos.x, 4)] / 17.0 * _RowAccess[fmod(screenPos.y, 4)]);

#endif
}

#endif
