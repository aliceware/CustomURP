#ifndef SCENEOBJECT_LIT_FORWARDBASE_PRAGMA
#define SCENEOBJECT_LIT_FORWARDBASE_PRAGMA

#pragma multi_compile __ BRG_WITHOUT_AO
#pragma multi_compile __ LIGHTMAP_ON_NOBRG LIGHTMAP_ON_INDIRECT
#pragma multi_compile __ LIGHTMAP_ON

#pragma multi_compile __ _ALPHATEST_ON
#pragma multi_compile __ FOG_LINEAR
#pragma multi_compile _ _SCREEN_DOOR_TRANSPARENCY

#pragma multi_compile __ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

#pragma multi_compile __ _ADDITIONAL_LIGHTS

#pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
#pragma multi_compile __ RO_TERRAIN_LOAD
#pragma multi_compile __ RO_MS_READ
#pragma multi_compile __ RO_FORCE_STORE_READ

#pragma shader_feature __ DEBUG_LIGHTMAP DEBUG_NOAOMAP DEBUG_MINIMAP

//CrossFade
#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE LOD_FADE_CROSSFADE_NOBRG

//BRG
#pragma multi_compile_instancing
#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

#endif
