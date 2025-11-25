#ifndef COMMON_HLSL_INCLUDED
#define COMMON_HLSL_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

uniform half _EnableAmbient;
uniform half4 _LightModel_SkyColor;
uniform half4 _LightModel_GroundColor;
uniform half4 _LightModel_EquatorColor;
uniform half _AOMapIntensity;
uniform half3 _PlayerLocation;
uniform float4 _BigWorldTime;

	half4 DecodeLightMapCommon(half4 color)
	{
		const half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
		return half4(DecodeLightmap(color, decodeInstructions).xyz, color.a);
	}

	half4 DecodeLightmapForEditor(half4 color)
	{
		const half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
		return half4(DecodeLightmap(color, decodeInstructions).xyz, color.a);
	}

	half3 DecodeLightmapForRuntime(half3 color)
	{
		color.rgb *= 4.59f; //(pow(2, 2.2))
		return color;
	}

	half4 DecodeLightmapForRuntime(half4 color)
	{
		color.rgb *= 4.59f;			//(pow(2, 2.2))
		return color;
	}

	inline half3 DecodeEnvironmentHDR(half4 data, half4 decodeInstructions)
	{
		// Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
		half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;

		// If Linear mode is not supported we can skip exponent part
		#if defined(UNITY_COLORSPACE_GAMMA)
			return (decodeInstructions.x * alpha) * data.rgb;
		#else
		#if defined(UNITY_USE_NATIVE_HDR)
			return decodeInstructions.x * data.rgb; // Multiplier for future HDRI relative to absolute conversion.
		#else
			return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * data.rgb;
		#endif
		#endif
	}

	//half Luminance(half3 rgb)
	//{
	//	return dot(rgb, half3(0.22, 0.707, 0.071));
	//}

	half3 DecodeHDR(half4 color)
	{
	#if UNITY_COLORSPACE_GAMMA
		color.xyz *= color.xyz; // �� to linear
	#endif

	#if _USE_RGBM
		return DecodeRGBM(color);
	#else
		return color.xyz;
	#endif
	}

	float3x3 CreateWorldToObjectMatrix(float3x3 objectToWorld, float3 scale)
	{
		float3x3 mat = mul(objectToWorld, float3x3(1 / scale.x, 0, 0, 0, 1 / scale.y, 0, 0, 0, 1 / scale.z));
		float3x3 worldToObject = float3x3(
			mat._m00 / scale.x, mat._m10 / scale.x, mat._m20 / scale.x,
			mat._m01 / scale.y, mat._m11 / scale.y, mat._m21 / scale.y,
			mat._m02 / scale.z, mat._m12 / scale.z, mat._m22 / scale.z);
		return worldToObject;
	}

	float3 TransformObjectToWorldNormalForBRG(float3 normalOS, float3x3 objectToWorld, float3 scale)
	{
		float3x3 worldToObject = CreateWorldToObjectMatrix(objectToWorld, scale);
		return SafeNormalize(mul(normalOS, worldToObject));
	}

	// sRGB
	// real Gamma22ToLinear(real c)
	// {
	// 	return PositivePow(c, 2.2);
	// }

	// real3 Gamma22ToLinear(real3 c)
	// {
	// 	return PositivePow(c.rgb, real3(2.2, 2.2, 2.2));
	// }

	// real4 Gamma22ToLinear(real4 c)
	// {
	// 	return real4(Gamma22ToLinear(c.rgb), c.a);
	// }

	// real LinearToGamma22(real c)
	// {
	// 	return PositivePow(c, 0.454545454545455);
	// }

	// real3 LinearToGamma22(real3 c)
	// {
	// 	return PositivePow(c.rgb, real3(0.454545454545455, 0.454545454545455, 0.454545454545455));
	// }

	// real4 LinearToGamma22(real4 c)
	// {
	// 	return real4(LinearToGamma22(c.rgb), c.a);
	// }

	// // sRGB
	// real SRGBToLinear(real c)
	// {
	// 	real linearRGBLo = c / 12.92;
	// 	real linearRGBHi = PositivePow((c + 0.055) / 1.055, 2.4);
	// 	real linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
	// 	return linearRGB;
	// }

	// real2 SRGBToLinear(real2 c)
	// {
	// 	real2 linearRGBLo = c / 12.92;
	// 	real2 linearRGBHi = PositivePow((c + 0.055) / 1.055, real2(2.4, 2.4));
	// 	real2 linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
	// 	return linearRGB;
	// }

	// real3 SRGBToLinear(real3 c)
	// {
	// 	real3 linearRGBLo = c / 12.92;
	// 	real3 linearRGBHi = PositivePow((c + 0.055) / 1.055, real3(2.4, 2.4, 2.4));
	// 	real3 linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
	// 	return linearRGB;
	// }

	// real4 SRGBToLinear(real4 c)
	// {
	// 	return real4(SRGBToLinear(c.rgb), c.a);
	// }

	// real LinearToSRGB(real c)
	// {
	// 	real sRGBLo = c * 12.92;
	// 	real sRGBHi = (PositivePow(c, 1.0 / 2.4) * 1.055) - 0.055;
	// 	real sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
	// 	return sRGB;
	// }

	// real2 LinearToSRGB(real2 c)
	// {
	// 	real2 sRGBLo = c * 12.92;
	// 	real2 sRGBHi = (PositivePow(c, real2(1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
	// 	real2 sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
	// 	return sRGB;
	// }

	// real3 LinearToSRGB(real3 c)
	// {
	// 	real3 sRGBLo = c * 12.92;
	// 	real3 sRGBHi = (PositivePow(c, real3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
	// 	real3 sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
	// 	return sRGB;
	// }

	// real4 LinearToSRGB(real4 c)
	// {
	// 	return real4(LinearToSRGB(c.rgb), c.a);
	// }

	half rimColor(half3 normal, float3 viewDir)
	{
		half3   viewDir2 = -normalize(half3(viewDir.x, 0, viewDir.z));
		half    value = min(1 - dot(normal, viewDir2), 1);
		return  value;
	}

	half3 Remap(half3 s, half a1, half a2, half b1, half b2)
	{
		s.x = b1 + (s.x - a1) * (b2 - b1) / (a2 - a1);
		s.y = b1 + (s.y - a1) * (b2 - b1) / (a2 - a1);
		s.z = b1 + (s.z - a1) * (b2 - b1) / (a2 - a1);
		s = max(0, s);
		return s;
	}

	half Remap(half s, half a1, half a2, half b1, half b2)
	{
		s = b1 + (s - a1) * (b2 - b1) / (a2 - a1);
		return s;
	}

	void CalFittingSH(half3 normalWS, out half sky, out half equator, out half ground)
	{
		half3 upWS = half3(0,1,0);
		half x = dot(normalWS, upWS);

		// 二次函数拟合SH结果
		half ax2 = 0.156296*x*x;
		half bx = 0.27095*x;
		half c = 0.114394;

		sky = saturate(ax2 + bx + c);
		ground = saturate(ax2 - bx + c);
		equator = 1 - sky - ground;
	}
	
	half3 CalAmbientLight(half3 normalWS)
	{
		half sky, equator, ground;
		CalFittingSH(normalWS, sky, equator, ground);

		return sky * _LightModel_SkyColor.rgb + 
			equator * _LightModel_EquatorColor.rgb + 
			ground * _LightModel_GroundColor.rgb;
	}

	half CalAmbientAO(half3 normalWS)
	{
		half sky, equator, ground;
		CalFittingSH(normalWS, sky, equator, ground);

		return sky * _LightModel_SkyColor.a + 
			equator * _LightModel_EquatorColor.a + 
			ground * _LightModel_GroundColor.a;
		}

	half3 CalRealtimeAmbient(half ao, half3 normalWS)
	{
		half3 res = 0;
		if(_EnableAmbient){
			res.rgb = CalAmbientLight(normalWS)*saturate(ao*_AOMapIntensity);
		}
		return res;
	}

	void LODCrossFadeDitheringTransition(float3 clipPos, float crossFadeStart, float crossFadeSpeed, float crossFadeSign)
	{
		float a = abs(min((_BigWorldTime.y - crossFadeStart) * crossFadeSpeed, 1.0f)) * crossFadeSign;
		half2 uv = clipPos.xy * _DitheringTextureInvSize;
		half d = SAMPLE_TEXTURE2D(_DitheringTexture, sampler_PointRepeat, uv).a;
		d = a - CopySign(d, a);
		clip(d);
	}

	void transparencyClip(float transparencyStart, float transparencyFlag, float4 screenPos)
	{
		// Screen-door transparency: Discard pixel if below threshold.
		float4x4 thresholdMatrix =
		{
			 1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
			13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
			 4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
			16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
		};
		float4x4 thresholdRowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
		float2 pos = (screenPos.xy / screenPos.w) * _ScreenParams.xy;
		pos = frac(pos * float2(0.125, 0.125)) * float2(4, 4);
		float alpha = abs((_Time.y - transparencyStart) * 4 + transparencyFlag);
		clip(alpha - thresholdMatrix[fmod(pos.x, 4)] * thresholdRowAccess[fmod(pos.y, 4)]);
	}

	// 


	//#if _ENABLE_VERTEX_SHADER_SKIN 
	//	#define CB_ANIM_DECLARE						//uniform float4 _BoneMatrix[200*3];

	//	#define GET_BLEND_MATRIX(input) uint vecNum = 3, offset0 = 0, offset1 = 1, offset2 = 2; \
	//			float4 row0 = _BoneMatrix[input.index.x * vecNum + offset0] * input.weight.x; \
	//			float4 row1 = _BoneMatrix[input.index.x * vecNum + offset1] * input.weight.x; \
	//			float4 row2 = _BoneMatrix[input.index.x * vecNum + offset2] * input.weight.x; \
	//			row0 = row0 + _BoneMatrix[input.index.y * vecNum + offset0] * input.weight.y; \
	//			row1 = row1 + _BoneMatrix[input.index.y * vecNum + offset1] * input.weight.y; \
	//			row2 = row2 + _BoneMatrix[input.index.y * vecNum + offset2] * input.weight.y; \
	//			row0 = row0 + _BoneMatrix[input.index.z * vecNum + offset0] * input.weight.z; \
	//			row1 = row1 + _BoneMatrix[input.index.z * vecNum + offset1] * input.weight.z; \
	//			row2 = row2 + _BoneMatrix[input.index.z * vecNum + offset2] * input.weight.z; \
	//			row0 = row0 + _BoneMatrix[input.index.w * vecNum + offset0] * input.weight.w; \
	//			row1 = row1 + _BoneMatrix[input.index.w * vecNum + offset1] * input.weight.w; \
	//			row2 = row2 + _BoneMatrix[input.index.w * vecNum + offset2] * input.weight.w; \
	//			float4x4 boneM44 = float4x4(row0, row1, row2, float4(0.0f, 0.0f, 0.0f, input.weight.x + input.weight.y + input.weight.z + input.weight.w));


	//	#define VS_DECLARE  float4 vertex : POSITION; float4 weight : BLENDWEIGHTS0; uint4 index : BLENDINDICES0;
	//	#define VS_SKINNING(input) GET_BLEND_MATRIX(input); \
	//			input.vertex = mul(boneM44, input.vertex);
	//	#define VS_SKINNING_NORMAL(input) GET_BLEND_MATRIX(input);\
	//			input.vertex = mul(boneM44, input.vertex); \
	//			input.normal = mul((float3x3)boneM44, input.normal);
	//	#define VS_SKINNING_NORMAL_TANGENT(input) GET_BLEND_MATRIX(input); \
	//			input.vertex = mul(boneM44, input.vertex); \
	//			input.normal = mul((float3x3)boneM44, input.normal); \
	//			input.tangent.xyz = mul((float3x3)boneM44, input.tangent.xyz);
	//#else
		#define CB_ANIM_DECLARE
		#define VS_DECLARE			 float4 vertex : POSITION;
		#define VS_SKINNING(input)
		#define VS_SKINNING_NORMAL(input)
		#define VS_SKINNING_NORMAL_TANGENT(input)
	//#endif 

	void CalcOrthoNormal(float3 dir, out float3 right, out float3 up)
	{
		up = abs(dir.y) > 0.999f ? float3(0, 0, 1) : float3(0, 1, 0);
		right = normalize(cross(up, dir));
		up = normalize(cross(dir, right));
	}

#endif
