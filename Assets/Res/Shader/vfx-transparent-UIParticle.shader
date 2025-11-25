Shader "Effect/vfx-transparent-UIParticle"
{
    Properties
    {
        //全局
        [CustomHeader(Total)]
        [Main(General, _KEYWORD, on, off)]_general("全局设置", float) = 1
        [Preset(General, LWGUI_BlendModePreset)]_BlendMode ("Blend Mode", float) = 1
        [SubToggle(General)]_ZWrite("ZWrite", Float) = 0.0
        [Sub(General)]_ZTest("ZTest", Float) = 2
        [SubEnum(General, off, 0, front, 1, back, 2)] _CullFunc("Cull", Float) = 2

        //基础贴图
        [CustomHeader(Texture)]
        [Main(BaseTexture, _KEYWORD, on, off)]_TextureGroup("基础贴图", float) = 1
        [Sub(BaseTexture)]_MainColorIntensity("总颜色强度", Range(0,10)) = 1
        [Sub(BaseTexture)]_MainOpaIntensity("总透明度", Range(0,1)) = 1
        
        [SubTitle(BaseTexture, BASE TEXTURE)]
        [Sub(BaseTexture)]_MainTex("主贴图", 2D) = "white" {}
        [SubEnum(BaseTexture, Default, 0, ForceToClamp, 1)]_MainTexWrap("贴图延展模式", float) = 0
        [Sub(BaseTexture)]_MainTexMoveSpeedU("UV Panner X", Float) = 0
        [Sub(BaseTexture)]_MainTexMoveSpeedV("UV Panner Y", Float) = 0
        [Sub(BaseTexture)]_MainTex_uv_begin_end("UV 范围 %XY为起始UV,ZW为结束UV%", Vector) = (0,0,1,1)

        [SubTitle(BaseTexture, ROTATE SCALE)]
        [SubToggle(BaseTexture)]_MainTexRotate("贴图旋转", float) = 0
        [ShowIf(_MainTexRotate, Equal, 1)][Sub(BaseTexture)]_MainRotateAngle("旋转角度", Range(-180,180)) = 0
        [ShowIf(_MainTexRotate, Equal, 1)][Sub(BaseTexture)]_MainRotateSpeed("旋转速度", float) = 0

        [SubToggle(BaseTexture)]_MainTexScale("贴图收缩", float) = 0
        // [MinMaxSlider(BaseTexture, _MainScaleMin, _MainScaleMax)] _MainScaleRange("收缩范围",float) = 0
        [ShowIf(_MainTexScale, Equal, 1)][Sub(BaseTexture)] _MainScaleMin("缩放最小值", float) = 1
        [ShowIf(_MainTexScale, Equal, 1)][Sub(BaseTexture)] _MainScaleMax("缩放最大值", float) = 2
        [ShowIf(_MainTexScale, Equal, 1)][Sub(BaseTexture)]_MainScaleSpeed("收缩速度", float) = 0
        
        [SubTitle(BaseTexture, COLOR SETTING)]
        [KWEnum(BaseTexture, R, _Toggle_Main_R, G, _Toggle_Main_G, B, _Toggle_Main_B, RGB_ORIGIN, _Toggle_Main_Origin)]_ColorChannel_Main("颜色使用通道", float) = 3
        [MinMaxSlider(BaseTexture, _TexColorBegin_Main, _TexColorEnd_Main)] _TexColorInterval_Main("颜色区间", Range(0, 1)) = 0
        [HideInInspector]_TexColorBegin_Main("颜色区间 开始", Range(0, 1)) = 0
        [HideInInspector]_TexColorEnd_Main("颜色区间 结束", Range(0, 1)) = 1
        [Sub(BaseTexture)][HDR]_tex_main_color_1("颜色 1", Color) = (1,1,1,0)
        [Sub(BaseTexture)][HDR]_tex_main_color_2("颜色 2", Color) = (0,0,0,0)
        
        [SubTitle(BaseTexture, ALPHA SETTING)]
        [SubEnum(BaseTexture, R, 0, G, 1, B, 2, A, 3, None, 4)]_AlphaUse_Main("透明度使用通道", float) = 3
        [MinMaxSlider(BaseTexture, _TexAlphaBegin_Main, _TexAlphaEnd_Main)] _TexAlphaInterval_Main("Alpha区间", Range(0, 1)) = 0
        [HideInInspector]_TexAlphaBegin_Main("Alpha区间 开始", Range(0, 1)) = 0
        [HideInInspector]_TexAlphaEnd_Main("Alpha区间 结束", Range(0, 1)) = 1
        [Sub(BaseTexture)]_TexAlphaWeight_Main("Alpha权重", Float) = 1

        //遮罩
        [CustomHeader(Mask)]
        // _MaskParam: x(intensity);y(offset);w(Off/Offset/Step)
        [Main(Mask, _KEYWORD, off)] _groupTex_Mask ("遮罩", float) = 0
        [SubEnum(Mask, Default, 0, ForceToClamp, 1)]_MaskTexWrap("贴图延展模式", Float) = 0
        [Sub(Mask)] _MaskTex("Mask贴图", 2D) = "white" {}
        [Sub(Mask)] _MaskIntensity("Mask强度", Float) = 1
        [Sub(Mask)] _MaskPannerU("Mask自动偏移U", Float) = 0
        [Sub(Mask)] _MaskPannerV("Mask自动偏移V", Float) = 0
        [Sub(Mask)] _MaskOffsetU("曲线控制Linear偏移U贡献", Float) = 0
        [Sub(Mask)] _MaskOffsetV("曲线控制Linear偏移V贡献", Float) = 0
        [SubTitle(BaseTexture, ROTATE BREATH)]
        [SubToggle(Mask)]_MaskRotate("贴图旋转", float) = 0
        [ShowIf(_MaskRotate, Equal, 1)][Sub(Mask)]_MaskRotateAngle("旋转角度", Range(-180,180)) = 0
        
        [SubToggle(Mask)]_MaskBreath("贴图呼吸", float) = 0
        [ShowIf(_MaskBreath, Equal, 1)][Sub(Mask)] _MaskBreathMin("呼吸最小值", Range(0, 1)) = 0
        [ShowIf(_MaskBreath, Equal, 1)][Sub(Mask)] _MaskBreathMax("呼吸最大值", Range(0, 1)) = 1
        [ShowIf(_MaskBreath, Equal, 1)][Sub(Mask)]_MaskBreathSpeed("呼吸速度", float) = 0
        //[Sub(Tex_04)] _Tex04TurbStrength("_Tex04TurbStrength", Float) = 1

        //噪声
        [CustomHeader(Noise)]
        [Main(Noise, _KEYWORD, off)] _groupTex_Noise ("Noise", float) = 0
        [KWEnum(Noise, Turbulence, _Toggle_Turbulence, Multiply, _, Add, _)]_Tex02Type("Noise作用", float) = 0
        [SubEnum(Noise, Default, 0, ForceToClamp, 1)]_NoiseTexWrap("贴图延展模式", float) = 0
        [Sub(Noise)] _NoiseTex("Noise贴图", 2D) = "white" {}
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
        [SubTitle(Dissolution, TEXTURE SETTING)]
        [Sub(Dissolution)]_DisTex("溶解贴图", 2D) = "white" {}
        [SubEnum(Dissolution, Default, 0, ForceToClamp, 1)]_DisTexWrap("贴图延展模式", float) = 0
        [Sub(Dissolution)] _DisPannerU("溶解 Panner U", Float) = 0
        [Sub(Dissolution)] _DisPannerV("溶解 Panner V", Float) = 0
        [SubTitle(Dissolution, ALPHA SETTING)]
        [Sub(Dissolution)]_dissolution_AlphaSoftness("溶解软硬程度", Range(0, 1)) = 0
        [SubTitle(Dissolution, SIDE SETTING)]
        [Sub(Dissolution)]_dissolution_SideWidth("溶解边缘颜色宽度", Range(0, 1)) = 0
        [Sub(Dissolution)]_dissolution_SideSoftness("溶解边缘软硬", Range(0, 1)) = 0
        [Sub(Dissolution)][HDR]_dissolution_SideColor("溶解边缘颜色", Color) = (1,1,1,1)

        //高级
        [CustomHeader(Advance)]
        _SrcBlend("SrcBlend", Float) = 5
        _DstBlend("DstBlend", Float) = 10

        //模板测试
        [CustomHeader(Stencil)]
        //Com Always,始终通过模板测试
        [Sub(Stencil)]_StencilComp ("Stencil Comparison", Float) = 8
        //Ref
        [Sub(Stencil)]_Stencil ("Stencil ID", Float) = 0
        //Pass Keep，保留模板缓存的值不变
        [Sub(Stencil)]_StencilOp ("Stencil Operation", Float) = 0
        [Sub(Stencil)]_StencilWriteMask ("Stencil Write Mask", Float) = 255
        [Sub(Stencil)]_StencilReadMask ("Stencil Read Mask", Float) = 255
        [HideInInspector][Sub(Stencil)]_ColorMask ("Color Mask", Float) = 15
        [HideInInspector][Sub(Stencil)]_ClipRect ("Clip Rect", Vector) = (0,0,1,1)
        
        //SoftMask
        [CustomHeader(SoftMask)]
        [PerRendererData] _SoftMask("Mask", 2D) = "white" {}

    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        
        // 模板测试
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        ColorMask [_ColorMask]

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend [_SrcBlend][_DstBlend]
            // 全局设置
            ZWrite[_ZWrite]
            ZTest [_ZTest]
            Cull[_CullFunc]
            
            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local __ SOFTMASK_SIMPLE SOFTMASK_SLICED SOFTMASK_TILED
         //add by @horatio,support nested softmask
            #pragma multi_compile_local __ SOFTMASK_SIMPLE_PARENT SOFTMASK_SLICED_PARENT SOFTMASK_TILED_PARENT

            #pragma vertex Vert
            #pragma fragment Frag

            #include "./CommonHLSL.hlsl"
            #include "./ROOPTSubPassLoadUntils.hlsl"
            #include "./SoftMaskHLSL.hlsl"
//////////////CBUFFER////////////////////
            //CBuffer声明后允许合批SRF Batcher，所有变量都要在这里共享
            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                sampler2D _NoiseTex;
                sampler2D _MaskTex;
                sampler2D _DisTex;

                half4 _MainTex_ST;
                half4 _NoiseTex_ST;
                half4 _MaskTex_ST;
                half4 _DisTex_ST;

                half _MainColorIntensity;
                half _MainOpaIntensity;
//////////////main tex////////////////////
                half _MainTexWrap;
                half _MainTexMoveSpeedU;
                half _MainTexMoveSpeedV;
                half4 _MainTex_uv_begin_end;

                half _MainTexRotate;
                half _MainRotateAngle;
                half _MainRotateSpeed;

                half _MainTexScale;
                half _MainScaleSpeed;
                half _MainScaleMin;
                half _MainScaleMax;

                half _ColorChannel_Main;
                half _TexColorBegin_Main;
                half _TexColorEnd_Main;
                half3 _tex_main_color_1;
                half3 _tex_main_color_2;
                half _AlphaUse_Main;
                half _TexAlphaBegin_Main;
                half _TexAlphaEnd_Main;
                half _TexAlphaWeight_Main;

//////////////mask////////////////////
                half _groupTex_Mask;
                half _MaskTexWrap;
                half _MaskIntensity;
                half _MaskPannerU;
                half _MaskPannerV;
                half _MaskOffsetType;
                half _MaskOffsetU;
                half _MaskOffsetV;
                half _MaskRotate;
                half _MaskRotateAngle;
                half _MaskBreath;
                half _MaskBreathMax;
                half _MaskBreathMin;
                half _MaskBreathSpeed;

//////////////noise////////////////////
                half _groupTex_Noise;
                half _Tex02Type;
                half _NoiseIntenMain;
                half _NoiseIntenMask;
                half _NoiseIntenDis;
                half _NoisePanU;
                half _NoisePanV;
                half _NoiseTexWrap;

//////////////dissolution////////////////////
                half _groupTex_Dis;
                half _DisProcessTest;
                half _DisTexWrap;
                half _DisPannerU;
                half _DisPannerV;
                half _dissolution_AlphaSoftness;
                half3 _dissolution_SideColor;
                half _dissolution_SideWidth;
                half _dissolution_SideSoftness;

                
/////////////RectMask/////////////////////////
                float4 _ClipRect;

            CBUFFER_END

/////////////FRAMEBUFFER/////////////////////////
            RO_FRAMEBUFFER_DECLARE_INPUT
/////////////VertexInput/////////////////////////输入结构
            struct VertexInput
            {
                //输入两个UV
                half4 positionOS                : POSITION;
                half4 color                     : COLOR;
                half4 uv                        : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
/////////////VertexOutput/////////////////////////输出结构
            struct VertexOutput
            {
                half4 positionCS                : SV_POSITION;
                half4 color                     : COLOR;
                half2 uv                        : TEXCOORD0;
                half4 customData                : TEXCOORD1;//x(mask offset);y(dissolve);
                half3 positionWS                : TEXCOORD2;
                SOFTMASK_COORDS(3)
                SOFTMASK_COORDS_PARENT(4)

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

/////////////顶点着色器/////////////////////////
            VertexOutput Vert(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                //每过100s重新刷新
                float deltaTime = _Time.y % 100.0f;
                output.uv.xy = input.uv.xy;
                output.customData.xy = input.uv.zw;

                output.color = input.color;

                float3 positionOS = input.positionOS;

                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(positionOS);
                output.positionCS = vertexPositionInput.positionCS;
                float3 positionVS = vertexPositionInput.positionVS;
                output.positionWS = input.positionOS;
        
                SOFTMASK_CALCULATE_COORDS(output, input.positionOS)
                SOFTMASK_CALCULATE_COORDS_PARENT(output, input.positionOS)
            
                return output;
            }
            
            //重映射
            half Remap_Float(half x, half t1, half t2, half s1, half s2)
            {
                
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }
/////////////像素着色器/////////////////////////
            half4 Frag(VertexOutput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float deltaTime = _Time.y % 100.0f;

                half4 color = half4(0,0,0,1);
                half noise = 1;

                // uv setting begin
                // main tex uv
                float2 mainUV = input.uv.xy;
                //XY为起始UV,ZW为结束UV
                mainUV.x = Remap(mainUV.x, 0, 1, _MainTex_uv_begin_end.x, _MainTex_uv_begin_end.z);
                mainUV.y = Remap(mainUV.y, 0, 1, _MainTex_uv_begin_end.y, _MainTex_uv_begin_end.w);
                mainUV += deltaTime * half2(_MainTexMoveSpeedU, _MainTexMoveSpeedV);

                if (_MainTexScale > 0.5){
                    float2 tempUV = mainUV;
                    tempUV -= 0.5;
                    tempUV *= lerp(_MainScaleMin, _MainScaleMax, sin(deltaTime * _MainScaleSpeed) * 0.5 + 0.5);
                    mainUV = saturate(tempUV + 0.5);
                    
                }

                if (_MainTexRotate > 0.5){
                    float2 tempUV = mainUV;
                    tempUV -= 0.5;
                    float angle = PI * _MainRotateAngle / 180;
                    angle += _MainRotateSpeed * deltaTime;
                    float2 finalUV;
                    finalUV.x = tempUV.x * cos(angle) - tempUV.y * sin(angle);
                    finalUV.y = tempUV.y * cos(angle) + tempUV.x * sin(angle);
                    mainUV = saturate(finalUV + 0.5);
                }

                //mainUV += input.customData.zw;
                mainUV = TRANSFORM_TEX(mainUV, _MainTex);

                //贴图延展模式：Clamp
                if (_MainTexWrap > 0)
                {
                    mainUV = saturate(mainUV);
                }

                // mask tex uv

                float2 maskUV = TRANSFORM_TEX(input.uv.xy, _MaskTex);

                half offset = 0;
                
                offset = input.customData.x;
                maskUV.xy += deltaTime * half2(_MaskPannerU, _MaskPannerV);
                maskUV.xy += half2(_MaskOffsetU, _MaskOffsetV) * offset;

                if (_MaskRotate > 0.5){
                    float2 tempUV = maskUV;
                    tempUV -= 0.5;
                    float angle = PI * _MaskRotateAngle / 180;
                    float2 finalUV;
                    finalUV.x = tempUV.x * cos(angle) - tempUV.y * sin(angle);
                    finalUV.y = tempUV.y * cos(angle) + tempUV.x * sin(angle);
                    maskUV = finalUV + 0.5;
                }

                
                // noise tex uv
                float2 noiseUV = TRANSFORM_TEX(input.uv.xy, _NoiseTex);

                noiseUV += deltaTime * half2(_NoisePanU, _NoisePanV);

                if (_NoiseTexWrap > 0)
                {
                    noiseUV = saturate(noiseUV);
                }

                // dissolve tex uv
                float2 disUV = TRANSFORM_TEX(input.uv.xy, _DisTex);
                
                disUV += deltaTime * half2(_DisPannerU, _DisPannerV);
                if (_DisTexWrap > 0)
                {
                    disUV = saturate(disUV);
                }

                if (_groupTex_Noise > 0)
                {
                    float noiseIntensity = 1;
                    noise = tex2D(_NoiseTex, noiseUV).r * noiseIntensity;
                    if(_Tex02Type < 0.5)
                    {
                        //turbulence
                        //噪声图是加法叠加上去的
                        mainUV += noise * _NoiseIntenMain;
                        disUV += noise * _NoiseIntenDis;
                        maskUV += noise * _NoiseIntenMask;
                    }
                }
                //uv setting end

                //////////////////////////////////// Main Color Begin///////////////////////////////////////
                
                half4 mainTex = tex2D(_MainTex, mainUV);
                half3 baseCol = mainTex.rgb;
                
                half colorArea_Main = _ColorChannel_Main > 0 ? (_ColorChannel_Main > 1.5 ? baseCol.b : baseCol.g) : baseCol.r;
                half3 mainCol = 1;
                if(_ColorChannel_Main > 2.5)
                {
                    mainCol = baseCol.rgb;
                }
                else
                {
                    half3 color1 = _tex_main_color_1;
                    half3 color2 = _tex_main_color_2;
                    
                    //颜色使用通道RGB
                    colorArea_Main = saturate(Remap_Float(colorArea_Main, _TexColorBegin_Main, _TexColorEnd_Main, 0, 1));
                    mainCol = lerp(color2, color1, colorArea_Main);
                }
                
                //////////////////////////////////// Main Color End ///////////////////////////////////////

                ///////////////////////// Alpha /////////////////////////////////////////
                float mainAlpha;
                if(_AlphaUse_Main > 3.5)
                {
                    mainAlpha = 1;
                }
                else
                {
                    mainAlpha = _AlphaUse_Main > 0 ? (_AlphaUse_Main > 1.5 ? (_AlphaUse_Main > 2.5 ? mainTex.a : mainTex.b) : mainTex.g) : mainTex.r;
                    mainAlpha = saturate(Remap_Float(mainAlpha, _TexAlphaBegin_Main, _TexAlphaEnd_Main, 0, 1));
                }
                //noise作用
                if (_Tex02Type > 0.5)
                {
                    if(_Tex02Type < 1.5)
                    {
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
                    float4 maskRGBA= tex2D(_MaskTex, maskUV);
                    mainAlpha *= maskRGBA.r * maskRGBA.a;
                    
                    if (_MaskBreath > 0.5){
                        float breath = sin(deltaTime * _MaskBreathSpeed) * 0.5 + 0.5;
                        mainAlpha *= lerp(_MaskBreathMin, _MaskBreathMax, breath);
                        //mainAlpha *= breath;
                    }
                    mainAlpha = saturate(mainAlpha * _MaskIntensity);
                }

                /////////////////////////溶解/////////////////////////////////////////
                if(_groupTex_Dis > 0)
                {
                    float disProgress = (_DisProcessTest > 0) ? _DisProcessTest : input.customData.y;
                    half4 disMap = tex2D(_DisTex, disUV);
                    half disMount = disMap.r;
                    
                    // dis alpha
                    half disAlpha = saturate((disMount + ((1 - disProgress) * 2 - 1)));
                    mainAlpha *= smoothstep(_dissolution_AlphaSoftness - 0.001, 1, disAlpha);
                    // dis side color
                    float side_inv = saturate((disMount + ((1 - disProgress) * 2 - 1) - _dissolution_SideWidth));
                    //平滑插值曲线
                    float sideColArea = smoothstep(_dissolution_SideSoftness - 0.001, 1, side_inv);
                    mainCol = lerp(_dissolution_SideColor, mainCol, sideColArea);
                    // mainCol += side * 100;
                }

                color.rgb = mainCol * input.color.rgb * _MainColorIntensity;
                color.a = mainAlpha * input.color.a * _MainOpaIntensity;

                // color.rgb = input.maskPosition.xyz;
                color.a *= SOFTMASK_GET_MASK(input);
                //add by @horatio,  support nested softmask
                color.a *= SOFTMASK_GET_MASK_PARENT(input);

                #ifdef UNITY_UI_CLIP_RECT
                    float2 inside = step(_ClipRect.xy, input.positionWS.xy) * step(input.positionWS.xy, _ClipRect.zw);
                    color.a *= inside.x * inside.y;
                #endif
                
                return color;
            }

            ENDHLSL
        }
    }
    CustomEditor "BigCatEditor.LWGUI"
}
