Shader "RO/SceneObject/Lit_Effect" 
{
	Properties
	{
        [CustomHeader(BaseTexture)]
        [Enum(None, 0, Emission, 1, Transparent, 2, CutOut, 3, Scatter, 4)] _BaseAlphaType ("Base Alpha Type", Float) = 0
		[MainTexture]_MainTex("Albedo", 2D) = "white" {}
		[ShowIf(_BaseAlphaType, Equal, 3)]_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [ShowIf(_BaseAlphaType, Equal, 1)]_EmissionIntensity ("Emission Intensity", Float) = 1
		_Color("Color", Color) = (1,1,1,1)
        [ShowIf(_BaseAlphaType, Equal, 4)]_ScatterRadius ("Scatter Radius", Float) = 4
        [ShowIf(_BaseAlphaType, Equal, 4)]_ScatterIntensity ("Scatter Intensity", Float) = 1

		[CustomHeader(NormalMap)]
		[Enum(NoNormal, 0, Specular, 2)]_EnableNormalMap("Normal Map Alpha Type", Float) = 0
		_NormalMap("Normal Map(RG:Normal|B:Rough|A:Metallic)", 2D) = "white" {}
		_NormalScale("Normal Scale", Range(0.0, 2.0)) = 1
		
		[CustomHeader(Effect)]
		_ParallaxMap("Parallax Map", 2D) = "Black" {}
		_ParallaxScale("Parallax Scale", Range(0.0, 1)) = 1
		_CausticMap("Caustic Map", 2D) = "Black" {}
		_CubeMap("CubeMap", CUBE)				 = ""{}
		_CubeColor("Color", Color) = (1,1,1,1)
		_RimInten("Rim Inten", Range(0.0, 5.0)) = 1

        [CustomHeader(Blend)]
		_TerrainBlendRange("Terrain Blend Range", Range(0.0, 2.0)) = 1
		[Toggle]_ZWrite("ZWrite", Float)	= 1.0
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Int)		= 2

		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("__src", Float) = 1.0
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("__dst", Float) = 0.0

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
	}

	SubShader
	{
		LOD 0

		Pass
		{
			Blend One Zero
			ZWrite[_ZWrite]
			Cull[_Cull]

			Name "ForwardLit"
			Tags{"LightMode" = "UniversalForward"}
			
			HLSLPROGRAM 
			#pragma vertex vert  
			#pragma fragment frag
			#pragma multi_compile LIT_CRYSTAL
			#pragma multi_compile LOD_HIGH_SHADER
			
			#include_with_pragmas "./SceneObject-LitInput.hlsl"
			#include_with_pragmas "./SceneObject-LitForwardBasePragma.hlsl"
			
			#include "./SceneCommon.hlsl"
			#include "./ROOPTSubPassLoadTerrain.hlsl"
			#include "./SceneObject-Lighting.hlsl"
            #include "./SceneObject-LitCloud.hlsl"
			#include "./ScreenDoorTransparencyHLSL.hlsl"
			#include "./Editor-MinimapHelper.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"


			float3 ViewWSToTS(float3 normalWS, float3 viewDirWS, half4 tangentWS)
			{
				float sgn = tangentWS.w;      // should be either +1 or -1
				float3 bitangent = sgn * cross(normalWS, tangentWS.xyz);
				float3x3 TBN = float3x3(tangentWS.xyz, bitangent.xyz, normalWS);
				float3 viewDirTS = mul(TBN, viewDirWS);
				return viewDirTS;
			}



			half3 LightingIndirectEffect(BRDFData brdfData, half3 normalWS, half3 viewDirectionWS, half3 bakedGI, half ambientAO, TEXTURECUBE_PARAM(cubeMap, sampler_cubeMap)){
				half3 ambient = CalRealtimeAmbient(ambientAO, normalWS);
				
				half3 reflectVector = reflect(-viewDirectionWS, normalWS);
				half NoV = saturate(dot(normalWS, viewDirectionWS));
				half fresnelTerm = Pow4(1.0 - NoV);
				half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
				// half mip = 0;
				half3 reflect = half4(SAMPLE_TEXTURECUBE_LOD(_ReflectCubemap, sampler_ReflectCubemap, reflectVector, mip)).rgb * _ReflectIntensity;
				float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
				reflect = reflect * half3(surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm)) * ambientAO;

				half3 exReflect = half4(SAMPLE_TEXTURECUBE(cubeMap, sampler_cubeMap, reflectVector)).rgb * _CubeColor;

				half3 indirectGI = ambient + bakedGI + reflect;
				return brdfData.albedo * indirectGI + brdfData.albedo * exReflect + brdfData.albedo * fresnelTerm*_RimInten*_CubeColor;
			}

			struct a2v
			{
				float4 vertex    : POSITION; 
				float3 normalOS  : NORMAL;
				float4 tangentOS : TANGENT;
				half4  texcoord  : TEXCOORD0;
				half4  texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos						: SV_POSITION;
				half2 uv						: TEXCOORD1;
				half4 fogFactor					: TEXCOORD2;

				half3 normalWS					: TEXCOORD3;
				float3 positionWS				: TEXCOORD4;
				float3 viewDirWS				: TEXCOORD5;

                half2  lmap	    				: TEXCOORD6;

				half4 tangentWS					: TEXCOORD8;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert(a2v v)
			{
				v2f o = (v2f)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
	
				float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
				
				o.pos = mul(UNITY_MATRIX_VP, positionWS);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);

				//#ifdef _ADDITIONAL_LIGHTS
				o.positionWS	= positionWS.xyz;
				//#endif
				o.viewDirWS = GetCameraPositionWS() - positionWS.xyz;

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				o.normalWS = TransformObjectToWorldNormalForBRG(v.normalOS.xyz, (float3x3) UNITY_MATRIX_M, _ObjectScale.xyz);
			#else
				o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
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

			//half4 frag(v2f i) : SV_Target
			RO_OPAQUE_PIXEL_SHADER_FUNCTION(frag, v2f i)
			{
				UNITY_SETUP_INSTANCE_ID(i);
				LODCrossFade(i.pos, _BrgCrossFadeStart, _BrgCrossFadeSpeed, _CrossFadeStart, _CrossFadeSpeed, _CrossFadeSign);
				ClipScreenDoorTransparency(_SDAlphaTest, _DisplayStartTime, _DisplayInOut, i.positionWS.xyz, i.pos.xy);


				half4 baseColor = tex2D(_MainTex, i.uv);
				baseColor.rgb *= _Color.rgb;
			// 	half4 hlodc = baseColor;
			// 	#if _ALPHATEST_ON
			// 		clip(baseColor.a - _Cutoff);
			// 	#endif

				half3 normalTS;
				half smoothness = 1;
				half specular = 0;
				half3 normalWS = NormalizeNormalPerPixel(i.normalWS);
				if(_EnableNormalMap){
					UnpackNormalData(i.uv, TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), normalTS, smoothness, specular, _NormalScale);
					half3 unpackedNormalWS = UnpackTangentNormal(normalWS, normalTS, i.tangentWS);
					normalWS = unpackedNormalWS;
				}
				smoothness = 1;
				half2 causticUV = (i.positionWS.xy + i.positionWS.z)/128;
				// causticUV = i.uv;
				causticUV += _Time.y*0.005;

				float3 viewDirWS = i.viewDirWS;
				float3 viewDirectionWS = SafeNormalize(viewDirWS);
				float3 viewDirTS = ViewWSToTS(normalWS, viewDirectionWS, i.tangentWS);
				float2 parallaxOffset = ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _ParallaxScale, causticUV);
				causticUV += parallaxOffset;
				half4 causticColor = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, causticUV);
				baseColor.rgb += causticColor.rgb*5;
				// c.rgb = viewDirTS;
				
				LightInfo info = InitLightInfo(i.lmap, normalWS, length(viewDirWS));
				half3 lm = info.lm;
				half ambientAO = info.ambientAO;
			
			float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
			Light mainLight = GetMainLight(shadowCoord);
			#if defined(UNITY_DOTS_INSTANCING_ENABLED) || (LIGHTMAP_ON_NOBRG && LIGHTMAP_ON)
				mainLight.shadowAttenuation *= info.shadow;
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
			
			
				half NdotL = saturate(dot(normalWS, mainLight.direction));
				BRDFData brdfData;
				InitBRDFData(baseColor.rgb, smoothness, specular, brdfData);
			#if LOD_HIGH_SHADER
				half3 directColor = LightingDirect(brdfData, normalWS, viewDirectionWS, mainLight);
				half3 indirectColor = LightingIndirectEffect(brdfData, normalWS, viewDirectionWS, lm.rgb, ambientAO, TEXTURECUBE_ARGS(_CubeMap, sampler_CubeMap));
			#else
				half3 directColor = LightingDirectLOD(brdfData, normalWS, viewDirectionWS, mainLight);
				half3 indirectColor = LightingIndirectLOD(brdfData, normalWS, viewDirectionWS, lm.rgb, ambientAO);
			#endif
				half4 c = 1;
				c.rgb = BlendTerrainColor(i.pos, _TerrainBlendRange, 0, indirectColor, lightColor);
			// 	if(_BaseAlphaType == 1)
			// 		c.rgb = lerp(c.rgb, baseColor.rgb, baseColor.a * _EmissionIntensity);
			// 	else
			// 		c.a = baseColor.a;


				c.rgb = MixFog(c.rgb, i.fogFactor);

			// #if DEBUG_LIGHTMAP
			// 	c.rgb = lm.rgb + ambient;
			// #endif
			#if DEBUG_MINIMAP
			c.rgb = MinimapColor(c.rgb, i.positionWS);
			#endif
				// c.rgb = indirectColor;

				return SubPassOutputColor(c, i.pos.z);
			}
			ENDHLSL
		}
		
		Pass
		{ 
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}
			
			ZWrite On
			ZTest LEqual
			Cull[_Cull]

			HLSLPROGRAM
			#pragma shader_feature _ALPHATEST_ON
			#pragma multi_compile LIT_CRYSTAL
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment
			#include "./SceneObject-LitInput.hlsl"
			#include "./SceneObject-LitShadow.hlsl"
			ENDHLSL
		}
		
		Pass
		{
			Name "Meta"
			Tags{"LightMode" = "Meta"}

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex ROVertexMeta
			#pragma fragment ROFragmentMeta

			#pragma shader_feature _ALPHATEST_ON
			#pragma multi_compile LIT_CRYSTAL

			#include "./MetaSceneObj.hlsl"
			
			ENDHLSL
		}
	}

	CustomEditor "BigCatEditor.SceneObjectGUI"
}
