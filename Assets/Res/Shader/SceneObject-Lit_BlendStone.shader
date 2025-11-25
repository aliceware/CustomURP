Shader "RO/SceneObject/BlendStone" 
{
	Properties
	{
        [CustomHeader(BaseTexture)]
		_MainTex("Albedo", 2D) = "white" {}
        _Color ("Main Color", Color) = (1,1,1,1)
        [CustomHeader(NormalMap)]
        _NormalMap ("Normal Map", 2D) = "bump" { }
        _NormalMapScale ("Normal Map Scale", Range(0, 1)) = 1

        [CustomHeader(Grass or Snow)]
        _GrassDiffuse ("Grass/Snow MainTex", 2D) = "white" { }
        _GrassNormal ("Grass/Snow Normal", 2D) = "bump" { }
        _BlendIntensity ("Blend Intensity", Range(0, 1)) = 1
        _BlendSoft ("Blend Soft", Range(0, 1)) = 0.3
        _BlendOffset ("Blend Offset", Range(-5, 5)) = -0.5
		_BlendHeightOffset ("Blend Height Offset", Float) = 0
        _BlendDir ("Blend Direction", Vector) = (0.0,1.0,0.0,1)

        [CustomHeader(Blend)]
		_TerrainBlendRange("Terrain Blend Range", Range(0.0, 2.0)) = 1

		[CustomHeader(ScreenDoorTransparency)]
		[Toggle(_SCREEN_DOOR_TRANSPARENCY)]_ScreenDoorToggle("纱窗测试", float) = 0
		_SDAlphaTest("纱窗Alpha测试", Range(0,1)) = 1
		_DisplayStartTime("出现消失开始时间", Range(0,1)) = 1
		_DisplayInOut("出现消失标记", Float) = 0
		//BRG Lightmap
		[HideInInspector]_ObjectScale ("ObjectScale", Vector) = (0,0,0,0)
		[HideInInspector]_Lightmap ("Lightmap", 2D) = "white" {}
		[HideInInspector]_LightmapST("LightmapST", Vector) = (0,0,0,0)
		[HideInInspector]_Ao ("AO", 2D) = "white" {}

		[HideInInspector]_CrossFadeStart("CrossFadeStart", Float) = 1
		[HideInInspector]_CrossFadeSpeed("CrossFadeSpeed", Float) = 1
		[HideInInspector]_CrossFadeSign("CrossFadeSign", Float) = 1

        [HideInInspector]_SrcBlend("__src", Float) = 1.0
		[HideInInspector]_DstBlend("__dst", Float) = 0.0
		[HideInInspector]_ZWrite("__zw", Float)	= 1.0
		[HideInInspector]_Cull("Cull", Int)		= 2
	}

	SubShader
	{
		LOD 200

		Pass
		{
			Blend[_SrcBlend][_DstBlend] 
			ZWrite[_ZWrite]
			Cull[_Cull]

			Name "ForwardLit"
			Tags {"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
				
			#pragma multi_compile __ BRG_WITHOUT_AO
			#pragma multi_compile __ LIGHTMAP_ON_NOBRG
			#pragma multi_compile __ LIGHTMAP_ON

			#pragma multi_compile __ FOG_LINEAR

			#pragma multi_compile __ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile __ _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _SCREEN_DOOR_TRANSPARENCY

			#pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
			#pragma multi_compile __ RO_TERRAIN_LOAD
			#pragma multi_compile __ RO_MS_READ
			#pragma multi_compile __ RO_FORCE_STORE_READ
				
			#pragma shader_feature __ DEBUG_LIGHTMAP DEBUG_NOAOMAP

			// CrossFade
			#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE LOD_FADE_CROSSFADE_NOBRG
				
			//BRG
			#pragma multi_compile_instancing
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
				
			#include "./SceneCommon.hlsl" 
			#include "./ROOPTSubPassLoadTerrain.hlsl"
			#include "./SceneObject-Lit_BlendStoneInput.hlsl"
			#include "./SceneObject-Lighting.hlsl"
            #include "./SceneObject-LitCloud.hlsl"
            #include "./SceneObject-TerrainColor.hlsl"
			#include "./ScreenDoorTransparencyHLSL.hlsl"

			half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = half(1.0))
			{
				half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
				return UnpackNormalScale(n, scale);
			}

			struct a2v 
			{
				VS_DECLARE
				half3 normal		: NORMAL;
				half4 texcoord 	 	: TEXCOORD0;
				half4 texcoord1 	: TEXCOORD1;
    			half4 tangentOS     : TANGENT;    			// xyz: tangent, w: sign

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos						 : SV_POSITION;
				half3 normalWS					 : NORMAL;
				half4 uv						 : TEXCOORD0;
				half2 uv2						 : TEXCOORD1;
				half4 fogFactor				 	 : TEXCOORD2;
				float3 positionWS			 	 : TEXCOORD3;
				float3	viewDirWS				 : TEXCOORD4;

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				half2  lmap	    				: TEXCOORD5;
			#else
				half2  lmap	    				: TEXCOORD5;
			#endif

    			half4 tangentWS                : TEXCOORD8;    // xyz: tangent, w: sign
				half noGrassLocal				: TEXCOORD9;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert(a2v v)
			{
				VS_SKINNING_NORMAL(v)
				v2f o = (v2f)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
	
				half4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
				float grassBlendHeightOffset = saturate(dot(v.vertex.xyz, normalize(_BlendDir.xyz)) + _BlendHeightOffset);
				o.noGrassLocal = grassBlendHeightOffset;
					
				o.pos = mul(UNITY_MATRIX_VP, positionWS);
				o.uv.xy = float2(positionWS.x / _GrassDiffuse_ST.x, positionWS.z / _GrassDiffuse_ST.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _MainTex);

				half4 rotScaleWS = positionWS - mul(UNITY_MATRIX_M, half4(0,0,0,1));

                o.uv2.xy = TRANSFORM_TEX(v.texcoord, _NormalMap);
				
	
				o.positionWS	= positionWS.xyz;
				o.viewDirWS = GetCameraPositionWS() - positionWS.xyz;
				o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				o.normalWS = TransformObjectToWorldNormalForBRG(v.normal, (float3x3) UNITY_MATRIX_M, _ObjectScale);
			#else
				o.normalWS = TransformObjectToWorldNormal(v.normal.xyz);
			#endif
	
				real sign = real(v.tangentOS.w) * GetOddNegativeScale();
				half3 tangentWS = real3(TransformObjectToWorldDir(v.tangentOS.xyz));
				o.tangentWS = half4(tangentWS, sign);

				#if defined(UNITY_DOTS_INSTANCING_ENABLED)
					o.lmap = v.texcoord1.xy * _LightmapST.xy + _LightmapST.zw;
				#else
					o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				return o;
			}

			// half4 frag(v2f i) : SV_Target
			RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
			{
				UNITY_SETUP_INSTANCE_ID(i);
					
				#ifdef LOD_FADE_CROSSFADE
					#if defined(UNITY_DOTS_INSTANCING_ENABLED)
						LODCrossFadeDitheringTransition(i.pos, _BrgCrossFadeStart, _BrgCrossFadeSpeed, _CrossFadeSign);
					#else
						LODCrossFadeDitheringTransition(i.pos, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
					#endif
				#elif LOD_FADE_CROSSFADE_NOBRG
					LODCrossFadeDitheringTransition(i.pos.xyz, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
				#endif

				#ifdef _SCREEN_DOOR_TRANSPARENCY
					ClipScreenDoorTransparency(_SDAlphaTest, _DisplayStartTime, _DisplayInOut, i.positionWS.xyz, i.pos.xy);
				#endif

				half4 baseColor = tex2D(_MainTex, i.uv.zw);
				baseColor.rgb *= _Color.rgb;

				half3 normalWS = NormalizeNormalPerPixel(i.normalWS);
				half3 grassNormal = normalWS;

				half3 normalTS;
				half smoothness;
				half specular;
				half ao;

				UnpackNormalData(i.uv2.xy, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), normalTS, smoothness, ao, _NormalMapScale);
				normalWS = UnpackTangentNormal(normalWS, normalTS, i.tangentWS);


				half3 detail_light = saturate(ao + baseColor);
				half3 detail_dark = baseColor.rgb * ao;
				baseColor.rgb = lerp(detail_dark, detail_light, ao);

				float3 viewDirWS = i.viewDirWS;
				float3 viewDirectionWS = SafeNormalize(viewDirWS);

                // grass or snow
                    
                float3 blendDir = normalize(_BlendDir.xyz);
                float grassBlend = clamp((dot(blendDir.xyz, grassNormal.xyz) + _BlendOffset) / _BlendSoft, 0.0, 1.0);
                grassBlend = pow(grassBlend, 2);
                grassBlend = grassBlend * (grassBlend * (-2.0) + 3.0) * _BlendIntensity;
                grassBlend = clamp(grassBlend, 0.0, 1.0);
				grassBlend *= i.noGrassLocal;
					

				// half2 terrainColorUV = frac(half2(i.positionWS.x, i.positionWS.z) / 256);
                // half3 grassDiffuse = SampleTerrainCtrBc(i.positionWS, 0.5);
                half4 grassDiffuse = tex2D(_GrassDiffuse, i.uv.xy);
				half3 grassnormalTS;
				half grasssmoothness;
				half grassspecular;
				UnpackNormalData(i.uv.xy, TEXTURE2D_ARGS(_GrassNormal, sampler_GrassNormal), grassnormalTS, grasssmoothness, grassspecular, _NormalMapScale);
				grassNormal = UnpackTangentNormal(grassNormal, grassnormalTS, i.tangentWS);

                // Color mix
                baseColor.xyz = lerp(baseColor.xyz, grassDiffuse.xyz, grassBlend);
                smoothness = lerp(smoothness, grasssmoothness, grassBlend);
                specular = lerp(1, grassspecular, grassBlend);
                normalWS = lerp(normalWS, grassNormal, grassBlend);

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
		        half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(_Lightmap, sampler_Lightmap, i.lmap));
				#if BRG_WITHOUT_AO
					half ambientAO = CalAmbientAO(normalWS);
				#else
					half4 ambientColor = SAMPLE_TEXTURE2D(_Ao, sampler_Ao, i.lmap);
					half ambientAO = ambientColor.r;
						
					half normalAmbientAO = CalAmbientAO(normalWS);
					ambientAO = lerp(ambientAO, normalAmbientAO, smoothstep(50, 60, length(viewDirWS)));
				#endif
			#elif LIGHTMAP_ON_NOBRG && LIGHTMAP_ON
				half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, i.lmap));
				half4 ambientColor = SAMPLE_TEXTURE2D_LIGHTMAP(unity_ShadowMask, samplerunity_ShadowMask, i.lmap);
				half ambientAO = ambientColor.r;
					
				half normalAmbientAO = CalAmbientAO(normalWS);
				ambientAO = lerp(ambientAO, normalAmbientAO, smoothstep(50, 60, length(viewDirWS)));
		    #elif LIGHTMAP_ON
				half4 lm = DecodeLightmapForEditor(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, i.lmap));
				half ambientAO = CalAmbientAO(normalWS);
			#else
				half3 lm = 0;
				half ambientAO = CalAmbientAO(normalWS);
			#endif
	    		float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
			#if defined(UNITY_DOTS_INSTANCING_ENABLED) || (LIGHTMAP_ON_NOBRG && LIGHTMAP_ON)
				Light mainLight = GetMainLight(shadowCoord);
				mainLight.shadowAttenuation *= lm.a;
				half NdotL = saturate(dot(normalWS, mainLight.direction));
			#else
				float4 shadowMask = SAMPLE_SHADOWMASK(i.lmap);
				Light mainLight = GetMainLight(shadowCoord, i.positionWS.xyz, shadowMask);
				mainLight.shadowAttenuation *= shadowMask.r;
				half NdotL = saturate(dot(normalWS, mainLight.direction));
			#endif

			#if DEBUG_NOAOMAP
				ambientAO = CalAmbientAO(normalWS);
			#endif
				
			#ifndef LIGHTMAP_ON
				#ifdef _ADDITIONAL_LIGHTS
					lm.rgb = GetAddLightResult(lm.rgb, i.positionWS, normalWS);
				#endif
			#endif
				
				half3 lightColor = lerp(ro_ShadowEdgeColor.rgb * mainLight.color.rgb, mainLight.color.rgb, mainLight.shadowAttenuation);
					
				//cloudShadow
				half cloudShadow = GetCloudShadow(i.positionWS.xyz, mainLight.shadowAttenuation, ambientAO);
				mainLight.shadowAttenuation = cloudShadow;
				lightColor *= mainLight.shadowAttenuation;
				 

				BRDFData brdfData;
				InitBRDFData(baseColor.rgb, smoothness, specular, brdfData);
				half3 directColor = LightingDirectLOD(brdfData, normalWS, viewDirectionWS, mainLight);
				half3 indirectColor = LightingIndirectLOD(brdfData, normalWS, viewDirectionWS, lm.rgb, ambientAO);

				half4 c = 1;
				c.rgb = BlendTerrainColor(i.pos, _TerrainBlendRange, directColor, indirectColor, lightColor);
				// c.rgb = directColor*lightColor+indirectColor;
				// c.rgb = mainLight.shadowAttenuation;

				c.rgb = MixFog(c.rgb, i.fogFactor);

				return SubPassOutputColor(c, i.pos.z);
			}
			ENDHLSL
		}


	    Pass
	    {
	        Name "ShadowCaster"
	        Tags {"LightMode" = "ShadowCaster"}
	        
	        ZWrite On
	        ZTest LEqual
	        Cull [_Cull]
	        
	        HLSLPROGRAM
	        #pragma vertex ShadowPassVertex
	        #pragma fragment ShadowPassFragment
	        #include "./SceneObject-Lit_BlendStoneInput.hlsl"
	        #include "./SceneObject-Lit_BlendStoneShadow.hlsl"
	        ENDHLSL
	    }

		Pass
		{
			Name "Meta"
			Tags {"LightMode" = "Meta"}

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex VertexMeta
			#pragma fragment FragmentMeta
				
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "./SceneObject-Lit_BlendStoneInput.hlsl"

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float2 uv0          : TEXCOORD0;
				float2 uv1          : TEXCOORD1;
				float2 uv2          : TEXCOORD2;
				half4 vertexColor 	: COLOR;
			};

			struct Varyings
			{
				float4 positionCS   		: SV_POSITION;
				float2 uv           		: TEXCOORD0;
				float3 normalWS				: TEXCOORD1;
				float3 smoothNormalWS		: TEXCOORD2;
				float4 positionOS   		: TEXCOORD3;
			};

				
			Varyings VertexMeta(Attributes v)
			{
				Varyings o;
				o.positionOS = v.positionOS;
				o.positionCS = MetaVertexPosition(v.positionOS, v.uv1, v.uv2,
					unity_LightmapST, unity_DynamicLightmapST);
				o.uv = TRANSFORM_TEX(v.uv0, _MainTex);
				o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);

				float4 vertexColor = v.vertexColor;
				vertexColor = vertexColor * 2 - 1;
			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				o.smoothNormalWS = TransformObjectToWorldNormalForBRG(vertexColor.xyz, (float3x3) UNITY_MATRIX_M, _ObjectScale);
			#else
				o.smoothNormalWS  = TransformObjectToWorldNormal(vertexColor.xyz);
			#endif

				return o;
			}

			half4 FragmentMeta(Varyings i) : SV_Target
			{
				//half4 albedoAlpha			= SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
				//half alpha					= Alpha(albedoAlpha.a, _Color, _Cutoff);
				half4 albedoAlpha			= tex2D(_MainTex, i.uv);
				half3 albedo				= albedoAlpha.rgb * _Color.rgb*_Color.a;

				#ifdef ENABLE_GRASS_BLEND
					half4 grassDiffuse = tex2D(_GrassDiffuse, i.uv.xy);
                    
					float3 blendDir = normalize(_BlendDir.xyz);
					float3 grassNormal = i.smoothNormalWS.xyz;
					float grassBlend = clamp((dot(blendDir.xyz, grassNormal.xyz) + _BlendOffset) / _BlendSoft, 0.0, 1.0);
					grassBlend = pow(grassBlend, 2);
					grassBlend = grassBlend * (grassBlend * (-2.0) + 3.0) * _BlendIntensity;
					grassBlend = clamp(grassBlend, 0.0, 1.0);
					float grassBlendHeightOffset = saturate(i.positionOS.y + _BlendHeightOffset);
					grassBlend *= grassBlendHeightOffset;
					

					// Color mix
					albedo.xyz = lerp(albedo.xyz, grassDiffuse.xyz, grassBlend);
					// albedo = grassDiffuse.xyz;
				#endif

				//BRDFData brdfData;
				//InitializeBRDFData(albedo, 0, half3(0, 0, 0), 0, alpha, brdfData);

				MetaInput metaInput;
				metaInput.Albedo          = albedo;
				//metaInput.SpecularColor   = 0;
				metaInput.Emission        = 0;

				return MetaFragment(metaInput);  
			}
			
			ENDHLSL
		}
	}

	SubShader
	{
		LOD 0

		Pass
		{
			Blend[_SrcBlend][_DstBlend] 
			ZWrite[_ZWrite]
			Cull[_Cull]

			Name "ForwardLit"
			Tags {"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
				
			#pragma multi_compile __ BRG_WITHOUT_AO
			#pragma multi_compile __ LIGHTMAP_ON_NOBRG
			#pragma multi_compile __ LIGHTMAP_ON

			#pragma multi_compile __ FOG_LINEAR

			#pragma multi_compile __ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile __ _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _SCREEN_DOOR_TRANSPARENCY

			#pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
			#pragma multi_compile __ RO_TERRAIN_LOAD
			#pragma multi_compile __ RO_MS_READ
			#pragma multi_compile __ RO_FORCE_STORE_READ
				
			#pragma shader_feature __ DEBUG_LIGHTMAP DEBUG_NOAOMAP DEBUG_MINIMAP

			// CrossFade
			#pragma multi_compile_fragment __ LOD_FADE_CROSSFADE LOD_FADE_CROSSFADE_NOBRG
				
			//BRG
			#pragma multi_compile_instancing
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
				
			#include "./SceneCommon.hlsl" 
			#include "./ROOPTSubPassLoadTerrain.hlsl"
			#include "./SceneObject-Lit_BlendStoneInput.hlsl"
			#include "./SceneObject-Lighting.hlsl"
            #include "./SceneObject-LitCloud.hlsl"
            #include "./SceneObject-TerrainColor.hlsl"
			#include "./ScreenDoorTransparencyHLSL.hlsl"
			#include "./Editor-MinimapHelper.hlsl"

			half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = half(1.0))
			{
				half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
				return UnpackNormalScale(n, scale);
			}

			struct a2v 
			{
				VS_DECLARE
				half3 normal		: NORMAL;
				half4 texcoord 	 	: TEXCOORD0;
				half4 texcoord1 	: TEXCOORD1;
    			half4 tangentOS     : TANGENT;    			// xyz: tangent, w: sign

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos						 : SV_POSITION;
				half3 normalWS					 : NORMAL;
				half4 uv						 : TEXCOORD0;
				half2 uv2						 : TEXCOORD1;
				half4 fogFactor				 	 : TEXCOORD2;
				float3 positionWS			 	 : TEXCOORD3;
				float3	viewDirWS				 : TEXCOORD4;

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				half2  lmap	    				: TEXCOORD5;
			#else
				half2  lmap	    				: TEXCOORD5;
			#endif

    			half4 tangentWS                : TEXCOORD8;    // xyz: tangent, w: sign
				half noGrassLocal				: TEXCOORD9;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert(a2v v)
			{
				VS_SKINNING_NORMAL(v)
				v2f o = (v2f)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
	
				half4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
				float grassBlendHeightOffset = saturate(dot(v.vertex.xyz, normalize(_BlendDir.xyz)) + _BlendHeightOffset);
				o.noGrassLocal = grassBlendHeightOffset;
					
				o.pos = mul(UNITY_MATRIX_VP, positionWS);
				o.uv.xy = float2(positionWS.x / _GrassDiffuse_ST.x, positionWS.z / _GrassDiffuse_ST.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _MainTex);

				half4 rotScaleWS = positionWS - mul(UNITY_MATRIX_M, half4(0,0,0,1));

                o.uv2.xy = TRANSFORM_TEX(v.texcoord, _NormalMap);
				
	
				o.positionWS	= positionWS.xyz;
				o.viewDirWS = GetCameraPositionWS() - positionWS.xyz;
				o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				o.normalWS = TransformObjectToWorldNormalForBRG(v.normal, (float3x3) UNITY_MATRIX_M, _ObjectScale);
			#else
				o.normalWS = TransformObjectToWorldNormal(v.normal.xyz);
			#endif
	
				real sign = real(v.tangentOS.w) * GetOddNegativeScale();
				half3 tangentWS = real3(TransformObjectToWorldDir(v.tangentOS.xyz));
				o.tangentWS = half4(tangentWS, sign);

				#if defined(UNITY_DOTS_INSTANCING_ENABLED)
					o.lmap = v.texcoord1.xy * _LightmapST.xy + _LightmapST.zw;
				#else
					o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				return o;
			}

			// half4 frag(v2f i) : SV_Target
			RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
			{
				UNITY_SETUP_INSTANCE_ID(i);
					
				LODCrossFade(i.pos, _BrgCrossFadeStart, _BrgCrossFadeSpeed, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
				ClipScreenDoorTransparency(_SDAlphaTest, _DisplayStartTime, _DisplayInOut, i.positionWS.xyz, i.pos.xy);

				half4 baseColor = tex2D(_MainTex, i.uv.zw);
				baseColor.rgb *= _Color.rgb;

				half3 normalWS = NormalizeNormalPerPixel(i.normalWS);
				half3 grassNormal = normalWS;

				half3 normalTS;
				half smoothness;
				half specular;
				half ao;

				UnpackNormalData(i.uv2.xy, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), normalTS, smoothness, ao, _NormalMapScale);
				normalWS = UnpackTangentNormal(normalWS, normalTS, i.tangentWS);


				half3 detail_light = saturate(ao + baseColor);
				half3 detail_dark = baseColor.rgb * ao;
				baseColor.rgb = lerp(detail_dark, detail_light, ao);

				float3 viewDirWS = i.viewDirWS;
				float3 viewDirectionWS = SafeNormalize(viewDirWS);

                // grass or snow
                    
                float3 blendDir = normalize(_BlendDir.xyz);
                float grassBlend = clamp((dot(blendDir.xyz, grassNormal.xyz) + _BlendOffset) / _BlendSoft, 0.0, 1.0);
                grassBlend = pow(grassBlend, 2);
                grassBlend = grassBlend * (grassBlend * (-2.0) + 3.0) * _BlendIntensity;
                grassBlend = clamp(grassBlend, 0.0, 1.0);
				grassBlend *= i.noGrassLocal;
					

				// half2 terrainColorUV = frac(half2(i.positionWS.x, i.positionWS.z) / 256);
                half4 grassDiffuse = tex2D(_GrassDiffuse, i.uv.xy);
                grassDiffuse.rgb = SampleTerrainCtrBc(i.positionWS, grassDiffuse.rgb);
				half3 grassnormalTS;
				half grasssmoothness;
				half grassspecular;
				UnpackNormalData(i.uv.xy, TEXTURE2D_ARGS(_GrassNormal, sampler_GrassNormal), grassnormalTS, grasssmoothness, grassspecular, _NormalMapScale);
				grassNormal = UnpackTangentNormal(grassNormal, grassnormalTS, i.tangentWS);

                // Color mix
                baseColor.xyz = lerp(baseColor.xyz, grassDiffuse.xyz, grassBlend);
                smoothness = lerp(smoothness, grasssmoothness, grassBlend);
                specular = lerp(1, grassspecular, grassBlend);
                normalWS = lerp(normalWS, grassNormal, grassBlend);

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
		        half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(_Lightmap, sampler_Lightmap, i.lmap));
				#if BRG_WITHOUT_AO
					half ambientAO = CalAmbientAO(normalWS);
				#else
					half4 ambientColor = SAMPLE_TEXTURE2D(_Ao, sampler_Ao, i.lmap);
					half ambientAO = ambientColor.r;
						
					half normalAmbientAO = CalAmbientAO(normalWS);
					ambientAO = lerp(ambientAO, normalAmbientAO, smoothstep(50, 60, length(viewDirWS)));
				#endif
			#elif LIGHTMAP_ON_NOBRG && LIGHTMAP_ON
				half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, i.lmap));
				half4 ambientColor = SAMPLE_TEXTURE2D_LIGHTMAP(unity_ShadowMask, samplerunity_ShadowMask, i.lmap);
				half ambientAO = ambientColor.r;
					
				half normalAmbientAO = CalAmbientAO(normalWS);
				ambientAO = lerp(ambientAO, normalAmbientAO, smoothstep(50, 60, length(viewDirWS)));
		    #elif LIGHTMAP_ON
				half4 lm = DecodeLightmapForEditor(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, i.lmap));
				half ambientAO = CalAmbientAO(normalWS);
			#else
				half3 lm = 0;
				half ambientAO = CalAmbientAO(normalWS);
			#endif
	    		float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
			#if defined(UNITY_DOTS_INSTANCING_ENABLED) || (LIGHTMAP_ON_NOBRG && LIGHTMAP_ON)
				Light mainLight = GetMainLight(shadowCoord);
				mainLight.shadowAttenuation *= lm.a;
				half NdotL = saturate(dot(normalWS, mainLight.direction));
			#else
				float4 shadowMask = SAMPLE_SHADOWMASK(i.lmap);
				Light mainLight = GetMainLight(shadowCoord, i.positionWS.xyz, shadowMask);
				mainLight.shadowAttenuation *= shadowMask.r;
				half NdotL = saturate(dot(normalWS, mainLight.direction));
			#endif

			#if DEBUG_NOAOMAP
				ambientAO = CalAmbientAO(normalWS);
			#endif
				
			#ifndef LIGHTMAP_ON
				#ifdef _ADDITIONAL_LIGHTS
					lm.rgb = GetAddLightResult(lm.rgb, i.positionWS, normalWS);
				#endif
			#endif
				
				half3 lightColor = lerp(ro_ShadowEdgeColor.rgb * mainLight.color.rgb, mainLight.color.rgb, mainLight.shadowAttenuation);
					
				//cloudShadow
				half cloudShadow = GetCloudShadow(i.positionWS.xyz, mainLight.shadowAttenuation, ambientAO);
				mainLight.shadowAttenuation = cloudShadow;
				lightColor *= mainLight.shadowAttenuation;
				 

				BRDFData brdfData;
				InitBRDFData(baseColor.rgb, smoothness, specular, brdfData);
				half3 directColor = LightingDirect(brdfData, normalWS, viewDirectionWS, mainLight);
				half3 indirectColor = LightingIndirect(brdfData, normalWS, viewDirectionWS, lm.rgb, ambientAO);

				half4 c = 1;
				c.rgb = BlendTerrainColor(i.pos, _TerrainBlendRange, directColor, indirectColor, lightColor);
				// c.rgb = directColor*lightColor+indirectColor;
				// c.rgb = mainLight.shadowAttenuation;

				c.rgb = MixFog(c.rgb, i.fogFactor);

				#if DEBUG_MINIMAP
					c.rgb = MinimapColor(baseColor.rgb, i.positionWS);
				#endif
				return SubPassOutputColor(c, i.pos.z);
			}
			ENDHLSL
		}

	    Pass
	    {
	        Name "ShadowCaster"
	        Tags {"LightMode" = "ShadowCaster"}
	        
	        ZWrite On
	        ZTest LEqual
	        Cull [_Cull]
	        
	        HLSLPROGRAM
	        #pragma vertex ShadowPassVertex
	        #pragma fragment ShadowPassFragment
	        #include "./SceneObject-Lit_BlendStoneInput.hlsl"
	        #include "./SceneObject-Lit_BlendStoneShadow.hlsl"
	        ENDHLSL
	    }

		Pass
		{
			Name "Meta"
			Tags {"LightMode" = "Meta"}

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex VertexMeta
			#pragma fragment FragmentMeta
				
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "./SceneObject-Lit_BlendStoneInput.hlsl"

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float2 uv0          : TEXCOORD0;
				float2 uv1          : TEXCOORD1;
				float2 uv2          : TEXCOORD2;
				half4 vertexColor 	: COLOR;
			};

			struct Varyings
			{
				float4 positionCS   		: SV_POSITION;
				float2 uv           		: TEXCOORD0;
				float3 normalWS				: TEXCOORD1;
				float3 smoothNormalWS		: TEXCOORD2;
				float4 positionOS   		: TEXCOORD3;
			};

				
			Varyings VertexMeta(Attributes v)
			{
				Varyings o;
				o.positionOS = v.positionOS;
				o.positionCS = MetaVertexPosition(v.positionOS, v.uv1, v.uv2,
					unity_LightmapST, unity_DynamicLightmapST);
				o.uv = TRANSFORM_TEX(v.uv0, _MainTex);
				o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);

				float4 vertexColor = v.vertexColor;
				vertexColor = vertexColor * 2 - 1;
			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				o.smoothNormalWS = TransformObjectToWorldNormalForBRG(vertexColor.xyz, (float3x3) UNITY_MATRIX_M, _ObjectScale);
			#else
				o.smoothNormalWS  = TransformObjectToWorldNormal(vertexColor.xyz);
			#endif

				return o;
			}

			half4 FragmentMeta(Varyings i) : SV_Target
			{
				//half4 albedoAlpha			= SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
				//half alpha					= Alpha(albedoAlpha.a, _Color, _Cutoff);
				half4 albedoAlpha			= tex2D(_MainTex, i.uv);
				half3 albedo				= albedoAlpha.rgb * _Color.rgb*_Color.a;

				#ifdef ENABLE_GRASS_BLEND
					half4 grassDiffuse = tex2D(_GrassDiffuse, i.uv.xy);
                    
					float3 blendDir = normalize(_BlendDir.xyz);
					float3 grassNormal = i.smoothNormalWS.xyz;
					float grassBlend = clamp((dot(blendDir.xyz, grassNormal.xyz) + _BlendOffset) / _BlendSoft, 0.0, 1.0);
					grassBlend = pow(grassBlend, 2);
					grassBlend = grassBlend * (grassBlend * (-2.0) + 3.0) * _BlendIntensity;
					grassBlend = clamp(grassBlend, 0.0, 1.0);
					float grassBlendHeightOffset = saturate(i.positionOS.y + _BlendHeightOffset);
					grassBlend *= grassBlendHeightOffset;
					

					// Color mix
					albedo.xyz = lerp(albedo.xyz, grassDiffuse.xyz, grassBlend);
					// albedo = grassDiffuse.xyz;
				#endif

				//BRDFData brdfData;
				//InitializeBRDFData(albedo, 0, half3(0, 0, 0), 0, alpha, brdfData);

				MetaInput metaInput;
				metaInput.Albedo          = albedo;
				//metaInput.SpecularColor   = 0;
				metaInput.Emission        = 0;

				return MetaFragment(metaInput);  
			}
			
			ENDHLSL
		}
	}
}
