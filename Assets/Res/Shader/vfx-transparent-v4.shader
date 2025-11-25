Shader "Effect/vfx-transparent-v4"
{
    Properties
    {
        [CustomHeader(Total)]
        [Main(General, _KEYWORD, on, off)]_general("全局设置", float) = 1
        [Preset(General, LWGUI_BlendModePreset)]_BlendMode ("Blend Mode", float) = 1
        [SubToggle(General)]_ZWrite("ZWrite", Float) = 0.0
        [Sub(General)]_ZTest("ZTest", Float) = 2
        [SubEnum(General, off, 0, front, 1, back, 2)] _CullFunc("Cull", Float) = 0.0

        [CustomHeader(Texture)]
        [Main(BaseTexture, _KEYWORD, on, off)]_TextureGroup("基础贴图", float) = 1
        
        [Sub(BaseTexture)]_MainColorIntensity("总颜色强度", Range(0,10)) = 1
        [Sub(BaseTexture)]_MainOpaIntensity("总透明度", Range(0,1)) = 1

        [SubTitle(BaseTexture, BASE TEXTURE)]
        [Sub(BaseTexture)]_MainTex("主贴图", 2D) = "white" {}
        [SubEnum(BaseTexture, Default, 0, ForceToClamp, 1)]_MainTexWrap("贴图延展模式", float) = 0
        [SubEnum(BaseTexture, uv, 0, uv2, 1, screen, 2)]_MainTex_UVMode("UV模式", Float) = 0
        [Sub(BaseTexture)]_MainAngle("Base旋转角度", Range(0,1)) = 0
        [Sub(BaseTexture)]_MainTexMoveSpeedU("UV Panner X", Float) = 0
        [Sub(BaseTexture)]_MainTexMoveSpeedV("UV Panner Y", Float) = 0
        [Sub(BaseTexture)]_MainTex_uv_begin_end("UV 范围 %XY为起始UV,ZW为结束UV%", Vector) = (0,0,1,1)
        [SubToggle(BaseTexture)]_AutoSheetAnim("自动序列动画", float) = 0
        [ShowIf(_AutoSheetAnim, Equal, 1)][Sub(BaseTexture)]_SheetTileY("Y方向数量", float) = 1
        [ShowIf(_AutoSheetAnim, Equal, 1)][Sub(BaseTexture)]_SheetAnimSpeed("速度", float) = 0

        [SubTitle(BaseTexture, ADD TEXTURE)]
        [SubToggle(BaseTexture, _Toggle_AddTex)]_UseAddTex("Add贴图开关", Float) = 0
        [ShowIf(_UseAddTex, Equal, 1)][Sub(BaseTexture)]_AddTex("Add贴图", 2D) = "black" {}
        [ShowIf(_UseAddTex, Equal, 1)][SubEnum(BaseTexture, Default, 0, ForceToClamp, 1)]_AddTexWrap("贴图延展模式", float) = 0
        [ShowIf(_UseAddTex, Equal, 1)][SubEnum(BaseTexture, uv, 0, uv2, 1, screen, 2)]_AddTex_UVMode("UV模式", Float) = 0
        [ShowIf(_UseAddTex, Equal, 1)][Sub(BaseTexture)]_AddAngle("Add旋转角度", Range(0,1)) = 0
        [ShowIf(_UseAddTex, Equal, 1)][Sub(BaseTexture)]_AddTexMoveSpeedU("UV Panner X", Float) = 0
        [ShowIf(_UseAddTex, Equal, 1)][Sub(BaseTexture)]_AddTexMoveSpeedV("UV Panner Y", Float) = 0
        [ShowIf(_UseAddTex, Equal, 1)][Sub(BaseTexture)]_AddTex_uv_begin_end("UV 范围 %XY为起始UV,ZW为结束UV%", Vector) = (0,0,1,1)

        [SubTitle(BaseTexture, COLOR SETTING)]
        [KWEnum(BaseTexture, R, _Toggle_Main_R, G, _Toggle_Main_G, B, _Toggle_Main_B, RGB_3COLORBLEND, _Toggle_Main_RGB, RGB_ORIGIN, _Toggle_Main_Origin)]_ColorChannel_Main("颜色使用通道", float) = 0
        [ShowIf(_ColorChannel_Main, Equal, 3)][SubToggle(BaseTexture)]_3ColorBlend_GreenMain("绿通道优先", float) = 0
        [MinMaxSlider(BaseTexture, _TexColorBegin_Main, _TexColorEnd_Main)] _TexColorInterval_Main("颜色区间", Range(0, 1)) = 0
        [HideInInspector]_TexColorBegin_Main("颜色区间 开始", Range(0, 1)) = 0
        [HideInInspector]_TexColorEnd_Main("颜色区间 结束", Range(0, 1)) = 1
        [Sub(BaseTexture)][HDR]_tex_main_color_1("颜色 1", Color) = (1,1,1,0)
        [Sub(BaseTexture)][HDR]_tex_main_color_2("颜色 2", Color) = (0,0,0,0)
        [ShowIf(_ColorChannel_Main, Equal, 3)][Sub(BaseTexture)][HDR]_tex_main_color_3("颜色 3", Color) = (0,0,0,0)
        [SubToggle(BaseTexture, _Toggle_BackSideColor)]_SideColorMult("正反面明度控制", float) = 0
        [ShowIf(_SideColorMult, Equal, 1)][Sub(BaseTexture)][HDR]_tex_main_color_1_back("背面颜色 1", Color) = (1,1,1,0)
        [ShowIf(_SideColorMult, Equal, 1)][Sub(BaseTexture)][HDR]_tex_main_color_2_back("背面颜色 2", Color) = (0,0,0,0)
        [ShowIf(_SideColorMult, Equal, 1)][Sub(BaseTexture)][HDR]_tex_main_color_3_back("背面颜色 3", Color) = (0,0,0,0)
        [SubTitle(BaseTexture, ALPHA SETTING)]
        [SubEnum(BaseTexture, R, 0, G, 1, B, 2, A, 3, None, 4)]_AlphaUse_Main("透明度使用通道", float) = 3
        [MinMaxSlider(BaseTexture, _TexAlphaBegin_Main, _TexAlphaEnd_Main)] _TexAlphaInterval_Main("Alpha区间", Range(0, 1)) = 0
        [HideInInspector]_TexAlphaBegin_Main("Alpha区间 开始", Range(0, 1)) = 0
        [HideInInspector]_TexAlphaEnd_Main("Alpha区间 结束", Range(0, 1)) = 1
        [Sub(BaseTexture)]_TexAlphaWeight_Main("Alpha权重", Float) = 1

        //遮罩
        // _MaskParam: x(intensity);y(offset);w(Off/Offset/Step)
        [Main(Mask, _KEYWORD, off)] _groupTex_Mask ("遮罩", float) = 0
        [SubEnum(Mask, Default, 0, ForceToClamp, 1)]_MaskTexWrap("贴图延展模式", Float) = 0
        [Sub(Mask)] _MaskTex("Mask贴图", 2D) = "white" {}
        [SubEnum(Mask, uv, 0, uv2, 1, screen, 2)]_MaskTex_UVMode("UV模式", Float) = 0
        [Sub(Mask)] _MaskAngle("Mask旋转角度", Range(0,1)) = 0
        [Sub(Mask)] _MaskIntensity("Mask Intensity", Float) = 1
        [Sub(Mask)] _MaskPannerU("Mask自动偏移U", Float) = 0
        [Sub(Mask)] _MaskPannerV("Mask自动偏移V", Float) = 0
        [KWEnum(Mask, Linear, _Toggle_LinearOffset, Step, _Toggle_StepOffset)] _MaskOffsetType("Mask曲线控制偏移方式", Float) = 0
        [Sub(Mask)] _MaskOffsetU("曲线控制偏移U贡献", Float) = 1
        [Sub(Mask)] _MaskOffsetV("曲线控制偏移V贡献", Float) = 0
        [Sub(Mask_Toggle_StepOffset)] _MaskOffsetStep("Mask Offset Step", Float) = 0
        [Sub(Mask)] _MaskAll("整体遮罩贴图", 2D) = "white" {}
        //[Sub(Tex_04)] _Tex04TurbStrength("_Tex04TurbStrength", Float) = 1

        [CustomHeader(Noise)]
        [Main(Noise, _KEYWORD, off)] _groupTex_Noise ("Noise", float) = 0
        [KWEnum(Noise, Turbulence, _Toggle_Turbulence, Multiply, _, Add, _)]_Tex02Type("Noise作用", float) = 0
        [SubEnum(Noise, Default, 0, ForceToClamp, 1)]_NoiseTexWrap("贴图延展模式", float) = 0
        [Sub(Noise)] _NoiseTex("Noise贴图", 2D) = "white" {}
        [SubEnum(Noise, uv, 0, uv2, 1, screen, 2)]_NoiseTex_UVMode("UV模式", Float) = 0
        [Sub(Noise)] _NoiseAngle("Noise旋转角度", Range(0,1)) = 0
        [SubToggle(Noise, _Toggle_NoiseTexIntensity)] _UseNoiseIntensityTexture("使用贴图控制强度", float) = 0
        [Sub(Noise_Toggle_NoiseTexIntensity)] _NoiseMask("Noise强度贴图", 2D) = "white" {}
        [Sub(Noise_Toggle_Turbulence)] _NoiseIntenMain("扰动作用于主贴图强度", Float) = 1
        [Sub(Noise_Toggle_Turbulence)] _NoiseIntenMask("扰动作用于Mask强度", Float) = 1
        [Sub(Noise_Toggle_Turbulence)] _NoiseIntenDis("扰动作用于溶解贴图强度", Float) = 1
        [Sub(Noise)] _NoisePanU("Noise Panner U", Float) = 0
        [Sub(Noise)] _NoisePanV("Noise Panner V", Float) = 0

        //溶解
        [CustomHeader(Dissolution)]
        [Main(Dissolution, _, off)]_groupTex_Dis("溶解(Dissolution/Time)", float) = 0
        [SubTitle(Dissolution, DISOLVE SETTING)]
        [Sub(Dissolution)] _DisProcessTest("溶解进度测试", Range(0,1)) = 0
        [KWEnum(Dissolution, UV, _, Direct, _Toggle_DirectDis)]_DisMode("溶解模式（UV方向或世界坐标方向）", Float) = 0
        [ShowIf(_DisMode, Equal, 1)][Sub(Dissolution)] _DisTexScale("方向性溶解，范围大小", Float) = 1
        [ShowIf(_DisMode, Equal, 1)][Sub(Dissolution)] _DisTexContribution("方向性溶解 贴图贡献程度", Range(0, 1)) = 0
        [ShowIf(_DisMode, Equal, 1)][Sub(Dissolution)] _DisDir("方向性溶解 溶解方向(局部坐标)", Vector) = (1,0,0,0)
        [SubTitle(Dissolution, TEXTURE SETTING)]
        [Sub(Dissolution)]_DisTex("溶解贴图", 2D) = "white" {}
        [SubEnum(Dissolution, uv, 0, uv2, 1, screen, 2)]_DisTex_UVMode("UV模式", Float) = 0
        [SubEnum(Dissolution, Default, 0, ForceToClamp, 1)]_DisTexWrap("贴图延展模式", float) = 0
        [Sub(Dissolution)] _DisAngle("Dissolve贴图旋转角度", Range(0,1)) = 0
        [Sub(Dissolution)] _DisPannerU("溶解 Panner U", Float) = 0
        [Sub(Dissolution)] _DisPannerV("溶解 Panner V", Float) = 0
        [SubTitle(Dissolution, ALPHA SETTING)]
        [Sub(Dissolution)]_dissolution_AlphaSoftness("溶解软硬程度", Range(0, 1)) = 0
        [SubTitle(Dissolution, SIDE SETTING)]
        [Sub(Dissolution)]_dissolution_SideWidth("溶解边缘颜色宽度", Range(0, 1)) = 0
        [Sub(Dissolution)]_dissolution_SideSoftness("溶解边缘软硬", Range(0, 1)) = 0
        [Sub(Dissolution)][HDR]_dissolution_SideColor("溶解边缘颜色", Color) = (1,1,1,1)

        //菲涅尔
        // _FresParam: x(intensity);y(Power);z(FresAlphaAdd);w(On/Off)
        // _FresSideParam: xy(remap-min/max);z(intensity)
         [CustomHeader(Fresnel)]
        [Main(Fresnel, _Fres, off)] _group_Fres ("菲涅尔", float) = 0
        [SubToggle(Fresnel)] _FresInvert("反向", Float) = 0
        [Sub(Fresnel)] _FresPow("Fresnel Power", Float) = 1
        [Sub(Fresnel)] _FresAlphaInten("Fresnel Alpha Intensity", Float) = 1
        [Sub(Fresnel)] _FresAlphaAdd("Fresnel Alpha Add", Float) = 0
        [Sub(Fresnel)][HDR] _FresCol("Fresnel Side Color", Color) = (1,1,1,1)
        [MinMaxSlider(Fresnel, _FresRemapMin, _FresRemapMax)] _FresRemap("Fresnel Side Remap MinMax", Range(-1, 3)) = 0
        [HideInInspector] _FresRemapMin("Fresnel Side Remap Min", Range(-1, 3)) = 0
        [HideInInspector] _FresRemapMax("Fresnel Side Remap Max", Range(-1, 3)) = 1
        [Sub(Fresnel)] _FresSideInten("Fresnel Side Intensity", Float) = 1

        //顶点动画
        [CustomHeader(HeightMap)]
        [Main(HeightMap, _ENALBE_HEIGHT, off)] _heightMapGroup("顶点动画", float) = 0
        [Sub(HeightMap)]_HeightScale("偏移程度", Float) = 0.5
        [Sub(HeightMap)]_HeightMap("Height 贴图", 2D) = "black" {}
        [SubToggle(HeightMap)]_HeightTex_use_uv2("使用UV2", Float) = 0
        [Sub(HeightMap)]_HeightTexMoveSpeedU("Height Panner U", Float) = 0
        [Sub(HeightMap)]_HeightTexMoveSpeedV("Height Panner V", Float) = 0

        //视差
        [CustomHeader(Parallax)]
        [Main(Parallax, _, off)] _gourp_parallax("视差", float) = 0
        [Sub(Parallax)]_ParallaxOffset("视差偏移量",range(0,1)) = 1
        [Sub(Parallax)]_ParallaxMap("视差贴图", 2D) = "black" {}

        [CustomHeader(DepthFade)]
        [Main(DepthFade, _, off)] _gourp_depthFade("软边缘", float) = 0
        [Sub(DepthFade)]_DepthDist("_DepthDist",Float) = 5

        [CustomHeader(Advance)]
        _SrcBlend("SrcBlend", Float) = 1
        _DstBlend("DstBlend", Float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }


        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend [_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            ZTest [_ZTest]
            Cull[_CullFunc]
            
            HLSLPROGRAM
            #pragma multi_compile _ _ENALBE_HEIGHT

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
            #pragma multi_compile __ RO_MS_READ
            #pragma multi_compile __ RO_FORCE_STORE_READ

            #pragma multi_compile_instancing

            #pragma vertex Vert
            #pragma fragment Frag

            #include "./CommonHLSL.hlsl"
            #include "./ROOPTSubPassLoadUntils.hlsl"

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                sampler2D _AddTex;
                sampler2D _NoiseTex;
                sampler2D _NoiseMask;
                sampler2D _MaskTex;
                sampler2D _DisTex;
                sampler2D _HeightMap;

                half4 _MainTex_ST;
                half4 _AddTex_ST;
                half4 _NoiseTex_ST;
                half4 _NoiseMask_ST;
                half4 _MaskTex_ST;
                half4 _DisTex_ST;
                half4 _HeightMap_ST;


                half _MainColorIntensity;
                half _MainOpaIntensity;
//////////////main tex////////////////////
                half _MainTexWrap;
                half _MainTex_UVMode;
                half _MainAngle;
                half _MainTexMoveSpeedU;
                half _MainTexMoveSpeedV;
                half4 _MainTex_uv_begin_end;
                half _UseAddTex;
                half _AddTexWrap;
                half _AddTex_UVMode;
                half _AddAngle;
                half _AddTexMoveSpeedU;
                half _AddTexMoveSpeedV;
                half4 _AddTex_uv_begin_end;
                half _AutoSheetAnim;
                half _SheetTileY;
                half _SheetAnimSpeed;

                half _ColorChannel_Main;
                half _3ColorBlend_GreenMain;
                half _TexColorBegin_Main;
                half _TexColorEnd_Main;
                half3 _tex_main_color_1;
                half3 _tex_main_color_2;
                half3 _tex_main_color_3;
                half _AlphaUse_Main;
                half _TexAlphaBegin_Main;
                half _TexAlphaEnd_Main;
                half _TexAlphaWeight_Main;

                half _SideColorMult;
                half3 _tex_main_color_1_back;
                half3 _tex_main_color_2_back;
                half3 _tex_main_color_3_back;

//////////////mask////////////////////
                half _groupTex_Mask;
                half _MaskTexWrap;
                half _MaskTex_UVMode;
                half _MaskIntensity;
                half _MaskAngle;
                half _MaskPannerU;
                half _MaskPannerV;
                half _MaskOffsetType;
                half _MaskOffsetU;
                half _MaskOffsetV;
                half _MaskOffsetStep;

//////////////noise////////////////////
                half _groupTex_Noise;
                half _UseNoiseIntensityTexture;
                half _NoiseTex_UVMode;
                half _Tex02Type;
                half _NoiseIntenMain;
                half _NoiseAngle;
                half _NoiseIntenMask;
                half _NoiseIntenDis;
                half _NoisePanU;
                half _NoisePanV;
                half _NoiseTexWrap;

//////////////dissolution////////////////////
                half _groupTex_Dis;
                half _DisMode;
                half _DisProcessTest;
                half _DisTex_UVMode;
                half _DisTexContribution;
                half3 _DisDir;
                half _DisTexScale;
                half _DisTexWrap;
                half _DisAngle;
                half _DisPannerU;
                half _DisPannerV;
                half _dissolution_AlphaSoftness;
                half3 _dissolution_SideColor;
                half _dissolution_SideWidth;
                half _dissolution_SideSoftness;

////////////////fresnel//////////////////////
                half _group_Fres;
                half _FresInvert;
                half _FresPow;
                half _FresAlphaInten;
                half _FresAlphaAdd;
                half3 _FresCol;
                half _FresRemapMin;
                half _FresRemapMax;
                half _FresSideInten;

///////////////Height////////////////////////
                half _HeightScale;
                half _HeightTex_use_uv2;
                half _HeightTexMoveSpeedU;
                half _HeightTexMoveSpeedV;

/////////////Parallax/////////////////////////
                half _gourp_parallax;
                half _ParallaxOffset;
                sampler2D _ParallaxMap;
                half4 _ParallaxMap_ST;

                //depthfade
                half _gourp_depthFade;
                half _DepthDist;

            CBUFFER_END

            RO_FRAMEBUFFER_DECLARE_INPUT
            struct VertexInput
            {
                half4 positionOS                : POSITION;
                half4 color                     : COLOR;
                half4 uv                        : TEXCOORD0;
                half4 uv1                       : TEXCOORD1;
                half4 texcoord2                 : TEXCOORD2;
                half3 normalOS                  : NORMAL;
                half4 tangentOS                 : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                half4 positionCS                : SV_POSITION;
                half4 color                     : COLOR;
                half2 uv                        : TEXCOORD0;
                half2 uv1                       : TEXCOORD1;
                half4 customData                : TEXCOORD2;//x(mask offset);y(dissolve);zw(main/dissolve uv offset)   
                half3 normalWS                  : TEXCOORD3;
                half3 positionWS                : TEXCOORD4;
                half3 viewDir                   : TEXCOORD5;
                half3 viewDirWS                 : TEXCOORD6;
                half4 scrPos                    : TEXCOORD7;
                float2 screenUV                 : TEXCOORD8;
                float3 centerPos                : TEXCOORD9;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput Vert(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float deltaTime = _Time.y % 100.0f;
                output.uv.xy = input.uv.xy;
                output.uv1.xy = input.uv1.xy;
                output.customData.xy = input.uv.zw;
                output.customData.zw = input.uv1.zw;

                output.color = input.color;
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS,input.tangentOS);
                output.normalWS = mul(input.normalOS, (float3x3)GetWorldToObjectMatrix());

                float3 positionOS = input.positionOS;
                //////////////////////////////////// Height ///////////////////////////////////////
                #ifdef _ENALBE_HEIGHT
                    half2 heightUV = _HeightTex_use_uv2 > 0 ? input.uv1.xy : input.uv.xy;
                    heightUV = TRANSFORM_TEX(heightUV, _HeightMap);
                    heightUV += deltaTime * half2(_HeightTexMoveSpeedU, _HeightTexMoveSpeedV);
                    half3 HeightMap = tex2Dlod(_HeightMap, float4(heightUV,0,0)).r;
                    positionOS += output.normalWS * HeightMap *_HeightScale;
                #endif
                ///////////////////////////////////////////////////////////////////////////////////

                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(positionOS);
                output.positionCS = vertexPositionInput.positionCS;
                float3 positionVS = vertexPositionInput.positionVS;
                output.positionWS = vertexPositionInput.positionWS;

                float3x3 rotation = float3x3(vertexNormalInput.tangentWS,vertexNormalInput.bitangentWS,vertexNormalInput.normalWS);
                output.viewDirWS = normalize(GetCameraPositionWS() - output.positionWS);
                output.viewDir = mul(rotation,output.viewDirWS);

                // float originDist = mul(UNITY_MATRIX_MV, float3(0.0,0.0,0.0)).z;
                output.screenUV = positionVS.xy / positionVS.z;
                TransformScreenUV(output.screenUV);
                // output.screenUV *= originDist;
            
                output.scrPos = ComputeScreenPos(output.positionCS);
                output.centerPos = input.texcoord2;
                return output;
            }

            half Remap_Float(half x, half t1, half t2, half s1, half s2)
            {
                
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }

            RO_TRANSPARENT_PIXEL_SHADER_FUNCTION(Frag, VertexOutput input)
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float deltaTime = _Time.y % 100.0f;

                half4 color = half4(0,0,0,1);
                half noise = 1;
                half NdotV = abs(dot(input.normalWS, input.viewDirWS));
                float fresnel = (_FresInvert > 0.5) ? NdotV : 1-NdotV;
                fresnel = fresnel * 0.5 + 0.5;
                fresnel = saturate(pow(fresnel,_FresPow));
                float2 scrUV = input.screenUV.xy + 0.5;

                // uv setting begin
                // main tex uv
                float2 mainUV = (_MainTex_UVMode > 0.5) ? ((_MainTex_UVMode > 1.5) ? scrUV : input.uv1.xy) : input.uv.xy;
                float2 tmpMainUV = mainUV;
                tmpMainUV -= 0.5;
				float2 finalMainUV = 0;
                half angle = _MainAngle * 2 * PI;
				finalMainUV.x = tmpMainUV.x*cos(angle) - tmpMainUV.y*sin(angle);//旋转x
				finalMainUV.y = tmpMainUV.x*sin(angle) + tmpMainUV.y*cos(angle);//旋转y
				finalMainUV += 0.5;
                mainUV = finalMainUV;
                mainUV.x = Remap(mainUV.x, 0, 1, _MainTex_uv_begin_end.x, _MainTex_uv_begin_end.z);
                mainUV.y = Remap(mainUV.y, 0, 1, _MainTex_uv_begin_end.y, _MainTex_uv_begin_end.w);
                mainUV += deltaTime * half2(_MainTexMoveSpeedU, _MainTexMoveSpeedV);
                mainUV += input.customData.zw;
                if(_AutoSheetAnim > 0.5)
                {
                    float yoffset = round(_SheetAnimSpeed * deltaTime);
                    half _SheetAnimStart = yoffset / _SheetTileY;
                    half _SheetAnimEnd = _SheetAnimStart + 1/_SheetTileY;
                    mainUV.y = Remap(mainUV.y, 0, 1, _SheetAnimStart, _SheetAnimEnd);
                }
                mainUV = TRANSFORM_TEX(mainUV, _MainTex);
                if(_gourp_parallax > 0.5)
                {
                    float ParallaxScale = _ParallaxOffset / 100.0f;
                    float2 tempMainUV = mainUV;
                    float viewZ = input.viewDir.z;
                    float2 parallaxOffset = (tex2D(_ParallaxMap, tempMainUV).r - 1) * input.viewDir.xy / viewZ * ParallaxScale + tempMainUV;
                    for(uint i=0; i < 20; i++) 
                    {
                        float2 tempOffset = parallaxOffset;
                        parallaxOffset = (tex2D(_ParallaxMap, tempOffset).r - 1) * input.viewDir.xy / viewZ * ParallaxScale + tempOffset;
                    }
                    mainUV = parallaxOffset;
                }
                if (_MainTexWrap > 0)
                {
                    mainUV = saturate(mainUV);
                }

                // add tex uv
                float2 addUV = (_AddTex_UVMode > 0.5) ? ((_AddTex_UVMode > 1.5) ? scrUV : input.uv1.xy) : input.uv.xy;
                if(_UseAddTex > 0.5)
                {
                    
                    float2 tmpAddUV = addUV;
                    tmpAddUV -= 0.5;
                    float2 finalAddUV = 0;
                    half angle = _AddAngle * 2 * PI;
                    finalAddUV.x = tmpAddUV.x*cos(angle) - tmpAddUV.y*sin(angle);//旋转x
                    finalAddUV.y = tmpAddUV.x*sin(angle) + tmpAddUV.y*cos(angle);//旋转y
                    finalAddUV += 0.5;
                    addUV = finalAddUV;
                    addUV.x = Remap(addUV.x, 0, 1, _AddTex_uv_begin_end.x, _AddTex_uv_begin_end.z);
                    addUV.y = Remap(addUV.y, 0, 1, _AddTex_uv_begin_end.y, _AddTex_uv_begin_end.w);
                    addUV += deltaTime * half2(_AddTexMoveSpeedU, _AddTexMoveSpeedV);
                    addUV += input.customData.zw;
                    addUV = TRANSFORM_TEX(addUV, _AddTex);
                    if (_AddTexWrap > 0)
                    {
                        addUV = saturate(addUV);
                    }
                }
               
               // mask tex uv
                float2 maskUV = (_MaskTex_UVMode > 0.5) ? ((_MaskTex_UVMode > 1.5) ? scrUV : input.uv1.xy) : input.uv.xy;
                maskUV = TRANSFORM_TEX(maskUV, _MaskTex);
                float2 tmpMaskUV = maskUV;
                tmpMaskUV -= 0.5;
				float2 finalMaskUV = 0;
                angle = _MaskAngle * 2 * PI;
				finalMaskUV.x = tmpMaskUV.x*cos(angle) - tmpMaskUV.y*sin(angle);//旋转x
				finalMaskUV.y = tmpMaskUV.x*sin(angle) + tmpMaskUV.y*cos(angle);//旋转y
				finalMaskUV += 0.5;
                maskUV = finalMaskUV;
                half offset = 0;
                if(_MaskOffsetType > 0.5){//step
                    offset = round(input.customData.x) * _MaskOffsetStep;
                    maskUV.xy += half2(_MaskOffsetU, _MaskOffsetV) * offset;
                }
                else{//offset
                    offset = input.customData.x + _MaskOffsetStep;
                }
                maskUV.xy += deltaTime * half2(_MaskPannerU, _MaskPannerV);
                maskUV.xy += half2(_MaskOffsetU, _MaskOffsetV) * offset;

                // noise tex uv
                half2 noiseUV = (_NoiseTex_UVMode > 0.5) ? ((_NoiseTex_UVMode > 1.5) ? scrUV : input.uv1.xy) : input.uv.xy;
                noiseUV = TRANSFORM_TEX(noiseUV, _NoiseTex);
                float2 tmpNoiseUV = noiseUV;
                tmpNoiseUV -= 0.5;
				float2 finalNoiseUV = 0;
                angle = _NoiseAngle * 2 * PI;
				finalNoiseUV.x = tmpNoiseUV.x*cos(angle) - tmpNoiseUV.y*sin(angle);//旋转x
				finalNoiseUV.y = tmpNoiseUV.x*sin(angle) + tmpNoiseUV.y*cos(angle);//旋转y
				finalNoiseUV += 0.5;
                noiseUV = finalNoiseUV;
                noiseUV += deltaTime * half2(_NoisePanU, _NoisePanV);
                if (_NoiseTexWrap > 0)
                {
                    noiseUV = saturate(noiseUV);
                }

                // dissolve tex uv
                float2 disUV = (_DisTex_UVMode > 0.5) ? ((_DisTex_UVMode > 1.5) ? scrUV : input.uv1.xy) : input.uv.xy;
                disUV = TRANSFORM_TEX(disUV, _DisTex);
                float2 tmpDisUV = disUV;
                tmpDisUV -= 0.5;
				float2 finaDisUV = 0;
                angle = _DisAngle * 2 * PI;
				finaDisUV.x = tmpDisUV.x*cos(angle) - tmpDisUV.y*sin(angle);//旋转x
				finaDisUV.y = tmpDisUV.x*sin(angle) + tmpDisUV.y*cos(angle);//旋转y
				finaDisUV += 0.5;
                disUV = finaDisUV;
                disUV += deltaTime * half2(_DisPannerU, _DisPannerV);
                if (_DisTexWrap > 0)
                {
                    disUV = saturate(disUV);
                }

                if (_groupTex_Noise > 0)
                {
                    float noiseIntensity = 1;
                    if(_UseNoiseIntensityTexture > 0.5)
                    {
                        float2 noiseMaskUV = TRANSFORM_TEX(input.uv.xy, _NoiseMask);
                        noiseIntensity *= tex2D(_NoiseMask, noiseMaskUV).r;
                    }
                    noise = tex2D(_NoiseTex, noiseUV).r * noiseIntensity;
                    if(_Tex02Type < 0.5){
                        //turbulence
                        mainUV += noise * _NoiseIntenMain;
                        disUV += noise * _NoiseIntenDis;
                        maskUV += noise * _NoiseIntenMask;
                    }
                }
                //uv setting end



                //////////////////////////////////// Main Color Begin///////////////////////////////////////
                half4 mainTex = tex2D(_MainTex, mainUV);
                half3 baseCol = mainTex.rgb;
                if(_UseAddTex > 0.5)
                {
                    half4 addTex = tex2D(_AddTex, addUV);
                    baseCol += addTex.rgb;
                }
                half colorArea_Main = _ColorChannel_Main > 0 ? (_ColorChannel_Main > 1.5 ? baseCol.b : baseCol.g) : baseCol.r;
                half3 mainCol = 1;
                if(_ColorChannel_Main > 3.5)
                {
                    mainCol = baseCol.rgb;
                }
                else
                {
                    half3 color1 = _tex_main_color_1;
                    half3 color2 = _tex_main_color_2;
                    half3 color3 = _tex_main_color_3;
                    
                    if(_SideColorMult > 0)
                    {
                        half face = sign(-NdotV);
                        color1 = (face > 0) ? _tex_main_color_1_back : _tex_main_color_1;
                        color2 = (face > 0) ? _tex_main_color_2_back : _tex_main_color_2;
                        color3 = (face > 0) ? _tex_main_color_3_back : _tex_main_color_3;
                    }
                    

                    if(_ColorChannel_Main > 2.5)
                    {
                        if(_3ColorBlend_GreenMain > 0)
                        {
                            mainCol = lerp(lerp(color3 * baseCol.b, color1, baseCol.r), color2, baseCol.g);
                        }
                        else
                        {
                            mainCol = lerp(lerp(color3 * baseCol.b, color2, baseCol.g), color1, baseCol.r);
                        }
                    }
                    else
                    {
                        colorArea_Main = saturate(Remap_Float(colorArea_Main, _TexColorBegin_Main, _TexColorEnd_Main, 0, 1));
                        mainCol = lerp(color2, color1, colorArea_Main);
                    }
                }
                
                //////////////////////////////////// Main Color End ///////////////////////////////////////

                float mainAlpha;
                if(_AlphaUse_Main > 3.5)
                {
                    mainAlpha = 1;
                }
                else
                {
                    mainAlpha = _AlphaUse_Main > 0 ? (_AlphaUse_Main > 1.5 ? (_AlphaUse_Main > 2.5 ? mainTex.a : mainTex.b) : mainTex.g) : mainTex.r;
                    mainAlpha = lerp(1, mainAlpha, _TexAlphaWeight_Main);
                    mainAlpha = saturate(Remap_Float(mainAlpha, _TexAlphaBegin_Main, _TexAlphaEnd_Main, 0, 1));
                }

                if (_Tex02Type > 0.5)
                {
                    if(_Tex02Type < 1.5){
                        //multiply
                        mainCol *= noise;
                        mainAlpha *= noise;
                    }
                    else{
                        //add
                        mainCol += noise;
                        mainAlpha += noise;
                    }
                }

                if(_groupTex_Mask > 0)
                {
                    if (_MaskTexWrap > 0)
                    {
                        maskUV = saturate(maskUV);
                    }
                    mainAlpha *= tex2D(_MaskTex, maskUV).r * _MaskIntensity;
                    mainAlpha = saturate(mainAlpha);
                }

                if (_group_Fres > 0)//fresAlpha
                {
                    half fresAlpha = fresnel * _FresAlphaInten;
                    fresAlpha = saturate(fresAlpha + _FresAlphaAdd);
                    mainAlpha *= fresAlpha;
                }

            /////////////////////////溶解/////////////////////////////////////////
                if(_groupTex_Dis > 0)
                {
                    float disProgress = (_DisProcessTest > 0) ? _DisProcessTest : input.customData.y;
                    half4 disMap = tex2D(_DisTex, disUV);
                    half disMount = disMap.r;
                    if(_DisMode > 0.5)
                    {
                        float3 pos = input.positionWS.xyz - input.centerPos;
                        float posOffset = dot(normalize(_DisDir), pos);

                        float scale = (1/_DisTexScale);
                        disMount = saturate((posOffset * scale * 0.5 + 0.5)) - disMap.r * _DisTexContribution;                        
                    }
                    
                    // dis alpha
                    half disAlpha = saturate((disMount + ((1 - disProgress) * 2 - 1)));
                    mainAlpha *= smoothstep(_dissolution_AlphaSoftness - 0.001, 1, disAlpha);
                    // dis side color
                    float side_inv = saturate((disMount + ((1 - disProgress) * 2 - 1) - _dissolution_SideWidth));
                    float sideColArea = smoothstep(_dissolution_SideSoftness - 0.001, 1, side_inv);
                    mainCol = lerp(_dissolution_SideColor, mainCol, sideColArea);
                    // mainCol += side * 100;
                }

            /////////////////////////fresnel///////////////////////////////////////

                if(_group_Fres > 0)
                {
                    half3 fresCol = fresnel * mainCol;
                    half fresColArea = saturate(Remap_Float(fresnel,_FresRemapMin,_FresRemapMax,0,1));
                    mainCol = lerp(mainCol,_FresCol.rgb * _FresSideInten, fresColArea);
                }

                // RO_TRANSPARENT_PIXEL_OUTPUT(float4(disAlpha.xxx, 1));
                color.rgb = mainCol * input.color.rgb * _MainColorIntensity;
                color.a = mainAlpha * input.color.a * _MainOpaIntensity;

                RO_TRANSPARENT_PIXEL_INPUT;
                float2 screenSpaceUV = input.positionCS.xy;
                float rawD = GET_SUBPASS_LOAD_DEPTH(screenSpaceUV);
                float sceneRawDepth = LinearEyeDepth(rawD.r, _ZBufferParams);

                float4 screenPos = input.scrPos / input.scrPos.w;
                
                if(_gourp_depthFade > 0.5)
                {
                    float distanceDepth = abs((sceneRawDepth - LinearEyeDepth(screenPos.z , _ZBufferParams)) / (_DepthDist));
                    distanceDepth = max((1.0 - distanceDepth), 0.0001);
                    float DepthInteraction =  smoothstep(0, 1, saturate(distanceDepth));
                    DepthInteraction = 1- saturate( DepthInteraction);
                    
                    color.a *= DepthInteraction;
                }

                RO_TRANSPARENT_PIXEL_OUTPUT(color)
            }


            ENDHLSL
        }
    }
    CustomEditor "BigCatEditor.LWGUI"
}
