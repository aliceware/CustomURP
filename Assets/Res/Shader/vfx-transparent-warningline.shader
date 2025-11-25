Shader "Effect/WarningLine"
{
    Properties
    {
        _ZTest("ZTest", Float) = 2
        [SubEnum(General, off, 0, front, 1, back, 2)] _CullFunc("Cull", Float) = 0.0

        _UVOffsetStrength ("UV Offset Strength", float) = 0.1
        [HDR]MainColor("颜色1", Color) = (1,1,1,0)
        [HDR]MainColor2("颜色2", Color) = (1,1,1,0)

        [HDR]OutLineColor("outline", Color) = (1,1,1,0)

        [CustomHeader(Advance)]
        _SrcBlend("SrcBlend", Float) = 1
        _DstBlend("DstBlend", Float) = 0
    }
    
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }


        HLSLINCLUDE
        #include "./CommonHLSL.hlsl"
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

            CBUFFER_START(UnityPerMaterial)
            float _UVOffsetStrength;
            float3 OutLineColor;
            CBUFFER_END

            struct a2v
            {   
                float3 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct v2f{
                float4 positionCS   :SV_POSITION;
                float2 uv           :TEXCOORD0;
                float3 normalWS     :TEXCOORD1;
                half  screendepth   : TEXCOORD2;
            };

            v2f OutlineVertex(a2v i)
            {
                v2f output;

                output.uv = i.uv;

                float3 positionWS = TransformObjectToWorld(i.positionOS);
                float vOffset = sin(i.uv.y * 3.141592) * _UVOffsetStrength;
                positionWS.y += vOffset;

                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(i.normalOS);
                float3 normalWS = vertexNormalInput.normalWS;
                output.normalWS = normalize(normalWS);
                
                // positionWS += output.normalWS * outlineExpandAmount;
                output.positionCS = TransformWorldToHClip(positionWS + output.normalWS * 0.03);

                output.screendepth = output.positionCS.z/output.positionCS.w;
                
                return output;
            }


            // half4 frag(v2f input):SV_Target
            RO_OPAQUE_PIXEL_SHADER_FUNCTION(OutlineFragment, v2f i)
            {
                half4 result = 1;
                result.rgb = OutLineColor;
                

                return SubPassOutputColor(result, i.screendepth);
            }


            ENDHLSL
        }

        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend [_SrcBlend][_DstBlend]
            ZWrite On
            ZTest [_ZTest]
            Cull[_CullFunc]
            
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
            #pragma multi_compile __ RO_MS_READ
            #pragma multi_compile __ RO_FORCE_STORE_READ

            CBUFFER_START(UnityPerMaterial)
            float4 MainColor;
            float4 MainColor2;
            float _UVOffsetStrength;
            CBUFFER_END

            RO_FRAMEBUFFER_DECLARE_INPUT
            struct VertexInput
            {
                half4 positionOS                : POSITION;
                half4 uv                        : TEXCOORD0;
                half3 normalOS                    : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                half4 positionCS                : SV_POSITION;
                half4 color                     : COLOR;
                half2 uv                        : TEXCOORD0;
                half3 normalWS                  : TEXCOORD1;
                half3 viewDirWS                 : TEXCOORD2;
                

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            

            VertexOutput Vert(VertexInput i)
            {
                VertexOutput o;

                float3 positionWS = TransformObjectToWorld(i.positionOS);
                
                float vOffset = sin(i.uv.y * 3.141592) * _UVOffsetStrength;
                positionWS.y += vOffset;
                o.positionCS = TransformWorldToHClip(positionWS);

                o.uv = i.uv;

                o.normalWS = i.normalOS;
                o.viewDirWS = normalize(GetCameraPositionWS() - positionWS);
                return o;
            }
            
            RO_TRANSPARENT_PIXEL_SHADER_FUNCTION(Frag, VertexOutput i)
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 color = float4(1,1,1,0.5);
                half NdotV = dot(i.normalWS, i.viewDirWS);

                color.rgb = lerp(MainColor, MainColor2, sin((i.uv.y + _Time.y * 0.5) * 20));//sin(i.uv.y * 3.141592);
                
                RO_TRANSPARENT_PIXEL_OUTPUT(color)
            }

            ENDHLSL
        }
    }

    CustomEditor "BigCatEditor.LWGUI"
}