Shader "RO/SceneObject/SimpleTree_LOD"
{
    Properties
	{
        _MainTex ("Leaf(R) Specular(G) Alpha(B) Branch(A) _Main", 2D) = "white" { }

        _CutOffset ("Cutoff Offset _AlphaTest", Range(1, 10)) = 1
        _NormalFadeOffset ("Normal Fade Offset", Range(0, 1)) = 0.2
        [Header(Base Color)]
		[Space(5)]
        [NoScaleOffset]_RampTex ("_Ramp", 2D) = "white" { }
        [HDR]_RimColor ("Detail Color", Color) = (0,0,0,1)
        _Ramp_ID ("Ramp_ID", Range(0.01, 0.99)) = 0.01
        [Header(Back Lit Color)]
		[Space(5)]
        _LTLambert ("Lambert _LT", Range(0, 1)) = 0.5
        _LTPower ("Power _LT", Range(0, 5)) = 1.2
        _LTScale ("Scale _LT", Range(0, 0.5)) = 0.01
        _RimIntensity ("Rim Intensity", Range(0, 5)) = 0
        _RimRange("Rim Range", Float) = 1
        _RimSmooth("Rim Smooth", Float) = 0.3
        [Header(Lightmap)]
        [Space(5)]
        _PreBakeLightmap ("Lightmap", 2D) = "white" { }
        _ShadowStrength ("Shadow Mask Strength", Float) = 1
        _BakeNormalLambert ("Bake Normal Lambert", Range(0, 1)) = 0.05

        [KeywordEnum(Off, SkyLight)] _Debug ("Debug mode", Float) = 0

        //BRG ShadowMask
        [HideInInspector]_CrossFadeSign("CrossFadeSign", Float) = 1
        [HideInInspector]_TreeLightProbeTex("TreeLightProbeTex", 3D) = "white" { }
        [HideInInspector]_TreeLightProbeST("TreeLightProbeST", Vector) = (0, 0, 0, 0)
        [HideInInspector]_TreeBoundsMax("TreeBoundsMax", Vector) = (0, 0, 0, 0)
        [HideInInspector]_TreeBoundsMin("TreeBoundsMin", Vector) = (0, 0, 0, 0)
    }

        SubShader
        {

            Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "TransparentCutout" "Queue" = "Transparent" }


            Pass
            {
                Name "FORWARD"
                Tags { "LightMode" = "UniversalForward" }

            // ZTest Equal
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha
            // Offset 0.5, 0.5
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ FOG_LINEAR
            #pragma multi_compile __ LIGHTMAP_ON
            #pragma multi_compile SHADOWS_SHADOWMASK
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma shader_feature _TEST_OCCLUSION_PROBE_OFF _TEST_OCCLUSION_PROBE_ON
            #pragma enable_d3d11_debug_symbols

            //CrossFade
            #pragma multi_compile_fragment __ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing

            #pragma shader_feature _DEBUG_OFF _DEBUG_SKYLIGHT

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Assets/Res/Shader/SceneCommon.hlsl"
            #include "./SceneObject-Lit_SimpleTree_PreZInput.hlsl"
            #include "Assets/Res/Shader/SceneObject-LitCloud.hlsl"
            #include "Assets/Res/Shader/ROOPTSubPassLoadUntils.hlsl"

            struct a2v
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                half3 normalOS      : NORMAL;
                half4 vertexColor   : COLOR0;

            #if defined(UNITY_DOTS_INSTANCING_ENABLED)
				uint instanceID : INSTANCEID_SEMANTIC;
			#endif
            };

            struct v2f {
                float4 positionCS    : SV_POSITION;
                float2 uv             : TEXCOORD0;
                float3 positionWS     : TEXCOORD1;
                half4 vertexColor    : TEXCOORD2;
                half4 fogFactor      : TEXCOORD3;
                half3 normalWS       : TEXCOORD4;
                half3 originNormalWS : TEXCOORD5;
                float4 screenPos      : TEXCOORD6;
                half2  lmap	    				: TEXCOORD7;
                #if LIGHTMAP_ON
                half2  truelmap	    				: TEXCOORD8;
                #endif
            // #if defined(UNITY_DOTS_INSTANCING_ENABLED)
				uint instanceID : CUSTOM_INSTANCE_ID;
            };

            v2f vert(a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.positionWS = positionWS;
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);

                //o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.normalWS = mul((float3x3) GetObjectToWorldMatrix(), v.normalOS.xyz);

                o.vertexColor = v.vertexColor;
                half3 originNormal = o.vertexColor.xyz * 2 - 1;
                // axis transform
                originNormal = originNormal.xzy;
                originNormal.xz = -originNormal.xz;
                o.originNormalWS = mul((float3x3) GetObjectToWorldMatrix(), originNormal.xyz);
                //o.originNormalWS = mul(originNormal, (float3x3)GetWorldToObjectMatrix());

                o.fogFactor = ComputeLinearFogFactor(o.positionWS.xyz, o.positionCS.z);
            // #if defined(UNITY_DOTS_INSTANCING_ENABLED)
            #if LIGHTMAP_ON
                o.truelmap = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
            #endif
                o.lmap = v.uv1.xy;
                
                o.screenPos = ComputeScreenPos(o.positionCS);
                return o;
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


            half3 CalTreeAmbientLight(half3 normalWS)
            {
                half sky, equator, ground;
                CalFittingSH(normalWS, sky, equator, ground);

                half3 skyColHSV = RGB2HSV(_LightModel_SkyColor.rgb);
                skyColHSV.y *= _AmbientSkySaturate;
                skyColHSV.z *= _AmbientSkyIntensity;
                half3 skyCol = HSV2RGB(skyColHSV);
                half3 equatorColHSV = RGB2HSV(_LightModel_EquatorColor.rgb);
                equatorColHSV.y *= _AmbientEquatorSaturate;
                equatorColHSV.z *= _AmbientEquatorIntensity;
                half3 equatorCol = HSV2RGB(equatorColHSV);
                half3 groundColHSV = RGB2HSV(_LightModel_SkyColor.rgb);
                groundColHSV.y *= _AmbientGroundSaturate;
                groundColHSV.z *= _AmbientGroundIntensity;
                half3 groundCol = HSV2RGB(groundColHSV);

                return sky * skyCol.rgb + 
                    equator * equatorCol.rgb + 
                    ground * groundCol.rgb;
            }

            half3 CalTreeRealtimeAmbient(half ao, half3 normalWS)
            {
                half3 res = 0;
                res.rgb = CalTreeAmbientLight(normalWS)*saturate(ao*_AOMapIntensity);
                return res;
            }

            float FetchOcclusionProbe(float3 positionWS, float4 boundsMax, float4 boundsMin, float4 scaleOffset)
            {
                float s = boundsMax.w;
                float t = boundsMin.w;
                float3 step = boundsMax.xyz - boundsMin.xyz;
                float3 offset = positionWS - boundsMin.xyz;
                float3 uvw = offset / step;
                if (scaleOffset.z == 0 && scaleOffset.w == 0)
                {
                    uvw = float3(uvw.x, uvw.z, uvw.y * scaleOffset.y + scaleOffset.x);
                }
                else
                {
                    uvw = float3(uvw.x * scaleOffset.y + scaleOffset.x, uvw.z * scaleOffset.w + scaleOffset.z, uvw.y);
                }
                return SAMPLE_TEXTURE3D(_TreeLightProbeTex, sampler_TreeLightProbeTex, uvw);
            }

            RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f input)
            {
                UNITY_SETUP_INSTANCE_ID(input);

                #ifdef LOD_FADE_CROSSFADE
                    #if defined(UNITY_DOTS_INSTANCING_ENABLED)
                        //游戏正常运行时的LOD CrossFade
					    LODCrossFadeDitheringTransition(input.positionCS.xyz, _BrgCrossFadeStart, _BrgCrossFadeSpeed, _CrossFadeSign);
                    #else
                        //游戏非正常运行时的LOD CrossFade，Editor和美术编辑场景
                        LODFadeCrossFade(input.positionCS);
                    #endif
                #endif

                half4 color = 1;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);
                           
                float3 normal_leaf = normalize(cross(ddy(input.positionWS),ddx(input.positionWS))).xyz;
                
                //AlphaTest
                float leaf_cut = dot(normal_leaf.xyz, normalize(viewDir.xyz));
                leaf_cut = clamp(abs(leaf_cut) - 0.1, 0.0, 1.0);
                leaf_cut = lerp(_CutOffset, 0, leaf_cut);
                float alpha = mainTex.a;
                // alpha = saturate(alpha - leaf_cut);
                // float4x4 thresholdMatrix =
                // {
                // 1.0,  9.0,  3.0,  11.0,
                // 13.0, 5.0,  15.0, 7.0,
                // 4.0,  12.0, 2.0,  10.0,
                // 16.0, 8.0,  14.0, 6.0
                // };
                // float2 scrPos = input.screenPos.yx / input.screenPos.ww;
                // scrPos.xy *= _ScreenParams.yx;
                // scrPos.xy = frac(abs(scrPos.xy * 0.25)) * 4.0;
                // clip(alpha - _NormalFadeOffset * thresholdMatrix[scrPos.x % 4][scrPos.y % 4] / 17.0);
                alpha = 1;
                //Lighting
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);

                half3 lightDir = mainLight.direction;
                half NdotL_Detail = dot(normalize(input.normalWS), lightDir);
                half NdotL_Whole = dot(normalize(input.originNormalWS), lightDir);
                half halfLambert = NdotL_Whole * 0.5 + 0.5;
                half halfLambert_Detail = NdotL_Detail * 0.5 + 0.5;
                half shadowArea = max(min(halfLambert_Detail, halfLambert),0.0);

                half4 preBakeLM = SAMPLE_TEXTURE2D(_PreBakeLightmap, sampler_PreBakeLightmap, input.lmap*_ShadowStrength);
                half bakedShadow = preBakeLM.r;
                
                // return SubPassOutputColor(input.vertexColor.aaaa, input.positionCS.z);
                // return SubPassOutputColor(preBakeLM.gggg, input.positionCS.z);

                half4 shadowMask = 1;
                #if defined(UNITY_DOTS_INSTANCING_ENABLED)
                    shadowMask.r = FetchOcclusionProbe(input.positionWS, _TreeBoundsMax, _TreeBoundsMin, _TreeLightProbeST)*bakedShadow;
                #elif LIGHTMAP_ON
                    shadowMask = SAMPLE_SHADOWMASK(input.truelmap);
                #else
                    shadowMask = bakedShadow;
                #endif
                // return SubPassOutputColor(shadowMask.xxxx, input.positionCS.z);

                shadowMask *= mainLight.shadowAttenuation;
                shadowArea = shadowArea * saturate(shadowArea*_BakeNormalLambert + shadowMask.r * _ShadowStrength);
                shadowArea = sqrt(shadowArea);

                // color.rgb = lerp(rampTex.rgb * _ShadowColor,rampTex.rgb, smoothstep(-0.3,0.3,halfLambert_Detail));
                half4 rampTex = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(shadowArea, 0.5));

                color.rgb = rampTex.rgb;

                half ao = lerp(0.5,1,saturate(input.vertexColor.a));

                half ao2 = (input.vertexColor.a * 0.5 + 0.5);

                color.rgb += lerp(0, color.rgb * _RimColor, mainTex.g) * shadowArea * ao2;

                half3 ambientCol = CalTreeRealtimeAmbient(ao, input.normalWS);

                half test = smoothstep(0.6,1,halfLambert_Detail);
                
                half3 directColor = color.rgb * shadowArea * mainLight.color;
                // half3 directColor = color.rgb * shadowArea * mainLight.color + mainTex.g * _RimColor.rgb * halfLambert_Detail * 0.1 * test * step(0.5,input.vertexColor.a);
                // directColor += _RimColor.rgb * saturate(NdotL_Detail) * saturate(input.vertexColor.a * 2 - 1);
                half3 indirectColor = color.rgb * ambientCol; 


                // return half4(ao.rrr, 1);

                color.rgb = directColor + indirectColor;

                // color.rgb *= rampTex.rgb;
                // half topPostion = dot(input.normalWS, normalize(_TopColorVector.xyz));
                // half topArea = topPostion * _TopColorScale + _TopColorOffset;
                // topArea = clamp(topArea, 0.0, 1.0);
                // color.rgb = lerp(color.rgb, color.rgb * _TopColor.rgb * _TopColor.a * 5, topArea);
                // half AO = input.vertexColor.a;
                // color.rgb = lerp(color.rgb * _AOColor, color.rgb, AO);
			    
                //backlit/rim
                float NDotV = dot(viewDir, normalize(input.normalWS));
                NDotV = NDotV * 0.5 + 0.5;
                NDotV = smoothstep(_RimRange,_RimRange-_RimSmooth,NDotV);
                half3 lightDir_Distortion = lightDir + normalize(input.originNormalWS);
                float VDotL = dot(viewDir, -lightDir_Distortion);
                VDotL = clamp(VDotL, 0.0, 1.0);
                VDotL = VDotL + 0.0001;
                VDotL = log2(VDotL);
                VDotL = VDotL * max(0.001,_LTPower);
                VDotL = exp2(VDotL);
                float rimArea = _LTScale * 25.0 * VDotL;
                
                float rimStr = (rimArea+1) * saturate(NdotL_Detail * _LTLambert + (1-_LTLambert)) * input.vertexColor.a;
                

                half3 rimColor = NDotV * mainLight.color.rgb * _RimIntensity * color.rgb * rimStr;

                // return half4(rimColor.rgb, 1);

				//Final Color
                color.rgb += rimColor;

                // fog
				color.rgb = MixFog(color.rgb, input.fogFactor);
                
                // color.rgb = NDotV;

                #if defined(_DEBUG_SKYLIGHT)
                color.rgb = indirectColor;
                #endif

                return SubPassOutputColor(half4(color.rgb, alpha), input.positionCS.z);
            }
            ENDHLSL
        }

        Pass
        {
            Name"ShadowCaster"
            Tags {"LightMode" = "ShadowCaster" }
       
            ZWrite On
            ZTest LEqual
            Cull Off

            HLSLPROGRAM
            #pragma multi_compile _ALPHATEST_ON
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "./SceneObject-Lit_SimpleTree_PreZInput.hlsl"
            #include "./SceneObject-Lit_SimpleTree_PreZShadow.hlsl"

            ENDHLSL
        }
    }
}