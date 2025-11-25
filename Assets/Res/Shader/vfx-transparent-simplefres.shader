Shader "Effect/vfx-transparent-simplefres"
{
    Properties
    {
        [CustomHeader(Total)]
        [Main(General, _KEYWORD, on, off)]_general("全局设置", float) = 1
        [Preset(General, LWGUI_BlendModePreset)]_BlendMode ("Blend Mode", float) = 1
        [SubToggle(General)]_ZWrite("ZWrite", Float) = 0.0
        [SubEnum(General, off, 0, front, 1, back, 2)] _CullFunc("Cull", Float) = 0.0

        [CustomHeader(ColorBase)]
        [Main(BaseTexture, _KEYWORD, on, off)]_TextureGroup("基础颜色", float) = 1
        [Sub(BaseTexture)]_MainColorIntensity("总颜色强度", Range(0,10)) = 1
        [Sub(BaseTexture)]_MainOpaIntensity("总透明度", Range(0,1)) = 1
        [Sub(BaseTexture)][HDR]_tex_main_color_1("颜色 1", Color) = (1,1,1,0)
        [Sub(BaseTexture)]_fadeout("_Fadeout_Test", Range(0,1)) = 0

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

        [CustomHeader(Advance)]
        [HideInInspector]_SrcBlend("SrcBlend", Float) = 1
        [HideInInspector]_DstBlend("DstBlend", Float) = 0
        [HideInInspector] _ZTest("__zt", Float) = 4

        [HideInInspector]_IndexBase ("IndexBase", Int) = 0
        [HideInInspector]_IndexStart ("IndexStart", Int) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend[_SrcBlend] [_DstBlend]
            ZWrite[_ZWrite]
            ZTest[_ZTest]
            Cull[_CullFunc]
            
            HLSLPROGRAM
            #pragma multi_compile _ _ENABLEFRACTION
            #pragma multi_compile _ _ENABLESELFPOINTLIGHT
            #pragma multi_compile _ _ENALBE_HEIGHT
            #pragma multi_compile _ _Toggle_UseTextureB

            #pragma multi_compile __ _ENABLE_INDEX2
            #pragma multi_compile __ _ENABLE_SKINNEDMESH

            #pragma multi_compile_instancing

            #pragma vertex Vert
            #pragma fragment Frag

            #include "./CommonHLSL.hlsl"

#ifdef _ENABLE_SKINNEDMESH
            struct VertexData
            {
                float3 position;
                float3 normal;
            };
            StructuredBuffer<VertexData> _Positions;
#else
            struct VertexData
            {
                float4 position;
                float4 normal;
            };
            StructuredBuffer<VertexData> _Positions;
#endif
            ByteAddressBuffer _Indices;

            CBUFFER_START(UnityPerMaterial)
                
                half _MainColorIntensity;
                half _MainOpaIntensity;

                half3 _tex_main_color_1;

                half _fadeout;

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

////////////////vertexdata//////////////////////
                uniform int _IndexBase;
                uniform int _IndexStart;
                uniform float4x4 _ObjectToWorld;
                uniform float4x4 _WorldToObject;
            CBUFFER_END

            struct VertexInput
            {
                half4 positionOS                : POSITION;
                half3 normalOS                  : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                half4 positionCS                : SV_POSITION;
                half3 normalWS                  : TEXCOORD0;
                half3 viewDirWS                 : TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uint loadIndex(uint id)
            {
        #ifdef _ENABLE_INDEX2
                return asuint(_Indices.Load(id * 2) >> (id % 2 * 16UL) & 0xFFFFUL);
        #else
                return asuint(_Indices.Load(id * 4));
        #endif
            }
    
            VertexOutput Vert(uint vertexID : SV_VertexID)
            {
                VertexOutput output = (VertexOutput)0;

                //UNITY_SETUP_INSTANCE_ID(input);
                //UNITY_TRANSFER_INSTANCE_ID(input, output);
                //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
                int index = loadIndex(vertexID + _IndexStart) + _IndexBase;
                float3 positionOS = _Positions[index].position.xyz;
                float3 normalOS = _Positions[index].normal.xyz;
                float3 positionWS = mul(_ObjectToWorld, float4(positionOS.xyz, 1.0f)).xyz;
        
                //VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(normalOS);
                output.normalWS = mul(normalOS, (float3x3) _WorldToObject);
                output.viewDirWS = normalize(GetCameraPositionWS() - positionWS);

                half4 positionCS = TransformWorldToHClip(positionWS);
                output.positionCS = positionCS;
                return output;
    }

            half Remap_Float(half x, half t1, half t2, half s1, half s2)
            {
                return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
            }

            half4 Frag(VertexOutput input) : SV_Target
            {
                //UNITY_SETUP_INSTANCE_ID(input);
                //UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 color = half4(0,0,0,1);
                color.rgb = _tex_main_color_1;
                color.a = 1;
                half fade = (1 - _fadeout);

                half NdotV = abs(dot(input.normalWS, input.viewDirWS));
                float fresnel = (_FresInvert > 0.5) ? NdotV : 1-NdotV;
                fresnel = fresnel * 0.5 + 0.5;
                fresnel = pow(fresnel,_FresPow);

                half fresAlpha = fresnel * _FresAlphaInten;
                fresAlpha += _FresAlphaAdd;
                color.a *= fresAlpha;

                half3 fresCol = fresnel * color.rgb;
                half fresColArea = saturate(Remap_Float(fresnel,_FresRemapMin,_FresRemapMax,0,1));

                half fadeColor = saturate(Remap_Float(fade,0.5,1,0,1));
                half fadeAlpha = saturate(Remap_Float(fade,0,0.8,0,1));
                color.rgb = lerp(color.rgb,_FresCol.rgb * _FresSideInten, fresColArea * fadeColor);

                color.rgb = color.rgb * _MainColorIntensity;
                color.a = color.a * _MainOpaIntensity * fadeAlpha;
                return color;
            }


            ENDHLSL
        }
    }
    CustomEditor "BigCatEditor.LWGUI"
}
