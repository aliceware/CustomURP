Shader "RO/SceneObject/GrassBrg"
{
    Properties
    {
        [NoScaleOffset]_MainTex("Albedo", 2D) = "white" {}
        [HideInInspector]_Color("Color", Color) = (1, 1, 1, 1)
        _SheenHeightMax("Sheen Height Max", Float) = 1

        _NoiseTex("SwingTex", 2D) = "white" {}
        _SwingStrength("Swing Bend Strength", Range( 0 , 1)) = 0.48
        _SwingFreq("Swing Speed", Range( 0 , 1)) = 0.1

        _RandomBendStrength("Random Bend Angle", Range( 0 , 5)) = 2
        _DefaultBendAngleBias("Default Bend Angle Bias", Range( -1 , 1)) = 0

		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilCompOp("Stencil CompOp", Float) = 8
		[Enum(UnityEngine.Rendering.StencilOp)]_StencilPassOp("Stencil PassOp", Float) = 2
		[IntRange]_StencilRef("Stencil Ref", Range(0, 255)) = 8
		[IntRange]_StencilReadMask("Stencil ReadMask", Range(0, 255)) = 8
		[IntRange]_StencilWriteMask("Stencil WriteMask", Range(0, 255)) = 8
    }

    SubShader
    {
		LOD 200

        Tags { "Queue"="Geometry-10"}
        Pass
        {

            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

			ZTest LEqual
			ZWrite On
            Cull Off

            HLSLPROGRAM
            #include "Assets/Res/Shader/AtmosphereCommon.hlsl"
            #include "./GrassCommon.hlsl"
            #include "Assets/Res/Shader/ROOPTSubPassLoadTerrain.hlsl"
            #include "Assets/Res/Shader/SceneObject-LitCloud.hlsl"
            #include "./CommonUtilities.hlsl"

            //BRG
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #pragma target 3.0
            #pragma multi_compile __ FOG_LINEAR

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD
            #pragma multi_compile __ RO_MS_READ
            #pragma multi_compile __ RO_FORCE_STORE_READ

            #pragma shader_feature __ DEBUG_LIGHTMAP

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            half4 _LightModel_Ambient;

            // 全局参数
            // sheen params
            half4 _SheenColorNear;
            half4 _SheenColorFar;

            float4 _SheenParams;
            #define _SheenDistNear _SheenParams.x
            #define _SheenDistFar _SheenParams.y
            #define _SheenScatterMin _SheenParams.z
            #define _SheenPower _SheenParams.w

            // wind tilingoffset
            float4 _WindTexTiling;
            // wind params
            half4 _WindParams1;
            #define _WindAngle _WindParams1.x
            #define _WindSpeed _WindParams1.y
            #define _WindBendStrength _WindParams1.z
            #define _WindNoise _WindParams1.w

            // wind params cont.
            half4 _WindParams2;
            #define _WindMask _WindParams2.x
            #define _WindSheenInten _WindParams2.y
            #define _WindDisorderFreq _WindParams2.z

			CBUFFER_START(UnityPerMaterial)
            uniform float4 _Color;
			 // swing params
            uniform float4 _NoiseTex_ST;
            // float4 _SwingParams;
            uniform float _SheenHeightMax;
            uniform half _SwingStrength;
            uniform half _SwingFreq;
            uniform half _RandomBendStrength;
            uniform half _DefaultBendAngleBias;
			CBUFFER_END

        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
            UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
                UNITY_DOTS_INSTANCED_PROP(float4, _Color)
            UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

            #define _Color   UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _Color)
        #endif

            struct a2v
            {
                float4  vertex      : POSITION;
                float2  texcoord    : TEXCOORD0;
                float2  texcoord1   : TEXCOORD1;

			    UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4	pos                     : SV_POSITION;
                float2	uv                      : TEXCOORD0;
                half4   shadowCoord			: TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                // UNITY_VERTEX_OUTPUT_STEREO
            };


            v2f vert(a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                float3 positionWS = mul(UNITY_MATRIX_M, v.vertex).xyz;
                float4 positionCS = TransformWorldToHClip(positionWS);
                o.pos = positionCS;

                o.shadowCoord = TransformWorldToShadowCoord(positionWS);
                o.uv = v.texcoord;


                return o;
            }

            RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 color = _Color;

                half4 c = tex2D(_MainTex, i.uv);
                return SubPassOutputColor(c, i.pos.z);

            }
            ENDHLSL
        }
    }

    SubShader
    {
		LOD 0
        Tags { "Queue"="Geometry-10"}
        Pass
        {

            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

			ZTest LEqual
			ZWrite On
            Cull Off

            HLSLPROGRAM
            #include "Assets/Res/Shader/AtmosphereCommon.hlsl"
            #include "./GrassCommon.hlsl"
            #include "Assets/Res/Shader/ROOPTSubPassLoadTerrain.hlsl"
            #include "Assets/Res/Shader/SceneObject-LitCloud.hlsl"
            #include "./CommonUtilities.hlsl"

            //BRG
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #pragma target 3.0
            #pragma multi_compile __ FOG_LINEAR

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD
            #pragma multi_compile __ RO_MS_READ
            #pragma multi_compile __ RO_FORCE_STORE_READ

            #pragma shader_feature __ DEBUG_LIGHTMAP

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            half4 _LightModel_Ambient;

            // 全局参数
            // sheen params
            half4 _SheenColorNear;
            half4 _SheenColorFar;

            float4 _SheenParams;
            #define _SheenDistNear _SheenParams.x
            #define _SheenDistFar _SheenParams.y
            #define _SheenScatterMin _SheenParams.z
            #define _SheenPower _SheenParams.w

            // wind tilingoffset
            float4 _WindTexTiling;
            // wind params
            half4 _WindParams1;
            #define _WindAngle _WindParams1.x
            #define _WindSpeed _WindParams1.y
            #define _WindBendStrength _WindParams1.z
            #define _WindNoise _WindParams1.w

            // wind params cont.
            half4 _WindParams2;
            #define _WindMask _WindParams2.x
            #define _WindSheenInten _WindParams2.y
            #define _WindDisorderFreq _WindParams2.z

			CBUFFER_START(UnityPerMaterial)
            uniform float4 _Color;
			 // swing params
            uniform float4 _NoiseTex_ST;
            // float4 _SwingParams;
            uniform float _SheenHeightMax;
            uniform half _SwingStrength;
            uniform half _SwingFreq;
            uniform half _RandomBendStrength;
            uniform half _DefaultBendAngleBias;
			CBUFFER_END

            sampler2D _OverlayPassTexture;
            float4 _OverlayPassTexture_TexelSize;
            float4x4 unity_MatrixVP_OP;

        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
            UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
                UNITY_DOTS_INSTANCED_PROP(float4, _Color)
            UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

            #define _Color   UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _Color)
        #endif

            struct a2v
            {
                float4  vertex      : POSITION;
                float2  texcoord    : TEXCOORD0;
                float2  texcoord1   : TEXCOORD1;

			    UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4	pos                     : SV_POSITION;
                float2	uv                      : TEXCOORD0;
                half4   shadowCoord			: TEXCOORD1;
                half4	fogFactor               : TEXCOORD2;
                float3 	viewDirWS               : TEXCOORD3;
                half2 	sheen                   : TEXCOORD4;
                float4   positionWS          : TEXCOORD5;
                float3 test :TEXCOORD6;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                // UNITY_VERTEX_OUTPUT_STEREO
            };


            v2f vert(a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 rootPosLS = float3(v.texcoord1.x, 0, v.texcoord1.y);
                float3 rootPosWS = mul(UNITY_MATRIX_M, float4(rootPosLS, 1.0)).xyz;

                float rootRand0t1 = GrassHash(rootPosWS.x + rootPosWS.z * 516.0);
                float bend = (rootRand0t1 - 0.5) * _RandomBendStrength;

                float3 bendDirWS = normalize(float3(1.0, 0, bend));
                float2 bendXZ = RotateVec2(bendDirWS.xz, -_WindAngle);
                bendDirWS = float3(bendXZ.x, 0, bendXZ.y);
                bendDirWS = normalize(bendDirWS);
                float3 bendDirLS = mul(UNITY_MATRIX_I_M, float4(bendDirWS, 0)).xyz;

                float2 rootPosUV = RotateVec2(float2(rootPosWS.x/100, rootPosWS.z/100), _WindAngle-90);

                // 自摆
                float4 noiseUV = 0;
                noiseUV.xy = TRANSFORM_TEX(rootPosUV, _NoiseTex);
                noiseUV.x += +_TimeParameters.x * _SwingFreq;
                half4 noiseRGBA = tex2Dlod(_NoiseTex, noiseUV);
                half noise2 = noiseRGBA.r;

                // 风浪
                float4 windUV = 0;
                windUV.xy = rootPosUV * _WindTexTiling.xy + _WindNoise * noiseRGBA.rg;
                windUV.x += _TimeParameters.x*_WindSpeed;
                half4 windRGBA = tex2Dlod(_NoiseTex, windUV);
                half noise1 = ChannelBlend(windRGBA, _TimeParameters.x);

                noise1 = saturate((noise1-_WindMask)/(1.0-_WindMask));
                half bendStrength = pow(noise1 * _WindBendStrength * rootRand0t1, 3.0) + saturate(noise2) * _SwingStrength + _DefaultBendAngleBias;
                bendStrength = SmoothClampToOne(bendStrength);

                float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
                float3 rotateVal = RotateAroundAxis(rootPosWS, positionWS.xyz, bendDirLS, bendStrength * 1.57 * v.vertex.y);

                rotateVal -= positionWS.xyz;
                v.vertex.xyz += rotateVal;

                //Interact
                half4 overlayPos = mul(unity_MatrixVP_OP, positionWS);
                overlayPos.y = -overlayPos.y;
                overlayPos += 0.5;
                half4 overlayTex = tex2Dlod(_OverlayPassTexture, float4(overlayPos.xy, 0, 0));
                float3 interactDirWS = normalize(float3(rootPosWS.x, 0, rootPosWS.z) - float3(_PlayerLocation.x,0,_PlayerLocation.z));
                float3 interactDirLS = mul(UNITY_MATRIX_I_M, float4(interactDirWS, 0)).xyz;
                float interactStr = min(overlayTex.r * v.vertex.y, 0.2);
                v.vertex.xyz += interactDirLS * interactStr;

                positionWS = mul(UNITY_MATRIX_M, v.vertex);
                float4 positionCS = TransformWorldToHClip(positionWS);
                o.pos = positionCS;

                o.shadowCoord = TransformWorldToShadowCoord(positionWS);
                o.uv = v.texcoord;


                float3 viewDirWS = GetCameraPositionWS() - positionWS.xyz;
                o.viewDirWS = viewDirWS;

                o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);

                float dist = length(viewDirWS);
                dist = smoothstep(_SheenDistNear, _SheenDistFar, dist);

                viewDirWS = normalize(viewDirWS);
                float fresnel = dot(viewDirWS, UNITY_MATRIX_M._m01_m11_m21);
                noise1 = saturate(_WindSheenInten * noise1);
                half power = lerp(_SheenPower, 0, noise1);
                fresnel = pow(saturate(1.0 - fresnel), power);

                half sheen = fresnel * v.vertex.y / _SheenHeightMax;
				#ifdef LOCAL_HEIGHT_FOG
					float scatter = dot(viewDirWS, ro_SunDir.xyz) * HeightFogDensity;
					scatter = lerp(_SheenScatterMin, 1, scatter);
					sheen *= scatter;
				#endif
                o.sheen.x = saturate(sheen);
                o.sheen.y = dist;

                o.positionWS = positionWS;
                o.test = rootPosWS;

                return o;
            }

            RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 color = _Color;

                half4 c = tex2D(_MainTex, i.uv);
                half3 sheenColor = lerp(_SheenColorNear.rgb, _SheenColorFar.rgb, i.sheen.y);
                c.rgb += sheenColor * i.sheen.x;
                Light mainLight = GetMainLight(i.shadowCoord);

                //解析Shadowmask和AO
                int value = color.a * 65535.0f;
                float shadowMaskMulNdotL = (value & 0xFF) / 255.0f;
                float ambientAO = ((value & 0xFFFF) >> 8) / 255.0f;
                half3 ambient = CalRealtimeAmbient(ambientAO, half3(0,1,0));

                //cloudShadow
                half cloudShadow = GetCloudShadow(i.positionWS.xyz, mainLight.shadowAttenuation, ambientAO);
                mainLight.shadowAttenuation = cloudShadow;

				half3 lightColor = mainLight.color.rgb;
                lightColor *= mainLight.shadowAttenuation;

                half3 radiance = lightColor * shadowMaskMulNdotL;
                half3 lm = DecodeLightmapForRuntime(color.rgb);

                // half3 normalWS = half3(0,1,0);
                // lm.rgb += CalRealtimeAmbient(0, normalWS);

                half3 leftAmb = lm + radiance + ambient;
                // return half4(color.a * mainLight.color.rgb,1);
                // #ifndef UNITY_COLORSPACE_GAMMA
                //     leftAmb = Gamma22ToLinear(leftAmb);
                // #endif
                c.rgb *= leftAmb;

				c.rgb = MixFog(c.rgb, i.fogFactor);
                #if DEBUG_LIGHTMAP
                    c.rgb = lm.rgb;
                #endif

                // half4 overlayPos = mul(unity_MatrixVP_OP, i.positionWS);
                // overlayPos.y = -overlayPos.y;
                // overlayPos += 0.5;
                // half4 overlayTex = tex2D(_OverlayPassTexture, overlayPos.xy);
                // c.rgb = overlayTex.rgb;

                return SubPassOutputColor(c, i.pos.z);

            }
            ENDHLSL
        }
    }
}
