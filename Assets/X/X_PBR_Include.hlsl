#ifndef WL_PBR_INCLUDE
#define WL_PBR_INCLUDE

#if defined(_CUSTOM_ENV_ON)
#define _GLOBAL_CUBEMAP_ON
#define _AMBIENT_LIGHT_ON
#endif

#if !defined(_GLOBAL_CUBEMAP_ON)
#define _ENVIRONMENTREFLECTIONS_OFF 1
#endif



	#include "XLighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

	sampler2D _BaseMap;
	sampler2D _NormalMap;
	sampler2D _Mask0;
	sampler2D _Mask1;
	sampler2D _Detailmap;
	sampler2D _Emissionmap;

	//#if _TWINKLE_ON
	//	sampler2D _Twinklemap;
	//#endif

	#if _SPARKLE_ON
		sampler2D _SparkleTex;  
	#endif

	samplerCUBE _EnvCubemap;

	#include "CustomLighting.hlsl"

	VertexOutput vert(VertexInput i)
	{
		VertexOutput o = (VertexOutput)0;

		o.uv.xy = TRANSFORM_TEX(i.uv, _BaseMap);
		o.uv.zw = i.uv;
#if defined(_TINT_RGB) || defined(_TINT_RGBA)
		o.uv2 = TRANSFORM_TEX(i.uv2, _GradientMap);
#endif
		VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positionOS.xyz);
		o.positionWS = vertexInput.positionWS;

		VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS, i.tangentOS);
		o.normalWS = float4(normalInput.normalWS, 0);
		o.tangentWS = half4(normalInput.tangentWS, 0);
		o.bitangentWS = half4(normalInput.bitangentWS, 0);
		o.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS.xyz);
		o.positionCS = vertexInput.positionCS;
		o.rimOffsetDir = o.viewDirWS;
		o.shadowCoord = GetShadowCoord( vertexInput );
		return o;
	}

	

	void InitializeInputData(VertexOutput input, half3 normalTS, half face, out CustomInputData inputData)
	{
		inputData = (CustomInputData)0;
		inputData.positionWS = input.positionWS;
		half f = 1;
	#if _BACKFACE_ON
		f = face > 0 ? 1.0f : -1.0f;
	#endif
		inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)) * f;
		inputData.positionWS = input.positionWS;
		inputData.viewDirectionWS = input.viewDirWS;
		//inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
		inputData.shadowCoord = input.shadowCoord;
		inputData.fogCoord = 0;
		inputData.vertexLighting = half3(1, 1, 1);
		inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
		inputData.shadowMask = half4(0, 0, 0, 0);

		inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	}




	half4 frag(VertexOutput input, float facing : VFACE) : SV_Target
	{
		half4 albedoColor = tex2D(_BaseMap, input.uv.xy);
		half4 albedo = albedoColor * _BaseColor;
		
		#if _ALPHATEST_ON
			half alpha = albedo.a;
			clip(alpha - _Cutoff);
		#elif _SURFACE_TYPE_TRANSPARENT
			half alpha = albedo.a;
		#else
			half alpha = 1;
		#endif

		half4 emissionMapColor = tex2D(_Emissionmap, input.uv.xy);
		float4 normalTS = float4(0, 0, 0, 0);
		normalTS.xyz = normalize(UnpackNormalScale(tex2D(_NormalMap, input.uv.xy), _NormalScale));
		normalTS.w = normalTS.z + 1;

		half4 mask2Map = tex2D(_Mask1, input.uv.xy);
		#if _SIMPLE_DETAIL_ON
			float2 detailUV = input.uv.zw * _Detailmap_ST.xy + _Detailmap_ST.zw;
			float3 detailNorTS = UnpackNormalScale(tex2D(_Detailmap, detailUV), _DetailScale);
			detailNorTS = normalize(detailNorTS);
			float3 normalTS2 = normalTS.xyw / normalTS.w;
			float normalFix = dot(normalTS.xyw, detailNorTS);
			detailNorTS = normalFix * normalTS2 - detailNorTS - normalTS.xyz;
			normalTS.xyz += mask2Map.r * detailNorTS;
		#endif

		half4 pbrMask0 = tex2D(_Mask0, input.uv.xy);
		half metallic = _Metallic * pbrMask0.r;
		half smoothness = _Smoothness * pbrMask0.g;

		half occlusion = lerp(1, pbrMask0.b, _Occlusion);
		half specular = _Specular;

		#if _ANISOTROPIC_ON
		specular = _AnisotropicScale * mask2Map.g;
		#endif

		CustomInputData inputData;
		InitializeInputData(input, normalTS.xyz, facing, inputData);

		#if _MAIN_LIGHT_SHADOWS_SCREEN || _MAIN_LIGHT_SHADOWS
			Light mainLight = GetMainLight(inputData.shadowCoord);
		#else
			Light mainLight = GetMainLight();
		#endif

		#ifdef _CUSTOM_ENV_ON
		mainLight.direction = lerp(mainLight.direction,normalize(_CustomLightDir.xyz),_CustomLight);
		#endif

		half f = 1;
		#if _BACKFACE_ON
		f = facing > 0 ? 1.0f : -1.0f;
		#endif
		float3 normalWS = normalize(inputData.normalWS) * f;
		float3 viewDirWS = input.viewDirWS;

		half3 ambient = CalAmbientByNormalWSY(normalWS.y) * 0.3f;
		inputData.bakedGI = ambient.rgb;

		half envReflIntensity = clamp(_EnvReflIntensity, 0.0f, 1.0f);
		inputData.bakedGI *= max(1.0f - 2.2f * envReflIntensity, 0.5f);

		half4 laserColor = ApllyHueColor(albedo, specular, normalWS, inputData.viewDirectionWS, mainLight.direction);
		albedo = lerp(albedo, laserColor, mask2Map.a);

	#if defined(_SPARKLE_ON)
		half3 sparkle = NoiseUVPoint(inputData, mainLight,  input.uv, _Shape, _ShapeSmooth, _Tilling, _Density, _Intensity, _Noise,mask2Map.b);
	#else
	    half3 sparkle = 0;
	#endif

		half4 color = UniversalFragmentPBR(
			inputData,
			albedo.rgb,
			metallic,
			specular,
			smoothness,
			occlusion,
			0,
			sparkle,
			albedo.a,
			_EnvCubemap, _EnvCubemap_HDR, _EnvBackfaceBrightness, _EnvCubemapRotation, _EnvCubemapIntensity,
			input.tangentWS.xyz, input.bitangentWS.xyz,0);

		//校色
		color.rgb = ColorAdjust(color.rgb, _Saturation, _Contrast, _ColorIntensity);

		//阴影
		color = lerp(color*0.4h,color, mainLight.shadowAttenuation);

		color.rgb += emissionMapColor.rgb * _Emission.rgb;
		color.rgb += envReflIntensity * _EnvReflAmbientColor.rgb;

		half3 rimCol = WLRimLight(normalWS, viewDirWS, input.rimOffsetDir) * pbrMask0.a;

		half4 result = half4(color.rgb + rimCol, alpha);

	#ifdef _CUSTOM_HDR_GRADING
		result.rgb = CustomApplyColorGrading(result.rgb, _LutParams.w, TEXTURE2D_ARGS(_ModelToneMappingLUTMap, sampler_LinearClamp), _LutParams.xyz);
	#endif

		

		return result;

	}


#endif//WL_PBR_INCLUDE
