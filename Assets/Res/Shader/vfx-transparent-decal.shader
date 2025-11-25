Shader "Effect/vfx-transparent-decal"
{
    Properties
    {
        [CustomHeader(Decal)]
        [Toggle(_Toggle_DECAL)]_Decal("开启贴花", Float) = 1.0
        [Toggle()]_RadialUV("radial uv", Float) = 0.0
        [HideInInspector]_objectScale("scale", Vector) = (1,1,1,1)
        [HideInInspector]_particleScale("particleScale", Float) = 0
        [CustomHeader(Total)]
        [Main(General, _KEYWORD, on, off)]_general("全局设置", float) = 1
        [Preset(General, LWGUI_BlendModePreset)]_BlendMode ("Blend Mode", float) = 1
        [SubToggle(General)]_ZWrite("ZWrite", Float) = 0.0
        [Sub(General)]_ZTest("ZTest", Float) = 4
        [SubEnum(General, off, 0, front, 1, back, 2)] _CullFunc("Cull", Float) = 0.0

        [CustomHeader(Texture)]
        [Main(BaseTexture, _KEYWORD, on, off)]_TextureGroup("基础贴图", float) = 1
        [Title(BaseTexture, Setting)]
        [Sub(BaseTexture)]_MainColorIntensity("总颜色强度", Range(0,10)) = 1
        [Sub(BaseTexture)]_MainOpaIntensity("总透明度", Range(0,1)) = 1

        [Sub(BaseTexture)]_MainTex("主贴图", 2D) = "white" {}
        [SubEnum(BaseTexture, Default, 0, ForceToClamp, 1)]_MainTexWrap("贴图延展模式", float) = 0
        [Title(BaseTexture, UV SETTING)]
        [Sub(BaseTexture)]_MainTexMoveSpeedU("UV Panner X", Float) = 0
        [Sub(BaseTexture)]_MainTexMoveSpeedV("UV Panner Y", Float) = 0
        [Sub(BaseTexture)]_MainTex_uv_begin_end("UV 范围 %XY为起始UV,ZW为结束UV%", Vector) = (0,0,1,1)
        [Title(BaseTexture, COLOR SETTING)]
        [KWEnum(BaseTexture, R, _Toggle_Main_R, G, _Toggle_Main_G, B, _Toggle_Main_B, RGB_3COLORBLEND, _Toggle_Main_RGB, RGB_ORIGIN, _Toggle_Main_Origin)]_ColorChannel_Main("颜色使用通道", float) = 0
        [SubToggle(BaseTexture_Toggle_Main_RGB)]_3ColorBlend_GreenMain("绿通道优先", float) = 0
        [MinMaxSlider(BaseTexture, _TexColorBegin_Main, _TexColorEnd_Main)] _TexColorInterval_Main("颜色区间", Range(0, 1)) = 0
        [HideInInspector]_TexColorBegin_Main("颜色区间 开始", Range(0, 1)) = 0
        [HideInInspector]_TexColorEnd_Main("颜色区间 结束", Range(0, 1)) = 1
        [Sub(BaseTexture)][HDR]_tex_main_color_1("颜色 1", Color) = (1,1,1,0)
        [Sub(BaseTexture)][HDR]_tex_main_color_2("颜色 2", Color) = (0,0,0,0)
        [Sub(BaseTexture_Toggle_Main_RGB)][HDR]_tex_main_color_3("颜色 3", Color) = (0,0,0,0)
        [Title(BaseTexture, ALPHA SETTING)]
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
        [Sub(Mask)] _MaskAngle("Mask旋转角度", Float) = 0
        [Sub(Mask)] _MaskIntensity("Mask Intensity", Float) = 1
        [Sub(Mask)] _MaskPannerU("Mask自动偏移U", Float) = 0
        [Sub(Mask)] _MaskPannerV("Mask自动偏移V", Float) = 0
        [KWEnum(Mask, Linear, _Toggle_LinearOffset, Step, _Toggle_StepOffset)] _MaskOffsetType("Mask曲线控制偏移方式", Float) = 0
        [Sub(Mask)] _MaskOffsetU("曲线控制偏移U贡献", Float) = 1
        [Sub(Mask)] _MaskOffsetV("曲线控制偏移V贡献", Float) = 0
        [Sub(Mask_Toggle_StepOffset)] _MaskOffsetStep("Mask Offset Step", Float) = 0
        //[Sub(Tex_04)] _Tex04TurbStrength("_Tex04TurbStrength", Float) = 1

        [CustomHeader(Noise)]
        [Main(Noise, _KEYWORD, off)] _groupTex_Noise ("Noise", float) = 0
        [KWEnum(Noise, Turbulence, _Toggle_Turbulence, Multiply, _, Add, _)]_Tex02Type("Noise作用", float) = 0
        [SubEnum(Noise, Default, 0, ForceToClamp, 1)]_NoiseTexWrap("贴图延展模式", float) = 0
        [Sub(Noise)] _NoiseTex("Noise贴图", 2D) = "white" {}
        [Sub(Mask)] _NoiseAngle("Noise旋转角度", Float) = 0
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
        [Title(Dissolution, DISOLVE SETTING)]
        [Sub(Dissolution)] _DisProcessTest("溶解进度测试", Range(0,1)) = 0
        [Sub(Dissolution_Toggle_DirectDis)] _DisTexContribution("方向性溶解 贴图贡献程度", Float) = 0
        [Sub(Dissolution_Toggle_DirectDis)] _DisDir("方向性溶解 溶解方向(局部坐标)", Vector) = (1,0,0,0)
        [Title(Dissolution, TEXTURE SETTING)]
        [Sub(Dissolution)]_DisTex("溶解贴图", 2D) = "white" {}
        [SubEnum(Dissolution, Default, 0, ForceToClamp, 1)]_DisTexWrap("贴图延展模式", float) = 0
        [Sub(Dissolution)] _DisPannerU("溶解 Panner U", Float) = 0
        [Sub(Dissolution)] _DisPannerV("溶解 Panner V", Float) = 0
        [Title(Dissolution, ALPHA SETTING)]
        [Sub(Dissolution)]_dissolution_AlphaSoftness("溶解软硬程度", Range(0, 1)) = 0
        [Title(Dissolution, SIDE SETTING)]
        [Sub(Dissolution)]_dissolution_SideWidth("溶解边缘颜色宽度", Range(0, 1)) = 0
        [Sub(Dissolution)]_dissolution_SideSoftness("溶解边缘软硬", Range(0, 1)) = 0
        [Sub(Dissolution)][HDR]_dissolution_SideColor("溶解边缘颜色", Color) = (1,1,1,1)

        //视差
        [CustomHeader(Parallax)]
        [Main(Parallax, _, off)] _gourp_parallax("视差", float) = 0
        [Sub(Parallax)]_ParallaxStrength("视差偏移量",range(0,1)) = 0.5
        [Sub(Parallax)]_Parallaxskew("_Parallaxskew",range(0,10)) = 1
        [Sub(Parallax)]_ParallaxMap("视差贴图", 2D) = "black" {}

        [CustomHeader(Advance)]
        [HideInInspector]_SrcBlend("SrcBlend", Float) = 1
        [HideInInspector]_DstBlend("DstBlend", Float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Overlay" "Queue" = "Transparent-499" "DisableBatching" = "True" }

        
        Stencil {
            Ref 5
            Comp Greater
            Pass Incrsat
            Fail Keep
        }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend[_SrcBlend] [_DstBlend]
            ZWrite[_ZWrite]
            ZTest[_ZTest]
            Cull[_CullFunc]
            
            HLSLPROGRAM
            #pragma multi_compile _ _Toggle_DECAL

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
                sampler2D _NoiseTex;
                sampler2D _NoiseMask;
                sampler2D _MaskTex;
                sampler2D _DisTex;

                half4 _MainTex_ST;
                half4 _NoiseTex_ST;
                half4 _NoiseMask_ST;
                half4 _MaskTex_ST;
                half4 _DisTex_ST;


                half _MainColorIntensity;
                half _MainOpaIntensity;

                half _RadialUV;

//////////////main tex////////////////////
                half _MainTexWrap;
                half _MainTexMoveSpeedU;
                half _MainTexMoveSpeedV;
                half4 _MainTex_uv_begin_end;
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

//////////////mask////////////////////
                half _groupTex_Mask;
                half _MaskTexWrap;
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
                half _DisProcessTest;
                half _DisTexContribution;
                half3 _DisDir;
                half _DisTexWrap;
                half _DisPannerU;
                half _DisPannerV;
                half _dissolution_AlphaSoftness;
                half3 _dissolution_SideColor;
                half _dissolution_SideWidth;
                half _dissolution_SideSoftness;

/////////////Parallax/////////////////////////
                half _gourp_parallax;
                half _ParallaxStrength;
                half _Parallaxskew;
                sampler2D _ParallaxMap;
                half4 _ParallaxMap_ST;
                sampler2D _ParallaxNormalMap;

                half _particleScale;
                half3 _objectScale;
                half3 _objectForward;
            CBUFFER_END

            RO_FRAMEBUFFER_DECLARE_INPUT
            struct VertexInput
            {
                half4 positionOS                : POSITION;
                half4 color                     : COLOR;
                half4 uv                        : TEXCOORD0;
                half4 uv1                       : TEXCOORD1;
                half4 texcoord2                 : TEXCOORD2;
                half4 texcoord3                 : TEXCOORD3;
                half3 normalOS                  : NORMAL;
                half4 tangentOS                 : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                half4 positionCS                : SV_POSITION;
                half2 uv                        : TEXCOORD0;//1u
                half4 customData                : TEXCOORD1;//x(mask offset);y(dissolve);zw(main/dissolve uv offset)   
                half4 screenPos                 : TEXCOORD2;
                half4 viewRayOS                 : TEXCOORD3;
                half4 center                    : TEXCOORD4;
                half4 size                      : TEXCOORD5;               
                half4 color                     : TEXCOORD7;
                float3x3 TBN                       : TEXCOORD8;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            

            
            float4 AdditionalData(float3 postionWS)
            {
                float4 data = half4(0.0, 0.0, 0.0, 0.0);
                float3 viewPos = TransformWorldToView(postionWS);
                data.x = length(viewPos / viewPos.z);// distance to surface
                data.y = length(GetCameraPositionWS().xyz - postionWS); // local position in camera space
                return data;
            }

            float3x3 YRotationMatrix(float degrees, float3 pivot)
            {
                float alpha = degrees * PI / 180.0;
                float s = sin(alpha);
                float c = cos(alpha);
               //But how can I insert the pivot???
                return float3x3(
                     c, 0, -s,
                     0, 1, 0,
                     s, 0, c);
            }

            VertexOutput Vert(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float deltaTime = _Time.y % 100.0f;
                output.uv.xy = input.uv.xy;
                output.customData.xy = input.uv.zw;
                output.customData.zw = input.uv1.zw;

                output.color = input.color;
                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
                float3 positionWS = vertexPositionInput.positionWS;

                output.center.xyz = input.texcoord2.xyz;
                output.size.xyz = half3(input.texcoord2.w, input.texcoord3.xy);
                output.screenPos = vertexPositionInput.positionNDC;
                float3 viewRay = vertexPositionInput.positionVS;
                output.viewRayOS.w = -viewRay.z;
                float4x4 ViewToObjectMatrix = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
                output.viewRayOS.xyz = mul((float3x3)ViewToObjectMatrix, viewRay);
                float3x3 TBN = float3x3(
                    input.tangentOS.xyz,
                    cross(input.normalOS,input.tangentOS.xyz)* input.tangentOS.w,
                    input.normalOS
                );
                output.TBN=TBN;

                output.positionCS = vertexPositionInput.positionCS;
                return output;
            }

            half Remap_Float(half x, half t1, half t2, half s1, half s2)
            {
                
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }

            //视差高度图
            float GetParallaxHeight (float2 uv)
            {
                return 1-tex2D(_ParallaxMap, uv.xy).r;
            }           
                        
            //设置ParallaxOffset（视差补偿）--之前的方法
            float2 ParallaxOffset (float2 uv, float2 viewDir)
            {
            float height = GetParallaxHeight(uv);
                // height -= 0.5;
                height *= -_ParallaxStrength;
                return viewDir * height;
            }

            float2 ParallaxRaymarching (float2 uv,float2 viewDir)
            {     float2 uvOffset = 0;
                float stepSize =0.05; //步长
                float2 uvDelta =viewDir *(stepSize*_ParallaxStrength);
                float stepHeight =1;
                float surfaceHeight =GetParallaxHeight(uv);
                // uv before
                float2 prevUVOffset = uvOffset;
                float prevStepHeight = stepHeight;
                float prevSurfaceHeight = surfaceHeight;
                for (int i =1;i<20 && stepHeight>surfaceHeight;i++)
                {
                    // uv before
                    prevUVOffset = uvOffset;
                    prevStepHeight = stepHeight;
                    prevSurfaceHeight = surfaceHeight;
                    // uv after
                    uvOffset -=uvDelta;
                    stepHeight-=stepSize;
                    surfaceHeight=GetParallaxHeight(uv+uvOffset);
                }
                float prevDifference = prevStepHeight - prevSurfaceHeight;//bef
                float difference = surfaceHeight - stepHeight;//aft
                float t = prevDifference / (prevDifference + difference);
                uvOffset = lerp(prevUVOffset, uvOffset, t);
                return uvOffset;
            }

            float3 getProjectedObjectPos(VertexOutput input, float depth){
                input.viewRayOS.xyz /= input.viewRayOS.w;
                //get depth from depth texture
                float3 worldPos = _WorldSpaceCameraPos + input.viewRayOS * depth;

                float3 objectPos = worldPos - input.center;

                float3 finalPos = objectPos;

                if (_particleScale > 0.5)
                {
                    float3 up = float3(0,1,0);
                    float3 r = -cross(_objectForward, up);
                    float3x3 rotationMatrix = 
                    float3x3(r,
                            up,
                            _objectForward);
                    
                    
                    finalPos = mul(rotationMatrix, float4(finalPos, 1)); 
                    finalPos /= _objectScale;
                }
                
                finalPos /= input.size.xyz;

                return finalPos;
            }

            RO_TRANSPARENT_PIXEL_SHADER_FUNCTION(Frag, VertexOutput input)
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float deltaTime = _Time.y % 100.0f;

                half4 color = half4(0,0,0,1);
                half noise = 1;


                RO_TRANSPARENT_PIXEL_INPUT;
                float2 screenSpaceUV = input.positionCS.xy;
                float rawD = GET_SUBPASS_LOAD_DEPTH(screenSpaceUV);
                float depth = LinearEyeDepth(rawD.r, _ZBufferParams);
                float3 decalSpaceScenePos = getProjectedObjectPos(input, depth);
                
                /// begin decal uv
                clip(0.5 - abs(decalSpaceScenePos));
                float2 decalSpaceUV = decalSpaceScenePos.xz + 0.5;
                if(_RadialUV > 0.5)
                {
                    float2 radialuv;
                    radialuv.y = length(decalSpaceUV - 0.5);
                    decalSpaceUV -= 0.5;
                    radialuv.x = frac(atan2(decalSpaceUV.x, decalSpaceUV.y)/(2 * PI) + 0.5).r;
                    input.uv = radialuv;
                }
                else
                {
                    input.uv = decalSpaceUV;
                }
                float decalEdgeY = pow(1-abs(decalSpaceScenePos.y) * 2, 1);
                
                float decalEdge = decalEdgeY;
                /// end decal uv

                
                //uv start
                float2 mainUV = input.uv.xy;
                mainUV.x = saturate(Remap(mainUV.x, 0, 1, _MainTex_uv_begin_end.x, _MainTex_uv_begin_end.z));
                mainUV.y = saturate(Remap(mainUV.y, 0, 1, _MainTex_uv_begin_end.y, _MainTex_uv_begin_end.w));
                mainUV = TRANSFORM_TEX(mainUV, _MainTex);
                mainUV += deltaTime * half2(_MainTexMoveSpeedU, _MainTexMoveSpeedV);
                mainUV += input.customData.zw;

                if (_MainTexWrap > 0)
                {
                    mainUV = saturate(mainUV);
                }
                // RO_TRANSPARENT_PIXEL_OUTPUT(float4(decalSpaceScenePos.xz, 0, 1))  

                // begin parallax 
                if(_gourp_parallax > 0.5)
                {
                    float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;

                    input.viewRayOS.xyz /= input.viewRayOS.w;
                    float3 p = -input.viewRayOS * depth;
                    // RO_TRANSPARENT_PIXEL_OUTPUT(float4(p, 1))
                    float3 TangentVS = float3(p.xz, p.y);
                    TangentVS = normalize(TangentVS);
                    TangentVS.xy /= (TangentVS.z+_Parallaxskew);
                    
                    half3 VdirTangentSpace = TangentVS;
                    VdirTangentSpace = normalize(VdirTangentSpace);

                    float2 uvOffset = ParallaxRaymarching(mainUV,VdirTangentSpace);
                    mainUV.xy +=uvOffset;
                }
                // end parallax 

                float2 maskUV = input.uv.xy;
                maskUV = TRANSFORM_TEX(maskUV, _MaskTex);
                float2 tmpMaskUV = maskUV;
                tmpMaskUV -= float2(0.5,0.5);
				float2 finalMaskUV = 0;
				finalMaskUV.x = tmpMaskUV.x*cos(_MaskAngle) - tmpMaskUV.y*sin(_MaskAngle);//旋转x
				finalMaskUV.y = tmpMaskUV.x*sin(_MaskAngle) + tmpMaskUV.y*cos(_MaskAngle);//旋转y
				finalMaskUV += float2(0.5,0.5);
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

                half2 noiseUV = TRANSFORM_TEX(input.uv.xy, _NoiseTex);
                float2 tmpNoiseUV = noiseUV;
                tmpNoiseUV -= float2(0.5,0.5);
				float2 finalNoiseUV = 0;
				finalNoiseUV.x = tmpNoiseUV.x*cos(_NoiseAngle) - tmpNoiseUV.y*sin(_NoiseAngle);//旋转x
				finalNoiseUV.y = tmpNoiseUV.x*sin(_NoiseAngle) + tmpNoiseUV.y*cos(_NoiseAngle);//旋转y
				finalNoiseUV += float2(0.5,0.5);
                noiseUV = finalNoiseUV;
                noiseUV += deltaTime * half2(_NoisePanU, _NoisePanV);
                if (_NoiseTexWrap > 0)
                {
                    noiseUV = saturate(noiseUV);
                }

                float2 disUV = TRANSFORM_TEX(input.uv.xy, _DisTex);
                disUV += deltaTime * half2(_DisPannerU, _DisPannerV);
                if (_DisTexWrap > 0)
                {
                    disUV = saturate(disUV);
                }

                //uv end        
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
                half4 mainTex = tex2D(_MainTex, mainUV);

                //////////////////////////////////// Main Color Begin///////////////////////////////////////
                half colorArea_Main = _ColorChannel_Main > 0 ? (_ColorChannel_Main > 1.5 ? mainTex.b : mainTex.g) : mainTex.r;
                half3 mainCol = 1;
                if(_ColorChannel_Main > 3.5)
                {
                    mainCol = mainTex.rgb;
                }
                else
                {
                    half3 color1 = _tex_main_color_1;
                    half3 color2 = _tex_main_color_2;
                    half3 color3 = _tex_main_color_3;
                    

                    if(_ColorChannel_Main > 2.5)
                    {
                        if(_3ColorBlend_GreenMain > 0)
                        {
                            mainCol = lerp(lerp(color3 * mainTex.b, color1, mainTex.r), color2, mainTex.g);
                        }
                        else
                        {
                            mainCol = lerp(lerp(color3 * mainTex.b, color2, mainTex.g), color1, mainTex.r);
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
                    mainAlpha = saturate(Remap_Float(mainAlpha, _TexAlphaBegin_Main, _TexAlphaEnd_Main, 0, 1));
                }

                if (_groupTex_Noise > 0)
                {
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
                }

                if(_groupTex_Mask > 0)
                {
                    if (_MaskTexWrap > 0)
                    {
                        maskUV = saturate(maskUV);
                    }
                    mainAlpha *= tex2D(_MaskTex, maskUV).r * _MaskIntensity;
                }

            /////////////////////////溶解/////////////////////////////////////////
                if(_groupTex_Dis > 0)
                {
                    half4 disMap = tex2D(_DisTex, TRANSFORM_TEX(disUV, _DisTex));
                    half disMount = disMap.r;
                    float disProgress = (_DisProcessTest > 0)? _DisProcessTest : input.customData.y;
                    
                    half disAlpha = saturate((disMount + ((1 - disProgress) * 2 - 1)));
                    float side_inv = saturate((disMount + ((1 - disProgress - _dissolution_SideWidth) * 2 - 1)));

                    mainAlpha *= smoothstep(_dissolution_AlphaSoftness - 0.001, 1, disAlpha);

                    float sideColArea = smoothstep(_dissolution_SideSoftness - 0.001, 1, side_inv);

                    mainCol = lerp(_dissolution_SideColor, mainCol, sideColArea);
                    // mainCol += side * 100;
                }

                mainAlpha *= decalEdge;

                color.rgb = mainCol * input.color.rgb * _MainColorIntensity;
                color.a = mainAlpha * input.color.a * _MainOpaIntensity;


                RO_TRANSPARENT_PIXEL_OUTPUT(color)
            }


            ENDHLSL
        }
    }
    CustomEditor "BigCatEditor.LWGUI"
}
