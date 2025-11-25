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
	UNITY_VERTEX_OUTPUT_STEREO
};

///////////////////////////////////////////////////////////////////////////////
//          	   	       Water debug functions                             //
///////////////////////////////////////////////////////////////////////////////

half3 DebugWaterFX(half3 input, half4 waterFX, half screenCoordinate)
{
    input = lerp(input, half3(waterFX.y, 1, waterFX.z), saturate(floor(screenCoordinate + 0.7)));
    input = lerp(input, waterFX.xxx, saturate(floor(screenCoordinate + 0.5)));
    half3 disp = lerp(0, half3(1, 0, 0), saturate((waterFX.www - 0.5) * 4));
    disp += lerp(0, half3(0, 0, 1), saturate(((1-waterFX.www) - 0.5) * 4));
    input = lerp(input, disp, saturate(floor(screenCoordinate + 0.3)));
    return input;
}

///////////////////////////////////////////////////////////////////////////////
//          	   	      Water shading functions                            //
///////////////////////////////////////////////////////////////////////////////

half3 Scattering(half depth)
{
	return SAMPLE_TEXTURE2D(_UnderWaterRamp, sampler_UnderWaterRamp, half2(depth, 0.75h)).rgb;
}

half3 Absorption(half depth)
{
	return SAMPLE_TEXTURE2D(_UnderWaterRamp, sampler_UnderWaterRamp, half2(depth, 0.0h)).rgb;
}

half4 RampColor(half depth)
{
	return SAMPLE_TEXTURE2D(_UnderWaterRamp, sampler_UnderWaterRamp, half2(depth, 0.0h));
}



float2 AdjustedDepth(half2 uvs, float4 additionalData)
{
	// 读取屏幕像素深度，摄像机朝着像素打出一个点到场景的距离，因为关闭了深度写入，所以获得的是视线直射到水背后场景的深度
	float rawD = GET_SUBPASS_LOAD_DEPTH(uvs);
	// float rawD = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_ScreenTextures_linear_clamp, uvs);
	// 采样深度纹理后的值是非线性的（0,1）的值，需要转化成线性的，非线性深度转化成线性深度
	float d = LinearEyeDepth(rawD, _ZBufferParams);
	//return float2(d * additionalData.x - additionalData.y, (rawD * -_ProjectionParams.x) + (1-UNITY_REVERSED_Z));
	// additionalData.x指海岸线深度，additionalData.y指场景深度（两者都针对屏幕空间）
	// _ProjectionParams.x = 1
	// 返回调整后的水深度和深度缓存中的深度
    return float2(d * additionalData.x - additionalData.y, (rawD * -_ProjectionParams.x));

}

float3 WaterDepth(float3 posWS, float4 additionalData, half2 screenCoordinates)// x = seafloor depth, y = water depth
{
	float3 outDepth = 0;
	outDepth.xz = AdjustedDepth(screenCoordinates, additionalData);//水垂直的深度
	outDepth.y = posWS.y;//水面世界坐标高度
	return outDepth;
}

half2 DistortionUVs(half depth, float3 normalWS)
{
    half3 viewNormal = mul((float3x3)GetWorldToHClipMatrix(), -normalWS).xyz;//变换到裁剪空间

    return viewNormal.xz * saturate((depth) * 0.005);//根据深度范围对xz方向扰动，深度越大扰动越多
}

float4 AdditionalData(float3 postionWS)
{
    float4 data = half4(0.0, 0.0, 0.0, 0.0);
    float3 viewPos = TransformWorldToView(postionWS);
	data.x = length(viewPos / viewPos.z);// distance to surface，点视线方向到近裁剪平面的距离，单位长度？
    data.y = length(GetCameraPositionWS().xyz - postionWS); // local position in camera space，水面上的点到摄像机距离
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

    o.uv.xy = v.texcoord; // geo uvs
	float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
	// 统一世界坐标向上
    o.normal = float3(0, 1, 0);
	o.clipPos = mul(UNITY_MATRIX_VP, positionWS);
	// 储存裁剪空间（透视投影之后，透视除法之前）的z坐标：近裁剪平面Near和Far之间的一个值
    o.posWS = float4(positionWS.xyz, o.clipPos.z);
	// 屏幕坐标UV
	o.shadowCoord = ComputeScreenPos(o.clipPos);
	// Additional data


#if defined(_STATIC_WATER)
	float time = 0;
#else
	float time = _Time.y;
#endif

	// Detail UVs// world(pre-waves) stored in zw, 地平面右下运动
    o.uv.zw = o.posWS.xz * 0.1h + time * 0.05h;
	// Geometric UVs stored in xy, 地平面左上运动
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
	// 齐次裁剪深度
	float clipZ = IN.posWS.w;

#if defined(_STATIC_WATER)
	float time = 0;
#else
	float time = _Time.y;
#endif

	float3 viewDir = _WorldSpaceCameraPos - positionWS;
	float4 fogFactor = ComputeLinearFogFactor(positionWS, clipZ);
	float depth = length(viewDir.y);
	half depthMulti = 1 / _MaxDepth;
	half depthRampSampler = depth.x * depthMulti;

	half dist = length(viewDir);//视线长度
	viewDir = SafeNormalize(viewDir);

	// 计算噪声
	// Line37 in CommonUtilities.hlsl of "2D Noise based on Morgan McGuire @morgan3d"
	// 计算随时间偏移的噪声值
	float noiseVal = (noise((positionWS.xz * 0.000005) + time) + noise((positionWS.xz * 0.000001) + time)) * 0.25 + 0.5;
    IN.uv.zw += noiseVal * half2(0.001, 0.001);
    IN.uv.xy += noiseVal * half2(0.002, 0);

    

	// 判断水面方向
	bool underWater = dot(viewDir, IN.normal) < 0;
	if(underWater){
		viewDir.y = -viewDir.y;
	}

	half3 screenCoordinate = IN.clipPos.xyz;//裁剪空间远近裁剪平面
    
	// Depth
	float4 additionalData = AdditionalData(positionWS);
	// float3 depth = WaterDepth(positionWS, additionalData, screenCoordinate.xy);// TODO - hardcoded shore depth UVs
	
	
    
    // Detail waves *2-1上下运动
	half2 detailBump1 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.zw).xy * 2 - 1;
	half2 detailBump2 = SAMPLE_TEXTURE2D(_SurfaceMap, sampler_SurfaceMap, IN.uv.xy).xy * 2 - 1;
	

	half2 detailBump = -(detailBump1 + detailBump2 * 0.5);

	IN.normal += half3(detailBump.x, 0, detailBump.y) * _BumpScale * lerp(2, 1, saturate(depth / 10));
	
	// if(underWater){
	// 	IN.normal = -IN.normal;
	// }
	half totalReflection = TotalInternalReflection(IN.normal, viewDir.xyz);
	//totalReflection = lerp(1, totalReflection, saturate(depth / 5));
	IN.normal = normalize(IN.normal);

	// Lighting
	//计算带阴影衰减的主光源
	Light mainLight = GetMainLight(TransformWorldToShadowCoord(positionWS+half3(detailBump.x, 0, detailBump.y) * _BumpScale));// 采样阴影贴图
	
	half shadow = mainLight.shadowAttenuation;
#if LIGHTMAP_ON
	float4 shadowMask = SAMPLE_SHADOWMASK(IN.lmap+(detailBump.x+detailBump.y)* _BumpScale * 0.02);
	half4 lm = DecodeLightmapForRuntime(SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, IN.lmap));
    // shadow *= shadowMask.r;
    shadow *= lm.a;
#endif
    half3 GI = SampleSH(IN.normal);
	shadow = shadow * 0.5;
	// Foam
	// half3 foamMap = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap,  IN.uv.zw).rgb; //r=thick, g=medium, b=light
	// half depthEdge = saturate(depth.x * 20);
	// half depthAdd = saturate(1 - depth.x * 4) * 0.5;
	// half edgeFoam = saturate((1 - depth.x * 0.5 - 0.25) + depthAdd) * depthEdge;
	// half foamBlendMask = edgeFoam;
	// half foamBlend = smoothstep(1 - _EdgeFoam, 1+1e-7, foamBlendMask);
	// half foamMask = saturate(length(foamMap * foamBlend)-0.1);
	// // Foam lighting
	// half3 foam = foamMask.xxx * (shadow * mainLight.color + GI);

	// Distortion
	half2 distortion = DistortionUVs(depth.x, IN.normal);
	// distortion = DistortionUVs(_MaxDepth, IN.normal);
	depth.x += (distortion.x+distortion.y)*_DepthDistortion;

	// Fresnel
	half hDir = SafeNormalize(-viewDir.xyz + ro_SunDir.xyz );
	half HoN =  saturate(dot(IN.normal, hDir));
	half NoV = saturate(dot(IN.normal, viewDir.xyz));
	half LoV = saturate(dot( viewDir.xyz, ro_SunDir.xyz));
    BRDFData brdfData;
    half alpha = 1;
	float3 offset = (0, 0, 0);
	offset.z += lerp(0, -0.2, saturate(depth / 50));
    InitializeBRDFData(half3(0, 0, 0), 0, half3(1, 1, 1), _Smoothness, alpha, brdfData);
	half3 spec = DirectBDRF(brdfData, IN.normal, mainLight.direction + offset, viewDir) * _UnderWaterSpecular * shadow * mainLight.color; // lightDir采用ro_SunDir使高光夹角更低
	half3 highlights = Highlights(positionWS, 1-_Smoothness, IN.normal, viewDir);
	half3 specular = pow(LoV, _MaxDepth);
	half4 ramp = RampColor(saturate(NoV * depthRampSampler + _RampOffsetInShadow * (saturate(1-shadow))));
	// ramp.rgb = RampColor(saturate(depthRampSampler + _RampOffsetInShadow * (saturate(1-shadow)))) * RampColor(saturate(NoV));
    // sss *= Scattering(depth.x * depthMulti);

	// Reflections
    half3 reflectVector = reflect(-viewDir.xyz, IN.normal);
    half perceptualRoughness = 0;
    half occlusion = 1;
    half3 skyReflection = SAMPLE_TEXTURECUBE(_UnderWaterReflection, sampler_UnderWaterReflection, reflectVector).rgb;
	// half3 underReflection = SAMPLE_TEXTURECUBE(_ReflectionUnderCubemap, sampler_UnderWaterReflection, reflectVector).rgb;
	
	half reflectStrength =  saturate(0.2+shadow) *  _UnderWaterReflectionStrength * lerp(0.5, 1.5, totalReflection);
	half3 reflection = skyReflection * reflectStrength;

	float2 scrUV = IN.clipPos.xy / _ScaledScreenParams.xy;

	// if (underWater){
	// 	scrUV += IN.normal.xy;
	// }
	

	half3 comp = lerp(ramp.rgb,  reflection, saturate(depth / 10));
	// comp = ramp.rgb + spec;
	// comp = ramp.rgb + totalReflection * 20  * _Specular * shadow * mainLight.color;
	
	comp = ramp.rgb + reflection + spec ;
	// half3 comp = ramp.rgb + reflection*reflectStrength + spec;
	//comp = comp + foam * foamMask; 
	// alpha = saturate(lerp(1, 0.95, totalReflection)/* * ramp.a+foamMask*/);
	// alpha = saturate(ramp.a+foamMask);
	half transDist = smoothstep(_TransDistMin, _TransDistMax, dist);
	// alpha *= transDist;
	if(underWater){
		// alpha *= smoothstep(0.5, 1, totalReflection);
		// alpha = 1;
	}
	
	// Fog
	comp.rgb = MixFog(comp.rgb, fogFactor);

	// comp.rgb = fresnelTerm;

#if defined(_DEBUG_FOAM)
	comp.rgb = shadow;
	
#elif defined(_DEBUG_SSS)
	
	comp.rgb = ramp;
	alpha = 1;
#elif defined(_DEBUG_REFLECTION)
	comp.rgb = reflection;
#elif defined(_DEBUG_NORMAL)
    // return half4(IN.normal.x * 0.5 + 0.5, 0, IN.normal.z * 0.5 + 0.5, 1);
	comp.rgb = IN.normal*0.5+0.5;
	alpha = 1;
#elif defined(_DEBUG_FRESNEL)
	comp.rgb = totalReflection;
#elif defined(_DEBUG_WATERDEPTH)
	comp.rgb = saturate(depthRampSampler);
#endif
    half4 color = half4(comp, alpha);
    RO_TRANSPARENT_PIXEL_OUTPUT(color)
}

#endif // WATER_HLSL_INCLUDED