Shader "brg/brg_terrain"
{
    Properties
    {
        _Heightmap ("Heightmap", 2D) = "white" {}
        _HeightmapScaleOffset ("HeightmapScaleOffset", Vector) = (1, 1, 0, 0)
        _Normalmap ("Normal", 2D) = "white" {}
        _NormalmapScaleOffset ("NormalmapScaleOffset", Vector) = (0,0,0,0)
        _Splatmap ("Splatmap", 2D) = "white" {}
        _SplatTextureIndices ("SplatTextureIndices", Vector) = (0, 0, 0, 0)

        _Lightmap ("Lightmap", 2DArray) = "" {}
        _LightmapScaleOffset ("LightmapScaleOffset", Vector) = (0,0,0,0)
        _AO ("AO", 2DArray) = "" {}

        //_Parameter.x：_LightmapIndex
        //_Parameter.y：_AOIndex
        //_Parameter.z: _HoleHeight
        _Parameter("Parameter", Vector) = (0,0,0,0)
        
        //边缘顶点偏移标记(上，下，左，右)
        _EdgeVertexOffset ("EdgeVertexOffset", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }
        LOD 100

        Pass
        {
            Name "Forward"

            Cull Off

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //BRG
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "./SceneCommon.hlsl"
            #include "./SceneObject-Lighting.hlsl"
            #include "./SceneObject-LitCloud.hlsl"
            #include "./SceneObject-TerrainColor.hlsl"
            #include "./ROOPTSubPassLoadUntils.hlsl"

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ HIGH_QUALITY

            #pragma multi_compile __ FOG_LINEAR

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
            #pragma multi_compile __ RO_TERRAIN_LOAD
            #pragma multi_compile __ RO_MS_READ
            #pragma multi_compile __ RO_FORCE_STORE_READ
            #pragma multi_compile TERRAIN_LIGHT

            struct a2v
            {
                float4 vertex       : POSITION;
                float4 uv           : TEXCOORD0;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float2 uvSm         : TEXCOORD0;            //Splatmap的UV
                float4 uv01         : TEXCOORD1;
                float4 uv23         : TEXCOORD2;
                float3 positionWS   : TEXCOORD3;
                float3 viewDirWS	: TEXCOORD4;
                half4 fogFactor     : TEXCOORD5;
                half3  lmap	        : TEXCOORD6;            //xy为lightmap坐标， z为dot(normal, lightDir)
                float2 nmap         : TEXCOORD7;
    
                float2 screendepth : TEXCOORD8;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _Heightmap;
            sampler2D _Normalmap;
            sampler2D _Splatmap;

            TEXTURE2D_ARRAY(_SplatTextures);
            SAMPLER(sampler_SplatTextures);

            TEXTURE2D_ARRAY(_SplatNormals);
            SAMPLER(sampler_SplatNormals);
            
            TEXTURE2D_ARRAY(_Lightmap);
            SAMPLER(sampler_Lightmap);

            TEXTURE2D_ARRAY(_AO);
            SAMPLER(sampler_AO);

            float _SplatTextureTileSize[32];
            
            CBUFFER_START(UnityPerMaterial)
            float4  _HeightmapScaleOffset;
            uint4   _SplatTextureIndices;
            float4  _LightmapScaleOffset;
            float4  _NormalmapScaleOffset;
            float4  _EdgeVertexOffset;
            float4  _Parameter;
            CBUFFER_END

        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
            UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
                UNITY_DOTS_INSTANCED_PROP(float4, _HeightmapScaleOffset)
                UNITY_DOTS_INSTANCED_PROP(uint4 , _SplatTextureIndices)
                UNITY_DOTS_INSTANCED_PROP(float4, _LightmapScaleOffset)
                UNITY_DOTS_INSTANCED_PROP(float4, _NormalmapScaleOffset)
                UNITY_DOTS_INSTANCED_PROP(float4, _EdgeVertexOffset)
                UNITY_DOTS_INSTANCED_PROP(float4, _Parameter)
            UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

            #define _HeightmapScaleOffset   UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _HeightmapScaleOffset)
            #define _SplatTextureIndices    UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(uint4 , _SplatTextureIndices)
            #define _LightmapScaleOffset    UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LightmapScaleOffset)
            #define _NormalmapScaleOffset   UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _NormalmapScaleOffset)
            #define _EdgeVertexOffset       UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _EdgeVertexOffset)
            #define _Parameter              UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _Parameter)
        #endif

            half DecodeHeightmap4(float4 heightmapColor)
            {
                int a = floor(heightmapColor.x * 15.0f + 0.2f);
                int b = floor(heightmapColor.y * 15.0f + 0.2f);
                int c = floor(heightmapColor.z * 15.0f + 0.2f);
                int d = floor(heightmapColor.w * 15.0f + 0.2f);
                uint xx = floor(a & 0xF);
                uint yy = floor((b & 0xF) << 4);
                uint zz = floor(c & 0xF);
                uint ww = floor((d & 0xF) << 4);

                uint uval = xx | yy;
                uint uval1 = zz | ww;

                uint high = floor((uval1 & 0xFF) << 8);
                uint low = floor(uval & 0xFF);

                uint uheight = high | low;
                return (half)uheight * 300 / 32766;
            }

            half DecodeHeightmap8(float4 heightmapColor)
            {
                int a = floor(heightmapColor.r * 255.0f + 0.2f);
                int b = floor(heightmapColor.g * 255.0f + 0.2f);

                uint low = floor(a & 0xFF);
                uint high = floor((b & 0xFF) << 8);

                uint uheight = high | low;
                return (half)uheight * 300 / 32766;
            }

            void HeightBasedSplatModify(inout half4 splatControl, in half masks[4])
            {
                // heights are in mask blue channel, we multiply by the splat Control weights to get combined height
                half4 splatHeight = half4(masks[0], masks[1], masks[2], masks[3]) * splatControl.rgba;
                half maxHeight = max(splatHeight.r, max(splatHeight.g, max(splatHeight.b, splatHeight.a)));

                // Ensure that the transition height is not zero.
                // half transition = max(_HeightTransition, 1e-5);
                half transition = 0.15;

                // This sets the highest splat to "transition", and everything else to a lower value relative to that, clamping to zero
                // Then we clamp this to zero and normalize everything
                half4 weightedHeights = splatHeight + transition - maxHeight.xxxx;
                weightedHeights = max(0, weightedHeights);

                // We need to add an epsilon here for active layers (hence the blendMask again)
                // so that at least a layer shows up if everything's too low.
                weightedHeights = (weightedHeights + 1e-5) * splatControl;

                // Normalize (and clamp to epsilon to keep from dividing by zero)
                half sumHeight = max(dot(weightedHeights, half4(1, 1, 1, 1)), 1e-5);
                splatControl = weightedHeights / sumHeight.xxxx;
            }

            inline void UnpackNormalDataArray(float2 uv, int index, out half3 normalTS, out half smoothness, out half specular, half scale = 1.0)
            {
                // half4 bump = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
                half4 bump = SAMPLE_TEXTURE2D_ARRAY(_SplatNormals, sampler_SplatNormals, uv, index);
            
                normalTS = UnpackNormalmapRG(bump, scale);
                smoothness = bump.z;
                specular = bump.a;
            }

            void NormalMapMix(float4 uvSplat01, float4 uvSplat23, half dist, half4 splatControl, out half3 mixedNormal, out half smoothness, out half specular)
            {
                float nrmDist = smoothstep(64, 0.0, dist);
                // nrmDist = 1;
                half3 nrm = half(0.0);
                smoothness = 0;
                specular = 0;

                half2 nrmUV0 = half2(uvSplat01.y, uvSplat01.x);
                half2 nrmUV1 = half2(uvSplat01.w, uvSplat01.z);

                half3 normalTS0, normalTS1, normalTS2, normalTS3;
                half smoothness0, smoothness1, smoothness2, smoothness3;
                half specular0, specular1, specular2, specular3;

                UnpackNormalDataArray(uvSplat01.xy, _SplatTextureIndices.x, normalTS0, smoothness0, specular0, nrmDist);
                UnpackNormalDataArray(uvSplat01.zw, _SplatTextureIndices.y, normalTS1, smoothness1, specular1, nrmDist);
                UnpackNormalDataArray(uvSplat23.xy, _SplatTextureIndices.z, normalTS2, smoothness2, specular2, nrmDist);
                UnpackNormalDataArray(uvSplat23.zw, _SplatTextureIndices.w, normalTS3, smoothness3, specular3, nrmDist);

                nrm += splatControl.r * normalTS0;
                nrm += splatControl.g * normalTS1;
                nrm += splatControl.b * normalTS2;
                nrm += splatControl.a * normalTS3;

                smoothness += splatControl.r * smoothness0;
                smoothness += splatControl.g * smoothness1;
                smoothness += splatControl.b * smoothness2;
                smoothness += splatControl.a * smoothness3;

                specular += splatControl.r * specular0;
                specular += splatControl.g * specular1;
                specular += splatControl.b * specular2;
                specular += splatControl.a * specular3;

                // avoid risk of NaN when normalizing.
                #if HAS_HALF
                    nrm.z += half(0.01);
                #else
                    nrm.z += 1e-5f;
                #endif

                mixedNormal = normalize(nrm.xyz);
            }
            
            v2f vert (a2v v)
            {
                v2f o = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                //计算边缘顶点偏移
                float4 offset = v.uv * _EdgeVertexOffset;
                v.vertex.xz += offset.xz + offset.yw;
                
                float2 uv = v.vertex.xz / 16.0f;
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                
                //计算顶点高度
                float2 uvHm = uv * _HeightmapScaleOffset.xy + _HeightmapScaleOffset.zw;
                float4 heightmap = tex2Dlod(_Heightmap, half4(uvHm.xy, 0, 0));

                //计算hole
                float height = DecodeHeightmap8(heightmap);
                if (height == 0)
                {
            #if defined(HIGH_QUALITY)
                    positionWS.y = height;
            #else
                    positionWS.y = _Parameter.z;
            #endif
                }
                else
                {
                    positionWS.y = height;
                }

                o.vertex = TransformWorldToHClip(positionWS);
                o.uvSm = uvHm;

                const int index1 = _SplatTextureIndices.x * 2;
                const int index2 = _SplatTextureIndices.y * 2;
                const int index3 = _SplatTextureIndices.z * 2;
                const int index4 = _SplatTextureIndices.w * 2;
                o.uv01.xy = float2(positionWS.x * _SplatTextureTileSize[index1], positionWS.z * _SplatTextureTileSize[index1 + 1]);
                o.uv01.zw = float2(positionWS.x * _SplatTextureTileSize[index2], positionWS.z * _SplatTextureTileSize[index2 + 1]);
                o.uv23.xy = float2(positionWS.x * _SplatTextureTileSize[index3], positionWS.z * _SplatTextureTileSize[index3 + 1]);
                o.uv23.zw = float2(positionWS.x * _SplatTextureTileSize[index4], positionWS.z * _SplatTextureTileSize[index4 + 1]);

                o.positionWS = positionWS;
                o.viewDirWS = GetCameraPositionWS() - positionWS.xyz;

                o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.vertex.z);
                
                o.lmap.xy = uv.xy * _LightmapScaleOffset.xy + _LightmapScaleOffset.zw;
                o.lmap.z = heightmap.b;
                o.nmap.xy = uv.xy * _NormalmapScaleOffset.xy + _NormalmapScaleOffset.zw;
    
                o.screendepth = float2(o.vertex.z, o.vertex.w);
                return o;
            }

            //half4 frag (v2f i) : SV_Target
            RO_TERRAIN_SHADER_FUNCTION(frag, v2f i)
            {
                UNITY_SETUP_INSTANCE_ID(i);
                
                //计算Splatmap
                half4 splatmap = tex2D(_Splatmap, i.uvSm);
                half4 splatColor1 = SAMPLE_TEXTURE2D_ARRAY(_SplatTextures, sampler_SplatTextures, i.uv01.xy, _SplatTextureIndices.x);
                half4 splatColor2 = SAMPLE_TEXTURE2D_ARRAY(_SplatTextures, sampler_SplatTextures, i.uv01.zw, _SplatTextureIndices.y);
                half4 splatColor3 = SAMPLE_TEXTURE2D_ARRAY(_SplatTextures, sampler_SplatTextures, i.uv23.xy, _SplatTextureIndices.z);
                half4 splatColor4 = SAMPLE_TEXTURE2D_ARRAY(_SplatTextures, sampler_SplatTextures, i.uv23.zw, _SplatTextureIndices.w);

                //计算mask
                half masks[4] = {splatColor1.a, splatColor2.a, splatColor3.a, splatColor4.a};
                HeightBasedSplatModify(splatmap, masks);

                half3 ctrBc = SampleTerrainCtrBc(i.positionWS, 0.5);
                // splatColor1.rgb = ctrBc;

                half4 baseColor = splatColor1 * splatmap.r +
                              splatColor2 * splatmap.g +
                              splatColor3 * splatmap.b +
                              splatColor4 * (1 - splatmap.r - splatmap.g - splatmap.b);


                // ViewDir
                half3 viewDirectionWS = SafeNormalize(i.viewDirWS);
                float dist = length(i.viewDirWS);

                //计算normal
                half4 normalmap = tex2D(_Normalmap, i.nmap);
                half3 normalWS = normalmap.xyz;

                half smoothness = 0;
                half specular = 0;
                #if defined(HIGH_QUALITY)
                    half3 normalTS = half3(0.0h, 0.0h, 1.0h);
                    NormalMapMix(i.uv01, i.uv23, dist, splatmap, normalTS, smoothness, specular);

                    float4 vertexTangent = float4(cross(float3(0, 0, 1), normalWS), 1.0);
                    VertexNormalInputs normalInput = GetVertexNormalInputs(normalWS, vertexTangent);

                    float3x3 tangentToWorld = float3x3(-normalInput.tangentWS.xyz, normalInput.bitangentWS.xyz, normalWS);
                    normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                #endif
    
                //计算Lightmap
                half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D_ARRAY(_Lightmap, sampler_Lightmap, i.lmap.xy, (uint)_Parameter.x));
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);
				mainLight.shadowAttenuation *= lm.a;

                //计算AO
                half4 ambientColor = SAMPLE_TEXTURE2D_ARRAY(_AO, sampler_AO, i.lmap.xy, (uint)_Parameter.y);
				half normalAmbientAO = CalAmbientAO(half3(0, 1, 0));
				half ambientAO = lerp(ambientColor.r, normalAmbientAO, smoothstep(50, 60, dist));

				half3 lightColor = lerp(ro_ShadowEdgeColor.rgb * mainLight.color.rgb, mainLight.color.rgb, mainLight.shadowAttenuation);
                
                //cloudShadow
                half cloudShadow = GetCloudShadow(i.positionWS.xyz, mainLight.shadowAttenuation, ambientAO);
                mainLight.shadowAttenuation = cloudShadow;

                lightColor *= mainLight.shadowAttenuation;
                
                BRDFData brdfData;
                InitBRDFData(baseColor.rgb, smoothness, specular, brdfData);
                half3 directColor = LightingDirect(brdfData, normalWS, viewDirectionWS, mainLight);
                half3 indirectColor = LightingIndirect(brdfData, normalWS, viewDirectionWS, lm.rgb, ambientAO);

                half4 finalColor = 1;
                finalColor.rgb = directColor*lightColor+indirectColor;
    
				finalColor.rgb = MixFog(finalColor.rgb, i.fogFactor);

                // finalColor.rgb = ctrBc.rgb;

                return TerainOutputColor(finalColor, i.vertex.z, directColor, indirectColor);
            }
            ENDHLSL
        }
    }
}
