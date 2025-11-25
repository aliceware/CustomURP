// #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
#include "./SceneObject-LitInput.hlsl"

struct Attributes
{
	float4 positionOS   : POSITION;
	float3 normalOS     : NORMAL;
	float2 uv0          : TEXCOORD0;
	float2 uv1          : TEXCOORD1;
	float2 uv2          : TEXCOORD2;
#ifdef _TANGENT_TO_WORLD
	float4 tangentOS     : TANGENT;
#endif
};

struct Varyings
{
	float4 positionCS   : SV_POSITION;
	float2 uv           : TEXCOORD0;
};



Varyings ROVertexMeta(Attributes input)
{
	Varyings output;
	output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2,
		unity_LightmapST, unity_DynamicLightmapST);
	output.uv = TRANSFORM_TEX(input.uv0, _MainTex);
	return output;
}

half4 ROFragmentMeta(Varyings input) : SV_Target
{
	//half4 albedoAlpha			= SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
	//half alpha					= Alpha(albedoAlpha.a, _Color, _Cutoff);
	half4 albedoAlpha			= tex2D(_MainTex, input.uv);
	half3 albedo				= albedoAlpha.rgb * _Color.rgb*_Color.a;

	//BRDFData brdfData;
	//InitializeBRDFData(albedo, 0, half3(0, 0, 0), 0, alpha, brdfData);

	MetaInput metaInput;
	metaInput.Albedo          = albedo;
	//metaInput.SpecularColor   = 0;
	metaInput.Emission        = 0;

	return MetaFragment(metaInput);  
}