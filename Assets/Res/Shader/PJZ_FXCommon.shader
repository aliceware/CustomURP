Shader "ProjectZ/Effect/FXCommon" {
    Properties
    {
        // _ColParam: xy(remap-min/max);zw(pan-u/v)
        // _ColParamB: x(alpha intensity);y(color intensity);w(On/Off);
        [HideInInspector] _globalOpacity("global opacity", float) = 1

        // [CustomHeader(Tex_01)]
        [Main(Tex_01, _KEYWORD, on, off)] _groupTex_01 ("Tex_01(RGBA)-MainTex", float) = 1
        [KWEnum(Tex_01, Off, _ToggleOff, RGBColor, _ToggleColor, RGBRemap, _ToggleRemap)]_Tex01Type("Tex_01(RGBA):Off/Color/RGBRemap", float) = 1
        [SubEnum(Tex_01, Default, 0, ForceToClamp, 1)]_MainTexWrap("Tex_01 Wrap Mode", float) = 0
        [Sub(Tex_01)]_MainTex("Tex_01", 2D) = "white" {}

        [Color(Tex_01_ToggleRemap, _MainTexColorG, _MainTexColorB)]
        _MainTexColorR ("Tex_01 Remap R/G/B Color", Color) = (1, 0, 0, 1)
        [HideInInspector] _MainTexColorG (" ", Color) = (0, 1, 0, 1)
        [HideInInspector] _MainTexColorB (" ", Color) = (0, 0, 1, 1)

        [Sub(Tex_01)] _TintColor("Tex_01 Color", Color) = (1,1,1,1)

        [MinMaxSlider(Tex_01, _Tex01RemapMin, _Tex01RemapMax)] _Tex01ColorRemap("Tex_01 Color Remap MinMax", Range(-1, 3)) = 0
        [HideInInspector] _Tex01RemapMin("Tex_01 Color Remap Min", Range(-1, 3)) = 0
        [HideInInspector] _Tex01RemapMax("Tex_01 Color Remap Max", Range(-1, 3)) = 1

        [Sub(Tex_01)] _Tex01ColorInten("Tex_01 Color Intensity", Float) = 1
        [Sub(Tex_01)] _Tex01PanU("Tex_01 Color Panner U", Float) = 0
        [Sub(Tex_01)] _Tex01PanV("Tex_01 Color Panner V", Float) = 0
        [Sub(Tex_01)] _Tex01AlphaInten("Tex_01 Alpha Intensity", Float) = 1

        //扰动
        [Main(Tex_02, _KEYWORD, on, off)] _groupTex_02 ("Tex_02(R)-Noise", float) = 0
        [SubEnum(Tex_02, Off, 0, Turbulence, 1, Multiply, 2, Add, 3)]_Tex02Type("Tex_02(R):Off/Turbulence/Multiply/Add", float) = 0
        [SubEnum(Tex_02, Default, 0, ForceToClamp, 1)]_NoiseTexWrap("Tex_02 Wrap Mode", float) = 0
        [Sub(Tex_02)] _NoiseTex("Tex_02", 2D) = "white" {}
        [Sub(Tex_02)] _Tex02Inten("Tex_02 Intensity", Float) = 0
        [Sub(Tex_02)] _Tex02PanU("Tex_02 Panner U", Float) = 0
        [Sub(Tex_02)] _Tex02PanV("Tex_02 Panner V", Float) = 0

        //溶解
        [Main(Tex_03, _KEYWORD, on, off)] _groupTex_03 ("Tex_03(R)-Dissolve", float) = 0
        [SubEnum(Tex_03, Off, 0, SoftDissolve, 1, HardDissolve, 2)] _Tex03Type("Tex_03(R):Off/SoftDissolve/HardDissolve", Float) = 0
        [SubEnum(Tex_03, Default, 0, ForceToClamp, 1)]_DisTexWrap("Tex_03 Wrap Mode", float) = 0
        [Sub(Tex_03)] _DisTex("Tex_03(Dissolve)", 2D) = "black" {}
        [Sub(Tex_03)] _Tex03DissolveOffset("Tex_03 Dissolve Offset", Float) = 0
        [Sub(Tex_03)] _DisCol("Dissolve Side Color", Color) = (1,1,1,1)
        [Sub(Tex_03)] _DisColB("Dissolve Side ColorB", Color) = (1,1,1,1)
        [Sub(Tex_03)] _Tex03RemapMin("Tex_03 Side Color Remap Min", Float) = 0
        [Sub(Tex_03)] _Tex03RemapMax("Tex_03 Side Color Remap Max", Float) = 1
        [Sub(Tex_03)] _Tex03ColorInten("Tex_03 Side Color Intensity", Float) = 1
        [Sub(Tex_03)] _Tex03AlphaInten("Tex_03 Side Alpha Intensity", Float) = 1
        [Sub(Tex_03)] _Tex03SideWidth("Tex_03 Side Width", Float) = 0.1

        //遮罩
        // _MaskParam: x(intensity);y(offset);w(Off/Offset/Step)
        [Main(Tex_04, _KEYWORD, on, off)] _groupTex_04 ("Tex_04(R)-Mask", float) = 0
        [SubEnum(Tex_04, Off, 0, LinearU, 1, LinearV, 2, StepU, 3, StepV, 4)] _Tex04Type("Tex_04(R):Off/Mask(Panner Linear/Step)", Float) = 0
        [SubEnum(Tex_04, Default, 0, ForceToClamp,1)]_MaskTexWrap("Tex_04 Wrap Mode", Float) = 0
        [Sub(Tex_04)] _MaskTex("Tex_04(Mask)", 2D) = "white" {}
        [Sub(Tex_04)] _Tex04Inten("Tex_04 Intensity", Float) = 1
        [Sub(Tex_04)] _Tex04OffsetStep("Tex_04 Offset", Float) = 0
        [Sub(Tex_04)] _Tex04TurbStrength("_Tex04TurbStrength", Float) = 1

        //菲涅尔
        // _FresParam: x(intensity);y(Power);z(FresAlphaAdd);w(On/Off)
        // _FresSideParam: xy(remap-min/max);z(intensity)
        [Main(Fresnel, _Fres, off)] _Fres ("Fresnel", float) = 0
        [Sub(Fresnel)] _FresPow("Fresnel Power", Float) = 1
        [Sub(Fresnel)] _FresAlphaInten("Fresnel Alpha Intensity", Float) = 1
        [Sub(Fresnel)] _FresAlphaAdd("Fresnel Alpha Add", Float) = 0
        [Sub(Fresnel)] _FresCol("Fresnel Side Color", Color) = (1,1,1,1)
        [MinMaxSlider(Fresnel, _FresRemapMin, _FresRemapMax)] _FresRemap("Fresnel Side Remap MinMax", Range(-1, 3)) = 0
        [HideInInspector] _FresRemapMin("Fresnel Side Remap Min", Range(-1, 3)) = 0
        [HideInInspector] _FresRemapMax("Fresnel Side Remap Max", Range(-1, 3)) = 1
        [Sub(Fresnel)] _FresSideInten("Fresnel Side Intensity", Float) = 1

        //SinAlpha
        // _AlphaParam: xy(remap-min/max);z(Speed);w(On/Off)
        [Main(Sin, _Sin, off)] _Sin ("Enable(SinAlpha)", float) = 0
        // [SubToggle(Sin)] _Sin("Enable(SinAlpha)", Float) = 0
        [MinMaxSlider(Sin, _SinRemapMin, _SinRemapMax)] _SinRemap("Sin Remap MinMax", Range(-1, 3)) = 0
        [HideInInspector] _SinRemapMin("Sin Remap Min", Range(-1, 3)) = 0
        [HideInInspector] _SinRemapMax("Sin Remap Max", Range(-1, 3)) = 1
        [Sub(Sin)] _SinRate("Sin Rate", Float) = 1

        [Main(Advanced, _KEYWORD, on, off)] _groupAdvanced ("Advanced", float) = 0
        [SubToggle(Advanced, FOG_ENABLE)] _FogOn("Fog On", Float) = 0
        [SubEnum(Advanced, UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2

        [Title(Advanced, BlendMode)]
        [Preset(Advanced, LWGUI_BlendModePreset)] _Mode("Mode", Float) = 1.0
        [SubEnum(Advanced, UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 5.0
        [SubEnum(Advanced, UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 10.0

        [Title(Advanced, Z Options)]
        [SubToggle(Advanced)] _ZWrite("ZWrite On", Float) = 0.0
        [SubEnum(Advanced, UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
        [Sub(Advanced)]_OffsetFactor("Offset Factor", Float) = 0
        [Sub(Advanced)]_OffsetUnits("Offset Units", Float) = 0

        [Title(Advanced, SoftParticle)]
        [SubToggle(Advanced, _SOFTPARTICLES_ON)] _SoftParticlesEnabled("Soft Particle On", Float) = 0.0
        [MinMaxSlider(Advanced, _SoftFadeNear, _SoftFadeFar)] _SoftFadeNearFar("Soft Fade Near Far", Range(0, 3)) = 0
        [HideInInspector] _SoftFadeNear("Soft Fade Near", Range(0, 3)) = 0
        [HideInInspector] _SoftFadeFar("Soft Fade Far", Range(0, 3)) = 1
    }

    SubShader
        {
            Tags { "QUEUE" = "Transparent+200" "PreviewType"="Plane"}
            Pass
            {
                Blend[_SrcBlend][_DstBlend]
                ZWrite[_ZWrite] Lighting Off
                Cull [_Cull]
                ZTest [_ZTest]
                Offset [_OffsetFactor],[_OffsetUnits]
                // AlphaTest GEqual

                Name "ForwardLit"
                Tags{"LightMode" = "UniversalForward"}

                HLSLPROGRAM
                #pragma vertex vert  
                #pragma fragment frag
                #pragma multi_compile __ _ADDITIVE_ON
                #pragma multi_compile __ _SOFTPARTICLES_ON
                #pragma multi_compile __ LOCAL_HEIGHT_FOG
                #pragma multi_compile __ FOG_LINEAR
                #pragma multi_compile __ FOG_ENABLE

                #include "./FXCommonHLSL.hlsl"

                ENDHLSL
            }
        }
    CustomEditor "BigCatEditor.LWGUI"
}
