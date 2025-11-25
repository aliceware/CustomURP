#ifndef WATER_HLSL_INCLUDED
#define WATER_HLSL_INCLUDED

#define SHADOWS_SCREEN 0

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "SceneObject-WaterInput.hlsl"
#include "CommonUtilities.hlsl"
// #include "GerstnerWaves.hlsl"
#include "SceneObject-WaterLighting.hlsl"
#include "SceneBase.hlsl"
#include "./ROOPTSubPassLoadUntils.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                  				Structs		                             //
///////////////////////////////////////////////////////////////////////////////

RO_FRAMEBUFFER_DECLARE_INPUT
struct WaterVertexInput // vert struct
{
	float4	vertex 					: POSITION;		// vertex positions
	float2	texcoord 				: TEXCOORD0;	// local UVs
	float2	texcoord1 				: TEXCOORD1;	// lightmap UVs
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct WaterVertexOutput // fragment struct
{
	float4	uv 						: TEXCOORD0;	// Geometric UVs stored in xy, and world(pre-waves) in zw
	float4	posWS					: TEXCOORD1;	// world position of the vertices
	float3 	normal 					: NORMAL;		// vert normals
	float3 	viewDir 				: TEXCOORD2;	// view direction
	float3	preWaveSP 				: TEXCOORD3;	// screen position of the verticies before wave distortion
	half2 	fogFactorNoise          : TEXCOORD4;	// x: fogFactor, y: noise
	float4	shadowCoord				: TEXCOORD6;	// for ssshadows

	#ifdef LIGHTMAP_ON
		half2 lmap					: TEXCOORD7;
	#endif
	float4	clipPos					: SV_POSITION;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

///////////////////////////////////////////////////////////////////////////////
//          	   	       Water debug functions                             //
///////////////////////////////////////////////////////////////////////////////

half3 DebugWaterFX(half3 input, half4 waterFX, half screenCoord)
{
    input = lerp(input, half3(waterFX.y, 1, waterFX.z), saturate(floor(screenCoord + 0.7)));
    input = lerp(input, waterFX.xxx, saturate(floor(screenCoord + 0.5)));
    half3 disp = lerp(0, half3(1, 0, 0), saturate((waterFX.www - 0.5) * 4));
    disp += lerp(0, half3(0, 0, 1), saturate(((1-waterFX.www) - 0.5) * 4));
    input = lerp(input, disp, saturate(floor(screenCoord + 0.3)));
    return input;
}

///////////////////////////////////////////////////////////////////////////////
//          	   	      Water shading functions                            //
///////////////////////////////////////////////////////////////////////////////

half3 Scattering(half depth)
{
	return SAMPLE_TEXTURE2D(_AbsorptionScatteringRamp, sampler_AbsorptionScatteringRamp, half2(depth, 0.75h)).rgb;
}

half3 Absorption(half depth)
{
	return SAMPLE_TEXTURE2D(_AbsorptionScatteringRamp, sampler_AbsorptionScatteringRamp, half2(depth, 0.0h)).rgb;
}

half4 RampColor(half depth)
{
	return SAMPLE_TEXTURE2D(_AbsorptionScatteringRamp, sampler_AbsorptionScatteringRamp, half2(depth, 0.0h));
}

float2 AdjustedDepth(half2 uvs, float4 additionalData)
{
	float rawD = GET_SUBPASS_LOAD_DEPTH(uvs);
	// float rawD = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_ScreenTextures_linear_clamp, uvs);
	float d = LinearEyeDepth(rawD, _ZBufferParams);
	//return float2(d * additionalData.x - additionalData.y, (rawD * -_ProjectionParams.x) + (1-UNITY_REVERSED_Z));
    return float2(d * additionalData.x - additionalData.y, (rawD * -_ProjectionParams.x));

}

// float3 reconstructPosWS(half2 screenUV){
// 	return reconstructWS;
// }


float3 WaterDepth(float3 posWS, float4 additionalData, half2 screenCoords)// x = seafloor depth, y = water depth
{
	float3 outDepth = 0;
	outDepth.xz = AdjustedDepth(screenCoords, additionalData);
	outDepth.y = posWS.y;
	return outDepth;
}

half2 DistortionUVs(half depth, float3 normalWS)
{
    half3 viewNormal = mul((float3x3)GetWorldToHClipMatrix(), -normalWS).xyz;

    return viewNormal.xz * saturate((depth) * 0.005);
}

float4 AdditionalData(float3 postionWS)
{
    float4 data = half4(0.0, 0.0, 0.0, 0.0);
    float3 viewPos = TransformWorldToView(postionWS);
	data.x = length(viewPos / viewPos.z);// distance to surface
    data.y = length(GetCameraPositionWS().xyz - postionWS); // local position in camera space
	return data;
}



///////////////////////////////////////////////////////////////////////////////
//               	   Vertex and Fragment functions                         //
///////////////////////////////////////////////////////////////////////////////

// Vertex: Used for Standard non-tessellated water
WaterVertexOutput WaterVertex(WaterVertexInput v)
{
    WaterVertexOutput o;
	
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);

	//反向 Z 缓冲反转深度
	#if UNITY_REVERSED_Z
	o.clipPos.z = max(o.clipPos.z, 1.0e-9f);
	#else
	o.clipPos.z = min(o.clipPos.z, o.clipPos.w - 1.0e-6f);
	#endif

    o.uv.xy = v.texcoord; // geo uvs
	float4 positionWS = mul(UNITY_MATRIX_M,v.vertex);
    o.normal = float3(0, 1, 0);
	o.clipPos = mul(UNITY_MATRIX_VP, positionWS);
    o.posWS = float4(positionWS.xyz, o.clipPos.z);
	o.shadowCoord = ComputeScreenPos(o.clipPos);// 齐次裁剪坐标
	// Additional data


#if defined(_STATIC_WATER)
	float time = 0;
#else
	float time = _Time.y;
#endif

	// Detail UVs
    o.uv.zw = o.posWS.xz * 0.1h + time * 0.05h;
    o.uv.xy = o.posWS.xz * 0.4h - time.xx * 0.1h;

#if LIGHTMAP_ON
	o.lmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
    return o;
}

// Fragment for water
// half4 WaterFragment(WaterVertexOutput IN) : SV_Target
RO_TRANSPARENT_PIXEL_SHADER_FUNCTION(WaterFragment, WaterVertexOutput IN)
{
    UNITY_SETUP_INSTANCE_ID(IN);

	
    RO_TRANSPARENT_PIXEL_INPUT;
	// return half4(0,0,1,0.5);
	float3 positionWS = IN.posWS.xyz;
	float clipZ = IN.posWS.w;

#if defined(_STATIC_WATER)
	float time = 0;
#else
	float time = _Time.y;
#endif
	float noiseVal = ((noise((positionWS.xz * 0.5) + time) + noise((positionWS.xz * 1) + time)) * 0.25 - 0.5) + 1;
    IN.uv.zw += noiseVal * 0.1;
    IN.uv.xy += noiseVal * 0.2;
    
    // Detail waves
	half2 detailBump1 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.zw).xy * 2 - 1;
	half2 detailBump2 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.xy).xy * 2 - 1;
	half2 detailBump = (detailBump1 + detailBump2 * 0.5);

	IN.normal += half3(detailBump.x, 0, detailBump.y) * _BumpScale;
	IN.normal = normalize(IN.normal);

    float3 viewDir = _WorldSpaceCameraPos - positionWS;
	float4 fogFactor = ComputeLinearFogFactor(positionWS, clipZ);
	half dist = length(viewDir);
	viewDir = SafeNormalize(viewDir);
	
	// Fresnel
	half fresnelTerm = CalculateFresnelTerm(IN.normal, viewDir.xyz);

	half3 screenCoord = IN.clipPos.xyz;//屏幕坐标，非UV
    
	// Depth
	float4 additionalData = AdditionalData(positionWS);
#if defined(_LODWATER)
	float3 depth = 999999;
#else
	float3 depth = WaterDepth(positionWS, additionalData, screenCoord.xy);// TODO - hardcoded shore depth UVs
#endif
	half depthMulti = 1 / _MaxDepth;

	half depthRampSampler = depth.x * depthMulti;

	// Lighting
	Light mainLight = GetMainLight(TransformWorldToShadowCoord(positionWS+half3(detailBump.x, 0, detailBump.y) * _BumpScale));
	half shadow = mainLight.shadowAttenuation;
#if LIGHTMAP_ON
	float4 shadowMask = SAMPLE_SHADOWMASK(IN.lmap+(detailBump.x+detailBump.y)* _BumpScale * 0.02);
	half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, IN.lmap));
    // shadow *= shadowMask.r;
    shadow *= lm.a;
#endif
    half3 GI = SampleSH(IN.normal);

	// Foam
	half3 foamMap = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap,  IN.uv.zw).rgb; //r=thick, g=medium, b=light
	half depthEdge = saturate(depth.x * 20);
	half depthAdd = saturate(1 - depth.x * 4) * 0.5;
	half edgeFoam = saturate((1 - depth.x * 0.5 - 0.25) + depthAdd) * depthEdge;
	half foamBlendMask = edgeFoam;
	half foamBlend = smoothstep(1 - _EdgeFoam, 1+1e-7, foamBlendMask);
	half foamMask = saturate(length(foamMap * foamBlend)-0.1);
	// Foam lighting
	half3 foam = foamMask.xxx * (shadow * mainLight.color + GI);

    BRDFData brdfData;
    half alpha = 1;
    InitializeBRDFData(half3(0, 0, 0), 0, half3(1, 1, 1), _Smoothness, alpha, brdfData);// albedo, metallic, specular, smoothness, alpha
	half3 spec = DirectBDRF(brdfData, IN.normal, mainLight.direction, viewDir) * _Specular * shadow * mainLight.color; // lightDir采用ro_SunDir使高光夹角更低
	half3 highlights = Highlights(positionWS, 1-_Smoothness, IN.normal, viewDir);
	

	// Distortion
	float2 screenUV = IN.clipPos.xy / _ScaledScreenParams.xy;
	float noiseScr = ((noise((positionWS.xz * 0.5) + time) + noise((positionWS.xz * 1) + time)) * 0.25 - 0.5) + 1;
	float reflectionDisturbMask = (1 - fresnelTerm) * ((1 - screenUV)* 0.5 + 0.5);
	float2 disturbedScreenUV = screenUV + lerp(0, noiseScr * 0.05, reflectionDisturbMask);
	float noiseRefraction =  (detailBump.x + detailBump.y) * 0.2;
	float depthDistortion = depthRampSampler * _DepthDistortion;
	depthDistortion = min(depthDistortion, 0.3);
	float2 disturb = lerp(0, noiseRefraction, (1 - fresnelTerm) * depthDistortion * ((1 - screenUV)* 0.5 + 0.5));
	float2 disturbScrUV = screenUV + disturb;
	float2 refractUV = disturbScrUV;
	
	float refrectRawD = GET_SUBPASS_LOAD_DEPTH(refractUV * _ScaledScreenParams.xy);
	float3 refractPositionWS = ComputeWorldSpacePosition(refractUV, refrectRawD, UNITY_MATRIX_I_VP);

	bool trueRefract = refractPositionWS.y > positionWS.y; // 偏移的目标必须是水下
	refractUV = trueRefract ? screenUV : disturbScrUV;
	float refractDepth = LinearEyeDepth(refrectRawD, _ZBufferParams);
	refractDepth = refractDepth * additionalData.x - additionalData.y;
	depth.x = trueRefract ? depth.x : refractDepth;
	depthRampSampler = depth.x * depthMulti;
	refractUV = refractUV * _ScaledScreenParams.xy;


	half4 ramp = RampColor(saturate(depthRampSampler));
	ramp.rgb = RampColor(saturate(depthRampSampler + _RampOffsetInShadow * saturate(1-shadow))) * mainLight.color;
	//ramp.rgb *= saturate(shadow * 0.5 + 0.5);
    // sss *= Scattering(depth.x * depthMulti);

	alpha = saturate(fresnelTerm * 0.1+ramp.a+foamMask);
	// alpha = saturate(ramp.a+foamMask);
	half transDist = smoothstep(_TransDistMax, _TransDistMin, dist);

	// Reflections
	IN.normal = lerp(half3(0,1,0), IN.normal, 0.2);
    half3 reflectVector = reflect(-viewDir.xyz, IN.normal);
    half perceptualRoughness = 0;
    half occlusion = 1;
    half3 reflectionCubemap = SAMPLE_TEXTURECUBE(_ReflectionCubemap, sampler_ReflectionCubemap, reflectVector).rgb;
	half4 reflectionSSPR = SAMPLE_TEXTURE2D(_ReflectionTexture, sampler_ReflectionTexture, disturbedScreenUV);
	half reflectionRate = reflectionSSPR.a;
	half3 reflection = saturate(reflectionSSPR.rgb) + reflectionCubemap * (1 - reflectionRate);
	half reflectStrength = fresnelTerm * _ReflectionStrength * saturate(0.2+shadow);

	half3 refraction = GET_SUBPASS_LOAD_COLOR(refractUV);
	half3 comp = ramp.rgb + lerp(0, reflection, reflectStrength) + spec;

	comp = comp + foam * foamMask; 
	comp = alpha * comp + (1 - alpha) * refraction;
	
	
	// Fog
	comp.rgb = MixFog(comp.rgb, fogFactor);

	// comp.rgb = refractPositionWS.y > positionWS.y;

#if defined(_DEBUG_FOAM)
	comp.rgb = foam;
	
#elif defined(_DEBUG_SSS)
    comp.rgb = ramp;
	alpha = 1;
#elif defined(_DEBUG_REFLECTION)
	comp.rgb = reflection;
#elif defined(_DEBUG_REFRACTION)
	comp.rgb = refraction;
	//comp.rgb = reconstructPosWS(screenUV);
	// comp.rgb = IN.posWS.xyz;
	alpha = 1;
#elif defined(_DEBUG_NORMAL)
    // return half4(IN.normal.x * 0.5 + 0.5, 0, IN.normal.z * 0.5 + 0.5, 1);
	comp.rgb = IN.normal*0.5+0.5;
	alpha = 1;
#elif defined(_DEBUG_FRESNEL)
	comp.rgb = fresnelTerm.xxx;
#elif defined(_DEBUG_WATERDEPTH)
	comp.rgb = saturate(depthRampSampler);
	alpha = 1;
#endif
    half4 color = half4(comp, transDist);
	//color.rgb = reflection.rgb;
	//color.a = 1;
	// color = tex2D(_ReflectionTexture, IN.uv);
    RO_TRANSPARENT_PIXEL_OUTPUT(color)
}

#endif // WATER_HLSL_INCLUDED