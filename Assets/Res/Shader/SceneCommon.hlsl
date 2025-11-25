#ifndef SceneCommon
#define SceneCommon
#include "./AtmosphereCommon.hlsl"

uniform float3 _LightDirection;
uniform half4 _LightModel_Ambient;


half3 GetMainLightResult(half3 lm, float4 shadowCoord, half3 normalWS)
{
	Light mainLight = GetMainLight(shadowCoord);
	float shadowAttenuation = mainLight.shadowAttenuation;
    // float shadowAttenuation = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord);
    // float shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
    // float shadowStrength = GetMainLightShadowStrength();
    // shadowAttenuation = lerp(1, shadowAttenuation, shadowStrength);

	half NdotL = saturate(dot(normalWS, mainLight.direction));
	half3 lightColor = mainLight.color*shadowAttenuation;
	half3 radiance = lightColor * NdotL;
	half3 outPut = radiance + lm;
	#ifdef LIGHTMAP_ON
		outPut = lm * min(shadowAttenuation + 0.5, 1);
	#endif
	return outPut;
}

half GGX(half NoH, half ref)
{
	half d = 1.0h - NoH * NoH;
	half a = ref * ref;
	half n = NoH * a;
	half p = a / (d + n * n);
	half specularTerm = (p * p);
	return specularTerm;
}

half3 GetMainLightResultMetal(half3 lm, float4 shadowCoord, half3 normalWS, half3 viewDirectionWS)
{
	half shadowAttenuation = 1;
	#if defined(_MAIN_LIGHT_SHADOWS)
		Light mainLight = GetMainLight(shadowCoord);
		shadowAttenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
	#else
		Light mainLight = GetMainLight();
	#endif

	half  NdotL = saturate(dot(normalWS, mainLight.direction));
	half3 radiance = mainLight.color* (shadowAttenuation)* NdotL;
	half3 outPut = radiance  + lm;
	//GGX
	half3 halfDir = normalize(mainLight.direction + viewDirectionWS);
	half  NoH = saturate(dot(normalWS, halfDir));
	half  specularTerm = GGX(NoH, 0.4);
	outPut += specularTerm* radiance;
	
	return outPut;
}

half3 GetAddLightResult(half3 inColor, float3 positionWS, half3 normalWS)
{
	half3 outPut = inColor;
	uint pixelLightCount = GetAdditionalLightsCount();
	for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
	{
		Light light = GetAdditionalLight(lightIndex, positionWS);
		half NdotL = saturate(dot(normalWS, light.direction));
		half3 radiance = light.color *light.distanceAttenuation* NdotL;
		outPut += radiance;
	}
	return outPut;
}
			
#ifdef BAKE_SKIN_ANIM
sampler2D _AnimTex0;
sampler2D _AnimTex1;
sampler2D _AnimTex2;

float RandomSeed(float3 n)
{
	return frac(sin(n.x + n.y + n.z) * 43758.5453);
}

inline float4x4 CreateMatrix(float boneId, float timeOffset, float frameRate)
{
	float time = frac(_Time.y*frameRate + timeOffset);
	float4 row0 = tex2Dlod(_AnimTex0, float4(time, boneId, 0, 0))*2-1;
	float4 row1 = tex2Dlod(_AnimTex1, float4(time, boneId, 0, 0))*2-1;
	float4 row2 = tex2Dlod(_AnimTex2, float4(time, boneId, 0, 0))*2-1;

	float4x4 reconstructedMatrix = float4x4(row0, row1, row2, float4(0, 0, 0, 1));

	return reconstructedMatrix;
}

inline float4x4 CalculateSkinMatrix(float2 boneIds, float2 boneInfluences, float timeOffset, float frameRate)
{
	float4x4 frame_BoneMatrix0 = CreateMatrix(boneIds.x, timeOffset, frameRate);
	float4x4 frame_BoneMatrix1 = CreateMatrix(boneIds.y, timeOffset, frameRate);
	float4x4 frame_BoneMatrix = frame_BoneMatrix0 * boneInfluences.x + frame_BoneMatrix1 * boneInfluences.y;
	return frame_BoneMatrix;
}
#endif

#endif
