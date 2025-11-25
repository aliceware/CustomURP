Shader "Custom/Cartoon-Lit-Avatar-ColorGrade"
{
    Properties
    {
        [CustomHeader(ColorGrade)]
        _BaseMap("Color Grade Map R:渐变映射|G:柔光图层|B:挑染分区|A:染色Mask", 2D) = "white" {}
        [Enum(Single, 0, Double, 1)] _UseColorGrade ("Use ColorGrade", Float) = 0
        _GradeFade("Color Grade Fade", Range(-4, 2)) = 0

        _GradeColor0 ("Part1 Color 0", Color) = (1,1,1,1)
        _GradeColor1 ("Part1 Color 0.5", Color) = (1,1,1,1)
        _GradeColor2 ("Part1 Color 1", Color) = (1,1,1,1)
        _GradeColorHalfPos("Part1 Color 0.5 Remap Position", Range(0, 1)) = 0.5
        _GradeRampID("Part1 Ramp ID", Integer) = 0

        _GradeColor10 ("Part2 Color 0", Color) = (1,1,1,1)
        _GradeColor11 ("Part2 Color 0.5", Color) = (1,1,1,1)
        _GradeColor12 ("Part2 Color 1", Color) = (1,1,1,1)
        _GradeColor1HalfPos("Part2 Color 0.5 Remap Position", Range(0, 1)) = 0.5
        _GradeRampID1("Part2 Ramp ID", Integer) = 0

        _GradeRampMap("Color Grade Ramp Map", 2D) = "white" {}
        _GradeRampCount("Ramp Count", Integer) = 32

        [CustomHeader(Shadow)]
        [Toggle(SHADOW_RAMP_ON)] _UseShadowRamp ("Use Shadow Ramp", Float) = 1
        _RampTex("RampMap 建议明暗交接线从0.9开始，RampRangeMax为0.55", 2D) = "white" {}
        _RampCount("Ramp Count", Range(1, 16)) = 8
        [MinMaxSlider(_RampRangeMin, _RampRangeMax)] _RampRange("Ramp Range", Range(0, 1)) = 0
        [HideInInspector] _RampRangeMin("Ramp Range Min", Range(0, 1)) = 0
        [HideInInspector] _RampRangeMax("Ramp Range Max", Range(0, 1)) = 0.55
        _RampReflectionRange("RefRange反弹光范围，控制AO处无反弹", Range(0, 1)) = 0.3

        [CustomHeader(LightMap)]
        [Toggle(_UseLightMap)] _UseLightMap ("Use Light Map", Float) = 1
        _LightMap("LightMap R:光滑度(0.95有Matcap)|G:AO(0.5以上不影响ramp)|B:Spec强度|A:RampID", 2D) = "black" {}

        [CustomHeader(NormalMap)]
        [Toggle]_EnableNormalMap("Enable Normal Map", Float) = 0
        _NormalMap("NormalMap", 2D) = "normal" {}

        [CustomHeader(Specular)]
        _SpecularPow ("Specular Power ", Range(1,20)) = 4
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)

        [CustomHeader(Metal)]
        _MetalTex("MetalTex", 2D) = "grey" {}
        _MetalIntensity("MetalIntensity", Range(0,1)) = 1

        [CustomHeader(RimLight)]
        [Toggle(_RIMLIGHT)] _EnableRimLight ("Enable Rim Light", Float) = 1
        _RimOffset("边缘光检测偏移量", Range(0,1)) = 0.1
        _RimStep("边缘光阈值", Range(0,1)) = 0.5
        _RimColor("边缘光颜色", Color) = (1,1,1,1)
        _RimIntensity("边缘光强度", Range(0,1)) = 0.15

        [CustomHeader(Outline)]
        [Enum(None, 0, Normal, 1, Tangent, 2)] _OutlineType ("Outline Type", Float) = 2
        _OutlineMap("Outline Map", 2D) = "white" {}
        _OutlineThickness("Outline Thickness", Range(0, 0.15)) = 0.014
        _OutlineColor("Outline Color", Color) = (1, 1, 1, 1)

        [CustomHeader(HitFX)]
        _HitStartTime("hitStartTime", Float) = 0
        _HitFxIntensity("HitFx Intensity", Range(0,1)) = 0
        [HDR]_HitFXColor ("HitFX Color", Color) = (1,1,1,0.2)
        _HitFXRimPow ("HitFX Rim Power ", Range(1,20)) = 4
        _HitFXRimStrength ("HitFX Rim Strength", Range(0, 3)) = 0.5

        [CustomHeader(Debug)]
        [KeywordEnum(Off, Base, Ramp, SceneGI, Specular, Matcap, Normal, AO, ID, Rim)] _Debug ("Debug mode", Float) = 0
        _DebugIDNum("Debug ID Number", Range(0, 15)) = 0

        [CustomHeader(Blend)]
        [Toggle]_ZWrite("ZWrite", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("_Cull", Float) = 2.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("_SrcBlend", Float) = 1.0
        [HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("_DstBlend", Float) = 0.0

        [CustomHeader(VFX)]
        [Toggle(_VFX_DISSOLVE)]_dissolveToggle("溶解特效", float) = 0
        _DissolveDuration("溶解时长", Float) = 1
        _DissolveStartTime("溶解开始时间", Float) = 0
        _DissolveFactorTest("Dissolve Factor Test", Range(0,1)) = 0
        _DissolveColor("Dissolve Color", Color) = (0,0,0,0)
        [HDR]_DissolveEdgeColor("Dissolve Edge Color", Color) = (1,1,1,1)
        _DissolveMap("DissolveMap", 2D) = "white"{}
        _DissolveEdgeWidth("DissolveEdgeWidth", Range(0,1)) = 0.3

        [Space(5)]

        [Toggle(_VFX_FROZEN)]_FrozenToggle("冰冻特效", float) = 0
        _FrozenStartTime("冰冻开始时间", Float) = 0
        _FrozenDuration("冰冻持续时间", Float) = 1
        _FrozenFactorTest("冰冻测试", Range(0,1)) = 0
        _FrozenInOut("冰冻进出标记", Float) = 0
        _FrozenMap("_FrozenMap", 2D) = "white"{}
        
        [Space(5)]

        [Toggle(_SCREEN_DOOR_TRANSPARENCY)]_ScreenDoorToggle("纱窗测试", float) = 0
        _SDAlphaTest("纱窗Alpha测试", Range(0,1)) = 1
        _DisplayStartTime("出现消失开始时间", Range(0,1)) = 1
        _DisplayInOut("出现消失标记", Float) = 0
        _SDCameraClip("相机剔除强度", Range(0,1)) = 1

        [HideInInspector]_VFXFresnel("Fresnel进度测试", Float) = 0
        [HideInInspector]_VFXFresnelPow("Fresnel pow", Float) = 0
        [HideInInspector]_VFXFrenelStartTime("Fresnel anim start time", Float) = 0
        [HideInInspector]_VFXFrenelDuration("Fresnel anim duration", Float) = 0
        [HideInInspector]_VFXFrenelInOut("Fresnel in out", Float) = 0
        [HideInInspector][HDR]_VFXFresnelColor("Fresnel特效颜色", Color) = (13,2,0,1)
        [HideInInspector]_VFXFresnelIntensity("Fresnel强度", Float) = 0

        [CustomHeader(Hidden)]
        [HideInInspector] _AvatarLightDir("_AvatarLightDir", Vector) = (0, 0, 0, 0)
        [HideInInspector] _AvatarLightColor("_AvatarLightColor", Vector) = (1, 1, 1, 1)
        [HideInInspector] _AmbientLightColor("_AmbientLightColor", Vector) = (1, 1, 1, 1)
        [HideInInspector] _UIColorMask("_UIColorMask", Float) = 1
        [HideInInspector] _SatValue("去色", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry"
            "RenderType"="Opaque"
        }

        Stencil {
            Ref 5
            Comp Always
            Pass Replace
            Fail Keep
        }

        HLSLINCLUDE
        #pragma multi_compile _COLORGRADE
        #include_with_pragmas "./Cartoon-Lit-AvatarInput.hlsl"
        #include "./CommonHLSL.hlsl"
        #include "./ShadowProb.hlsl"
        #include "./ROOPTSubPassLoadUntils.hlsl"

        ENDHLSL


        
        Pass
        {
            Name "OutLine"
            Tags { "LightMode" = "UniversalForwardOnly" }
            
            cull front

            HLSLPROGRAM
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFragment

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD

            #include "./Cartoon-Lit-AvatarColorGradeUtils.hlsl"
            #include "./Cartoon-Lit-AvatarOutlinePass.hlsl"

            ENDHLSL
        }

        Pass
        {
            
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite [_ZWrite]
            cull [_Cull]
            Blend[_SrcBlend][_DstBlend]
        
            HLSLPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma vertex vert
            #pragma fragment frag
            

            #pragma multi_compile __ _RIMLIGHT
                
            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD

            #pragma shader_feature _DEBUG_OFF _DEBUG_BASE _DEBUG_RAMP _DEBUG_SCENEGI _DEBUG_SPECULAR _DEBUG_MATCAP _DEBUG_NORMAL _DEBUG_AO _DEBUG_ID _DEBUG_RIM

            #include "./Cartoon-Lit-AvatarColorGradeUtils.hlsl"
            #include "./Cartoon-Lit-AvatarForwardBasePass.hlsl"

            ENDHLSL

        }  

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "./Cartoon-Lit-AvatarDepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            Fog {Mode Off}
            ZWrite On ZTest LEqual Cull Off
            Offset 1, 1
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "./Cartoon-Lit-AvatarShadowCasterPass.hlsl"
            ENDHLSL
        }

    }

    CustomEditor "BigCatEditor.CartoonLitAvatarGUI"
}
