Shader "Effect/vfx-transparent-fakelight"
{
    Properties
    {
        [CustomHeader(Total)]
        [Main(General, _KEYWORD, on, off)]_general("全局设置", float) = 1
        [Preset(General, LWGUI_BlendModePreset)]_BlendMode ("Blend Mode", float) = 1
        [SubToggle(General)]_ZWrite("ZWrite", Float) = 0.0
        [Sub(General)]_ZTest("ZTest", Float) = 4
        [SubEnum(General, off, 0, front, 1, back, 2)] _CullFunc("Cull", Float) = 0.0

        [Sub(General)]_Range("范围", Range(0,1)) = 1
        [Sub(General)]_RangeScale("_RangeScale", Float) = 1
        [Sub(General)][HDR]_Color("颜色", Color) = (1,1,1,0)
        [Sub(General)]_Intensity("强度", Range(0,5)) = 1

        [CustomHeader(Advance)]
        [HideInInspector]_SrcBlend("SrcBlend", Float) = 1
        [HideInInspector]_DstBlend("DstBlend", Float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Overlay" "Queue" = "Transparent-499" "DisableBatching" = "True" }


        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend One One
            ZWrite[_ZWrite]
            ZTest[_ZTest]
            Cull[_CullFunc]
            
            HLSLPROGRAM
            #pragma multi_compile _ _ENABLEFRACTION
            #pragma multi_compile _ _ENABLESELFPOINTLIGHT
            #pragma multi_compile _ _Toggle_DECAL

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
            #pragma multi_compile __ RO_MS_READ
            #pragma multi_compile __ RO_FORCE_STORE_READ

            #pragma multi_compile_instancing

            #pragma vertex Vert
            #pragma fragment Frag

            #include "./CommonHLSL.hlsl"
            #include "./ROOPTSubPassLoadUntils.hlsl"


            #define PI 3.1415926

            CBUFFER_START(UnityPerMaterial)
                float _Range;
                float _RangeScale;
                float4 _Color;
                float _Intensity;
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
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                half4 positionCS                : SV_POSITION;
                half4 color                     : COLOR;
                half2 uv                        : TEXCOORD0;//1u
                half4 customData                : TEXCOORD1;//x(mask offset);y(dissolve);zw(main/dissolve uv offset)   
                half4 screenPos                 : TEXCOORD2;
                half3 viewRayOS                 : TEXCOORD3;
                half4 positionOS                : TEXCOORD4;
                half4 size                      : TEXCOORD5;
                half  rot                       : TEXCOORD6;

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
                output.customData.xy = input.uv.zw;
                output.customData.zw = input.uv1.zw;

                output.color = input.color;

                output.positionOS = input.positionOS;
                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
                float3 positionWS = vertexPositionInput.positionWS;
                output.positionCS = vertexPositionInput.positionCS;
                float3 viewRay = vertexPositionInput.positionVS;
                float4x4 ViewToObjectMatrix = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
                output.viewRayOS.xyz = mul((float3x3)ViewToObjectMatrix, viewRay);
                output.viewRayOS.xyz /= -viewRay.z;

                output.screenPos = ComputeScreenPos(output.positionCS);
                return output;
            }

            half Remap_Float(half x, half t1, half t2, half s1, half s2)
            {
                
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }


            float4 GetWorldPositionFromDepthValue(float2 uv, float linearDepth) //重建世界坐标
			{
				float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;

				float height = 2 * camPosZ / unity_CameraProjection._m11;
				float width = _ScreenParams.x / _ScreenParams.y * height;

				float camPosX = width * uv.x - width / 2;
				float camPosY = height * uv.y - height / 2;
				float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
				return mul(unity_CameraToWorld, camPos);
			}

            float NormalDistribution(float x, float intensity, float range)
			{
				return ((1 / sqrt(2)*PI) * exp(-pow(x*(1 / range), 2) / 2)) * intensity;
                // return clamp(1.0f - (x / range), 0.0, 1.0) * intensity;
			}


            float3 getProjectedObjectPos(float3 viewRayOS, float depth){
                //get depth from depth texture
                float3 worldPos = _WorldSpaceCameraPos + viewRayOS * depth;

                return worldPos;
            }


            RO_TRANSPARENT_PIXEL_SHADER_FUNCTION(Frag, VertexOutput input)
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float deltaTime = _Time.y % 100.0f;

                half4 color = half4(0,0,0,1);

                RO_TRANSPARENT_PIXEL_INPUT;
                // float2 screenSpaceUV = input.positionCS.xy;
                float2 screenSpaceUV = input.screenPos.xy/input.screenPos.w;
                float rawD = GET_SUBPASS_LOAD_DEPTH(input.positionCS.xy);
                float3 sceneCol = GET_SUBPASS_LOAD_COLOR(input.positionCS.xy);
                float depth = Linear01Depth(rawD.r, _ZBufferParams);

                // float3 screenWorldPos = _WorldSpaceCameraPos + input.viewRayOS * depth;
                float3 screenWorldPos = GetWorldPositionFromDepthValue(screenSpaceUV , depth);
                
                float4x4 m = UNITY_MATRIX_M;
				float3 worldPos = float3(m[0].w, m[1].w, m[2].w);
                
                // clip(area - 0.0001);
                
				float distance = length(screenWorldPos - worldPos);

                float grey = saturate(0.299 * sceneCol.r + 0.578 * sceneCol.g + 0.114* sceneCol.b);
                float shadow = saturate(smoothstep(-0.2, 0.07,grey));

                float colFactor = lerp(50,1,shadow);
                float3 colorBlend = _Color.rgb * sceneCol * colFactor;
 
                float area = NormalDistribution(distance, _Intensity, _Range * 0.08 * _RangeScale);
				color.rgb = colorBlend * area;

                clip(area - 0.0001);
                RO_TRANSPARENT_PIXEL_OUTPUT(color)
            }


            ENDHLSL
        }
    }
    CustomEditor "BigCatEditor.LWGUI"
}
