Shader "Custom/Cartoon-Lit-Avatar_ROTemp"
{
    Properties
    {
        [CustomHeader(BaseTexture)]
        _BaseMap("BaseMap", 2D) = "white" {}
        [Enum(Transparency, 0, Emission, 1, None, 2)] _BaseAlphaType ("Base Alpha Type", Float) = 2
        _BaseColorTint("BaseColorTint", Color) = (1,1,1,1)
        _EmissionIntensity ("Emission Intensity", Float) = 1
        [Toggle]_EnableColorGrade("_EnableColorGrade", Float) = 1
        _HighColor("HighColor", Color)	 = (1,1,1,0)				//MaskColor
		_LowColor("LowColor", Color) = (0,0,1,0)
		_ColorControl("ColorControl", Vector) = (0.899, 0.713, 0.649, 0.32)

        [CustomHeader(Shadow)]
        _RampTex("RampMap 建议明暗交接线从0.9开始，RampRangeMax为0.55", 2D) = "white" {}
        _RampCount("Ramp Count", Range(1, 16)) = 8
        [MinMaxSlider(_RampRangeMin, _RampRangeMax)] _RampRange("Ramp Range", Range(0, 1)) = 0
        [HideInInspector] _RampRangeMin("Ramp Range Min", Range(0, 1)) = 0
        [HideInInspector] _RampRangeMax("Ramp Range Max", Range(0, 1)) = 0.55
        _RampReflectionRange("RefRange反弹光范围，控制AO处无反弹", Range(0, 1)) = 0.3

        [CustomHeader(LightMap)]
        [Toggle(_UseLightMap)] _UseLightMap ("Use Light Map", Float) = 1
        _LightMap("LightMap R:光滑度(0.95有Matcap)|G:AO(0.5以上不影响ramp)|B:Spec强度|A:RampID", 2D) = "black" {}

        [CustomHeader(Specular)]
        _SpecularPow ("Specular Power ", Range(1,20)) = 4
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)

        [CustomHeader(Metal)]
        _MetalTex("MetalTex", 2D) = "grey" {}
        _MetalIntensity("MetalIntensity", Range(0,1)) = 1

        [CustomHeader(RimLight)]
        _RimOffset("边缘光检测偏移量", Range(0,1)) = 0.1
        _RimStep("边缘光阈值", Range(0,1)) = 0.5
        _RimColor("边缘光颜色", Color) = (1,1,1,1)
        _RimIntensity("边缘光强度", Range(0,1)) = 0.15

        [CustomHeader(Outline)]
        [Enum(None, 0, Normal, 1, Tangent, 2)] _OutlineType ("Outline Type", Float) = 2
        _OutlineMap("Outline Map", 2D) = "white" {}
        _OutlineThickness("Outline Thickness", Range(0, 0.05)) = 0.01
        _OutlineColor("Outline Color", Color) = (1, 1, 1, 1)

        [CustomHeader(Debug)]
        [KeywordEnum(Off, Base, Ramp, SceneGI, Specular, Matcap, Normal, AO, ID, Rim)] _Debug ("Debug mode", Float) = 0
        _DebugIDNum("Debug ID Number", Range(0, 15)) = 0

        [CustomHeader(HitFX)]
        _HitStartTime("hitStartTime", Float) = 0
        _HitFxIntensity("HitFx Intensity", Range(0,1)) = 0
        [HDR]_HitFXColor ("HitFX Color", Color) = (1,1,1,0.2)
        _HitFXRimPow ("HitFX Rim Power ", Range(1,20)) = 4
        _HitFXRimStrength ("HitFX Rim Strength", Range(0, 3)) = 0.5

        [CustomHeader(Blend)]
        [HideInInspector] _Cull("_Cull", Float) = 2.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("_SrcBlend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("_DstBlend", Float) = 0.0
        [HideInInspector]_ZWrite("_ZWrite", Float) = 1.0

        [CustomHeader(VFX)]
        [Toggle(_VFX_DISSOLVE)]_dissolveToggle("溶解特效", float) = 0
        // _DissolveDuration("溶解时长", Float) = 1
        _DissolveStartTime("溶解开始时间", Float) = 0
        _DissolveFactorTest("Dissolve Factor Test", Range(0,1)) = 0
        _DissolveColor("Dissolve Color", Color) = (0,0,0,0)
        [HDR]_DissolveEdgeColor("Dissolve Edge Color", Color) = (1,1,1,1)
        _DissolveMap("DissolveMap", 2D) = "white"{}
        _DissolveEdgeWidth("DissolveEdgeWidth", Range(0,1)) = 0.3

        _UIColorMask("_UIColorMask", Float) = 1

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
        #include "./CommonHLSL.hlsl"
        #include "./ShadowProb.hlsl"
        #include "./ROOPTSubPassLoadUntils.hlsl"
       
        ENDHLSL


        
        Pass
        {
            Name "OutLine"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            
            cull front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD
            #pragma multi_compile _ _VFX_DISSOLVE

            float _OutLine;
            TEXTURE2D(_OutlineMap);
            SAMPLER(sampler_OutlineMap);
            half4 _OutlineColor;
            float  _OutlineThickness;
            float _OutlineType;
            float _HitFxIntensity;
            float _HitStartTime;
            float4 _HitFXColor;
            float4 _AvatarLightDir;
            float4 _AvatarLightColor;
            half _EnableColorGrade;
            half4 _HighColor;
            half4 _LowColor;
            half4 _ColorControl;

            float4 GetNewClipPosWithZOffset(float4 originalPositionCS, float viewSpaceZOffsetAmount)
            {
                if(unity_OrthoParams.w == 0)
                {
                    ////////////////////////////////
                    //Perspective camera case
                    ////////////////////////////////
                    float2 ProjM_ZRow_ZW = UNITY_MATRIX_P[2].zw;
                    float modifiedPositionVS_Z = -originalPositionCS.w + -viewSpaceZOffsetAmount; // push imaginary vertex
                    float modifiedPositionCS_Z = modifiedPositionVS_Z * ProjM_ZRow_ZW[0] + ProjM_ZRow_ZW[1];
                    originalPositionCS.z = modifiedPositionCS_Z * originalPositionCS.w / (-modifiedPositionVS_Z); // overwrite positionCS.z
                    return originalPositionCS;    
                }
                else
                {
                    ////////////////////////////////
                    //Orthographic camera case
                    ////////////////////////////////
                    originalPositionCS.z += -viewSpaceZOffsetAmount / _ProjectionParams.z; // push imaginary vertex and overwrite positionCS.z
                    return originalPositionCS;
                }
            }
            
            float GetCameraFOV()
            {
                float t = unity_CameraProjection._m11;
                float Rad2Deg = 180 / 3.1415;
                float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
                return fov;
            }

            float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
            {
                float cameraMulFix;
                if (unity_OrthoParams.w == 0)
                {
                    cameraMulFix = abs(positionVS_Z);
                    cameraMulFix = saturate(cameraMulFix);
                    cameraMulFix *= GetCameraFOV();
                }
                else
                {
                    float orthoSize = abs(unity_OrthoParams.y);
                    orthoSize = saturate(orthoSize);
                    cameraMulFix = orthoSize * 50;
                }

                return cameraMulFix * 0.0001;
            }

            half3 colorGradeOutline(half3 diffColor, half4 highColor, half4 lowColor, half4 Control)
            {
                half isGrade = step(diffColor.b, 0);
                half3 Color = diffColor;
                if (isGrade)
                {
                    half4 Colorlow = lowColor * Control.w;
                    half4 Colorhigh = highColor * 1.3;

                    half4 highRange = lerp(Colorlow , Colorhigh, (diffColor.x - Control.y) / (Control.x - Control.y));
                    //Color = lerp(Colorlow, lowColor, (-Control.w + diffColor.x) / (-Control.w + Control.z));

                    //Color = Control.w < diffColor.x ? Color : Colorlow;
                    //Color = Control.z < diffColor.x ? lowColor : Color;
                    Color = Control.y < diffColor.x ? highRange.rgb : Colorlow.rgb;
                    Color = Control.x < diffColor.x ? Colorhigh.rgb : Color;

                    Color = lerp(diffColor.rrr, diffColor.rrr * Color, Control.z)*0.75;
                    //Color = highRange;
                }

                return Color;
            }


            struct a2v
            {   
                float3 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                half4 vertexColor   : COLOR0;
            };

            struct v2f{
                float4 positionCS   :SV_POSITION;
                float2 uv           :TEXCOORD0;
                float3 normalWS     :TEXCOORD1;
                float3 color     :COLOR0;
                half  screendepth               : TEXCOORD2;
            };
            
            v2f vert(a2v input)
            {
                v2f output;

                output.uv = input.uv;

                VertexPositionInputs PositionInputs = GetVertexPositionInputs(input.positionOS);
                half4 outline = SAMPLE_TEXTURE2D_LOD(_OutlineMap, sampler_OutlineMap, input.uv.xy, 0);
                float3 positionWS = PositionInputs.positionWS;
                float3 positionVS = PositionInputs.positionVS;
                float dist = distance(_WorldSpaceCameraPos, positionWS)/unity_CameraProjection._m11;
                dist = clamp(dist, 0.2, 1);
                float outlineExpandAmount = outline.a * _OutlineThickness * dist;//* GetOutlineCameraFovAndDistanceFixMultiplier(positionVS.z);

                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float3 normalWS = vertexNormalInput.normalWS;
                if(_OutlineType == 2)
                {
                    output.normalWS = vertexNormalInput.tangentWS;
                }
                else
                {
                    output.normalWS = vertexNormalInput.normalWS;
                }
                output.normalWS = normalize(output.normalWS);

                
                // positionWS += output.normalWS * outlineExpandAmount;
                output.positionCS = TransformWorldToHClip(positionWS + output.normalWS * outlineExpandAmount);

                output.color = outline.rgb;

                output.screendepth = output.positionCS.z/output.positionCS.w;

                
                #ifdef _VFX_DISSOLVE
                    output.positionCS = 0;
                #endif

                return output;
            }


            // half4 frag(v2f input):SV_Target
            RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f input)
            {
                half4 result = 1;
                result.rgb = _OutlineColor.rgb * input.color;
                if(_EnableColorGrade > 0.5)
                {
                    result.rgb = colorGradeOutline(result.rgb, _HighColor, _LowColor, _ColorControl);
                }


                float _HitFactor = (_HitFxIntensity > 0.01) ? _HitFxIntensity : saturate((_Time.y - _HitStartTime)/(0.2));
                result.rgb = lerp(result.rgb, _HitFXColor.rgb, (1-_HitFactor));
                result.rgb *= lerp(1, _AvatarLightColor.rgb, _AvatarLightDir.w);
                

                return SubPassOutputColor(result, input.screendepth);
            }

            ENDHLSL
        }

        Pass
        {
            
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite on
            ZTest on
            cull off
            Blend[_SrcBlend][_DstBlend]
        
            HLSLPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ _VFX_DISSOLVE
                
            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD

            #pragma shader_feature _DEBUG_OFF _DEBUG_BASE _DEBUG_RAMP _DEBUG_SCENEGI _DEBUG_SPECULAR _DEBUG_MATCAP _DEBUG_NORMAL _DEBUG_AO _DEBUG_ID _DEBUG_RIM

            // #define RampCount 5
            #define _AmbientRange 0.8
            #define _AmbientSmooth 0.1
            #define _AmbientStrength 0.2
            #define _AmbientStrengthInShadow 1
            #define _RampStrengthInShadow 0.6

            CBUFFER_START(UnityPerMaterial)
            half _EnableColorGrade;
            half4 _HighColor;
            half4 _LowColor;
            half4 _ColorControl;


            half _BaseAlphaType;

            float4 _AvatarLightDir;
            float4 _AvatarLightColor;
            float4 _AmbientLightColor;
            float _EmissionIntensity;

            float4 _BaseColorTint;
            float4 _BaseMap_ST;
            float4 _LightMap_ST;
            float4 _MetalTex_ST;

            float _SpecularPow;
            float4 _SpecularColor;

            float _MetalIntensity;

            float _HitFxIntensity;
            float4 _HitFXColor;
            float _HitFXRimPow;
            float _HitFXRimStrength;

            half _RampRangeMin;
            half _RampRangeMax;

            half _RimOffset;
            half _RimStep;
            half4 _RimColor;
            half _RimIntensity;

            half _UseLightMap;
            half _RampCount;

#ifdef _VFX_DISSOLVE
            half _DissolveFactorTest;
            half _DissolveEdgeWidth;
            sampler2D _DissolveMap;
            half4 _DissolveMap_ST;
            half3 _DissolveEdgeColor;
            half3 _DissolveColor;
            half _DissolveDuration;
            half _DissolveStartTime;
#endif
            half _HitStartTime;
            
            CBUFFER_END

            half _RampReflectionRange;

            half _DebugIDNum;

            struct AvatarLightInfo
            {
                float3 lightDir;
                half3 lightCol;
                half3 darkCol;
                half inShadow;
            };

            half3 _LightInShadow;
            half3 _LightOutShadow;
            half3 _DarkInShadow;
            half3 _DarkOutShadow;

            half _UIColorMask;

            AvatarLightInfo InitLightInfo(float3 positionWS)
            {
                AvatarLightInfo info;
                if(_AvatarLightDir.w == 0){
                    Light mainLight = GetMainLight();
                    info.lightDir = mainLight.direction;
                    info.lightCol = 1;
                    info.darkCol = 0.5;
                    info.inShadow = 0;
                    //no avatar light controller
                }
                else if(_AvatarLightDir.w == 1){
                    //default avatar light controller
                    info.lightDir = _AvatarLightDir.xyz;
                    info.lightCol = _AvatarLightColor.rgb;
                    info.darkCol = _AmbientLightColor.rgb;
                    info.inShadow = 1 - _AvatarLightColor.a;
                }
                else if(_AvatarLightDir.w == 2){
                    //shadow prob volume
                    info.lightDir = _AvatarLightDir.xyz;
                    info.inShadow = 1 - SampleShadowProb(positionWS);
                    info.lightCol = lerp(_LightOutShadow, _LightInShadow, info.inShadow);
                    info.darkCol = lerp(_DarkOutShadow, _DarkInShadow, info.inShadow);
                }
                return info;
            }

            struct Attributes
            {
                float4 positionOS   : POSITION;
                half2  uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS   : TANGENT;
                float4 vertexColor  : COLOR0;
            };

            struct Varings {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS      : TEXCOORD1;
                float3 viewDir       : TEXCOORD2;
                float3 positionWS   : TEXCOORD3;
                float3 smoothNormal : TEXCOORD4;
                float4 positionNDC  : TEXCOORD5;
                float3 positionVS   : TEXCOORD6;
                float4 vertexColor  : COLOR0;
                half  screendepth               : TEXCOORD7;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);
            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);
            TEXTURE2D(_MetalTex);
            SAMPLER(sampler_MetalTex);

            Varings vert(Attributes IN)
            {
                Varings o;
                VertexPositionInputs PositionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                float3 positionWS = PositionInputs.positionWS;
                o.positionCS = PositionInputs.positionCS;
                o.positionVS = PositionInputs.positionVS;
                o.positionNDC = PositionInputs.positionNDC;
                o.uv.xy = TRANSFORM_TEX(IN.uv,_BaseMap);

                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                o.normalWS = vertexNormalInput.normalWS;
                o.smoothNormal = vertexNormalInput.tangentWS;

                o.viewDir = normalize(_WorldSpaceCameraPos - positionWS);
                o.positionWS = positionWS;
                o.vertexColor = IN.vertexColor;

                o.screendepth = o.positionCS.z/o.positionCS.w;
                return o;
            }

            half3 colorGradeOutline(half3 diffColor, half4 highColor, half4 lowColor, half4 Control)
            {
                half isGrade = step(diffColor.b, 0);
                half3 Color = diffColor;
                if (isGrade)
                {
                    half4 Colorlow = lowColor * Control.w;
                    half4 Colorhigh = highColor * 1.3;

                    half4 highRange = lerp(Colorlow , Colorhigh, (diffColor.x - Control.y) / (Control.x - Control.y));
                    //Color = lerp(Colorlow, lowColor, (-Control.w + diffColor.x) / (-Control.w + Control.z));

                    //Color = Control.w < diffColor.x ? Color : Colorlow;
                    //Color = Control.z < diffColor.x ? lowColor : Color;
                    Color = Control.y < diffColor.x ? highRange.rgb : Colorlow.rgb;
                    Color = Control.x < diffColor.x ? Colorhigh.rgb : Color;

                    Color = lerp(diffColor.rrr, diffColor.rrr * Color, Control.z)*0.75;
                    //Color = highRange;
                }

                return Color;
            }

            float3 NPR_Base_Ramp(float lambertRampAO, float rampID)
            {
                float rampSampler = 1-rampID - 0.5/_RampCount;
                return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(lambertRampAO, rampSampler)).rgb;
            }


            half3 NPR_Base_Specular(half NdotL,half NdotH, half3 normalWS,half3 baseColor,half4 parameter)
            {
                half  SpecularPow = max(parameter.r, 0.01) * _SpecularPow;
                half3 SpecularColor = _SpecularColor * parameter.b;
                half SpecularContrib = saturate(pow(NdotH, SpecularPow));
                half SpecularAO = saturate(parameter.g - 0.5);
            
                return SpecularColor * ((SpecularContrib * saturate(NdotL) * SpecularAO));
            }

            half2 AdjustMatcapUV(half3 viewDir, half3 normalWS)
            {
                //补偿 world To view 校正
                half3 viewAmendment = mul(UNITY_MATRIX_V, half4(viewDir, 0)).xyz+ half3(0,0,1) ;
                half3 viewNm = mul(UNITY_MATRIX_V, half4(normalWS, 0)).xyz ;
                //向量混合
                half3 viewblend = viewAmendment* dot(viewAmendment, viewNm)/viewAmendment.z - viewNm ;
                // float2 MetalDir = normalize(mul(UNITY_MATRIX_V,normalWS)) * 0.5 + 0.5;
                half2 MetalDir = viewblend.xy*-0.5+0.5;
                return MetalDir;
            }

            half3 NPR_Base_Matcap(half3 MetalTex, half3 Diffuse, half3 lightCol, half4 parameter)
            {
                half3 MetalLight = lerp(Diffuse, lightCol, saturate(MetalTex * 2 - 1));
                half3 MetalDark = lerp(0, Diffuse, saturate(MetalTex * 2));
                half3 MetalFinal = lerp(MetalDark, MetalLight, step(0.5,MetalTex));
                half MatcapAO = saturate(parameter.g - 0.5);
                half MetalStrength = step(0.95, parameter.r) * _MetalIntensity * MatcapAO;
                return lerp( Diffuse, MetalFinal, MetalStrength);
            }


            RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, Varings input)
            {
                AvatarLightInfo lightInfo = InitLightInfo(input.positionWS);
                float rampStrength = lerp(1, _RampStrengthInShadow, lightInfo.inShadow);

                float3 normalWS = input.normalWS;
            
                float3 lightDir = normalize(lightInfo.lightDir); //主光源方向
                float3 viewDir = input.viewDir;
                float3 halfDir = normalize(lightDir + viewDir);

                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
                if(_EnableColorGrade > 0.5)
                {
                    baseColor.rgb = colorGradeOutline(baseColor.rgb, _HighColor, _LowColor, _ColorControl);
                }
                baseColor.rgb *= _BaseColorTint;
                
                half4 LightMap = half4(0,1,0,1);
                if(_UseLightMap == 1)
                {
                    LightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv.xy);
                }
                

                float NdotL = dot(normalWS, lightDir);
                float NdotH = max(0, dot(normalWS, halfDir));
                float NdotV = max(0, dot(normalWS, viewDir));

                float lambert = NdotL;
                half halfLambert = lambert * 0.5 + 0.5;
                half AO = saturate(LightMap.g * 2);
                half rampMax = _RampRangeMax + (1.2-_RampRangeMax)*(1 - AO);
                float shadowMinMax = 1.0 / (rampMax - _RampRangeMin);
                float rampArea = (halfLambert * shadowMinMax - _RampRangeMin * shadowMinMax);

                half lambertRampAO = saturate(rampArea);

                half lambertRampAOStepRef = lerp(lambertRampAO * (1 - _RampReflectionRange) + _RampReflectionRange, lambertRampAO, saturate(AO*2));
                float3 RampColor = NPR_Base_Ramp(lambertRampAOStepRef, LightMap.a);
                half ambientStr = lerp(_AmbientStrength, _AmbientStrengthInShadow, lightInfo.inShadow);
                half ambient = smoothstep(_AmbientRange + _AmbientSmooth + 0.001, _AmbientRange, lambertRampAO) * ambientStr;

                half3 lightCol = lerp(lightInfo.lightCol, lightInfo.darkCol, ambient);
                RampColor = lerp(1, RampColor, rampStrength);

                half3 Diffuse;

                float4 FinalColor = 1;
                float3 Specular = 0;
                half3 MetalTex = 0;

                Diffuse = RampColor * baseColor.rgb * lightCol;

                Specular = NPR_Base_Specular(NdotL,NdotH,normalWS,baseColor,LightMap) * lightCol;
                    
                half2 MetalDir = AdjustMatcapUV(viewDir, normalWS);
                MetalTex = SAMPLE_TEXTURE2D(_MetalTex, sampler_MetalTex, MetalDir.xy).rgb;
                Diffuse = NPR_Base_Matcap(MetalTex, Diffuse, lightCol, LightMap);

                FinalColor.rgb = Diffuse + Specular;

                //RimLightStart
                float rimOffset = _RimOffset * 0.06;
                float VdotL = max(0, dot(float3(lightDir.x, 0, lightDir.z), viewDir));
                float3 nDirVS = normalize(TransformWorldToViewDir(normalWS,true)) * (1-VdotL);
                nDirVS.y = 0;

                float4 scrPos = input.positionNDC;
                float2 screenPos = scrPos.xy / scrPos.w;
                // Cannot preview _CameraDepthTexture in edit mode, sample texture instead of posNDC.z/posNDS.w
                float trueDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos);
                float linearEyeTrueDepth = LinearEyeDepth(trueDepth,_ZBufferParams);

                float3 offsetPosVS = float3(input.positionVS.xy + nDirVS.xy * saturate(linearEyeTrueDepth) * rimOffset, input.positionVS.z);
                float4 offsetPosCS = TransformWViewToHClip(offsetPosVS);
                float4 offsetPosVP = ComputeScreenPos(offsetPosCS) / scrPos.w;
                float offsetDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, offsetPosVP);

                float linearEyeOffectDepth = LinearEyeDepth(offsetDepth,_ZBufferParams);
                float depthDiffer = linearEyeOffectDepth - linearEyeTrueDepth;
                float rimIntensity = smoothstep(0.0,_RimStep,saturate(depthDiffer))*_RimIntensity * (lambertRampAO > 0.9 ? 1 : 0.5);
                //RimLightEnd
                half3 Rim = lightCol * _RimColor * rimIntensity;

                FinalColor.rgb += Rim;

                float _HitFactor = (_HitFxIntensity > 0.01) ? _HitFxIntensity : saturate((_Time.y - _HitStartTime)/(0.2));
                float fresnel = 1-saturate(dot(normalWS, viewDir));
                fresnel = pow(fresnel,_HitFXRimPow);
                float hitStrength = saturate(fresnel * _HitFXRimStrength + _HitFXColor.a);
                FinalColor.rgb = lerp(FinalColor.rgb, _HitFXColor.rgb, hitStrength * (1-_HitFactor));

                if(_BaseAlphaType == 0)
                    FinalColor.a = baseColor.a * _BaseColorTint.a;
                else if(_BaseAlphaType == 1){
                    FinalColor.rgb = lerp(FinalColor.rgb, baseColor.rgb * _EmissionIntensity, baseColor.a);
                }

                FinalColor.rgb *= _UIColorMask;

                #if defined(_DEBUG_BASE)
                    FinalColor.rgb = baseColor.rgb;
                #elif defined(_DEBUG_RAMP)
                    FinalColor.rgb = RampColor;
                #elif defined(_DEBUG_SCENEGI)
                    FinalColor.rgb = lightCol;
                #elif defined(_DEBUG_SPECULAR)
                    FinalColor.rgb = Specular;
                #elif defined(_DEBUG_MATCAP)
                    FinalColor.rgb = MetalTex;
                #elif defined(_DEBUG_NORMAL)
                    FinalColor.rgb = normalWS * 0.5 + 0.5;
                #elif defined(_DEBUG_AO)
                    FinalColor.rgb = LightMap.g;
                #elif defined(_DEBUG_ID)
                    half debugStep = 0.1 / _RampCount;
                    half debugId = saturate(1 - abs(_DebugIDNum / _RampCount - LightMap.a));
                    debugId = pow(debugId, 30);
                    // debugId = step(0.9, debugId);
                    FinalColor.rgb = debugId;
                #elif defined(_DEBUG_RIM)
                    FinalColor.rgb = Rim;
                #endif


#ifdef _VFX_DISSOLVE
                half2 dissolveUV = TRANSFORM_TEX(input.uv.xy, _DissolveMap);
                half dissolveVal = tex2D(_DissolveMap, dissolveUV).r;

                float DissolveFactor = (_DissolveFactorTest > 0.01) ? _DissolveFactorTest : saturate((_Time.y - _DissolveStartTime)/(_DissolveDuration));
                
                if(dissolveVal < DissolveFactor)
                {
                    discard;
                }
                
                float EdgeFactor = saturate((dissolveVal - DissolveFactor)/(_DissolveEdgeWidth * DissolveFactor));

                // FinalColor.rgb = DissolveFactor;


                FinalColor.rgb = lerp(FinalColor  * (1 - 5*DissolveFactor), _DissolveEdgeColor * FinalColor, 1 - EdgeFactor);
#endif

                return SubPassOutputColor(FinalColor, input.screendepth);
            }

            ENDHLSL

        }  

        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
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

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
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
            #include "./CommonHLSL.hlsl"
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct v2f {
                float4 vertex : SV_POSITION;
            };
            float3 _LightDirection;
            v2f vert(a2v v)
            {
                v2f o = (v2f)0;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                half3 normalWS = TransformObjectToWorldNormal(v.normal);
                worldPos = ApplyShadowBias(worldPos, normalWS, _LightDirection);
                o.vertex = TransformWorldToHClip(worldPos);
                return o;
            }
            real4 frag(v2f i) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

    }

    CustomEditor "BigCatEditor.LWGUI"
}
