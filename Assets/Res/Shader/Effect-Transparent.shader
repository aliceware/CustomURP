Shader "RO/Effect/Transparent" {
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
		_TintColor("Tint Color", Color) = (1,1,1,1)
		_Exposure("Exposure", Range(0.0, 10.0)) = 1.0

		[HideInInspector] _MaskTex("Mask", 2D) = "white" {}

		// _MainTexUVSpeed.w: 0:_UV_ANIMATION_OFF 1:_UV_ANIMATION_ON
		[HideInInspector] _MainTexUVSpeed("Main Tex UV Speed", Vector) = (0,0,0,0)
		// _MaskTexUVSpeed.z: 0:_MASK_ON 1:_MASK_OFF	_UV_ANIMATION_ON.w: 0:_UV_ANIMATION_ON 1:_UV_ANIMATION_OFF
		[HideInInspector] _MaskTexUVSpeed("Mask Tex UV Speed", Vector) = (0,0,0,0)

		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 5.0
		[HideInInspector] _DstBlend("__dst", Float) = 1.0
		[HideInInspector] _ZWrite1("__zw", Float) = 0.0
		[HideInInspector] _Cull("__cull", Float) = 0.0

		[Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("ZTest", Int) = 4//2017.4 : False,Never,Less,E,LE,G,NotE,GE,Always
		_Offset("_Offset", Range(-10.0, 1.0)) = 0

		//扰动
		_NoiseTex("_Noise", 2D) = "white" {}
		_NoiseTexUVSpeed("_Noise Tex UV Speed", Vector) = (0,0,0,0)

		//溶解
		_Dis("_Dis", Range(0, 1.00)) = 0
		_DisColor("_DisColor", Color) = (0,0,0,0)
		_ExposureDis("_ExposureDis", Range(0.0, 10.0)) = 1.0
		_DisSmooth("_DisSmooth",Range(0, 10.0)) = 10.0
		_DisTexUVSpeed("_Dis Tex UV Speed", Vector) = (0,0,0,0)
	}

		SubShader
			{
				Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
				Pass
				{
					Blend[_SrcBlend][_DstBlend]
					ZWrite[_ZWrite1] Lighting Off
					Cull[_Cull]
					ZTest[_ZTest]
					AlphaTest Greater 0.01
					ColorMask RGBA
					Offset[_Offset], 1

					Name "ForwardLit"
					Tags { "LightMode" = "UniversalForward" }

           

					HLSLPROGRAM
					#pragma vertex vert  
					#pragma fragment frag
					// #pragma multi_compile __ _ADDITIVE_ON
					#pragma multi_compile __ FOG_LINEAR

					#include "./AtmosphereCommon.hlsl"
					uniform sampler2D _MainTex;
					uniform sampler2D _MaskTex;
					uniform sampler2D _NoiseTex;

					CBUFFER_START(UnityPerMaterial)
					uniform half4 _MainTex_ST;
					uniform half4 _MaskTex_ST;
					uniform half4 _NoiseTex_ST;

					uniform half4 _MainTexUVSpeed;
					uniform half4 _MaskTexUVSpeed;
					uniform half4 _NoiseTexUVSpeed;
					uniform half4 _DisTexUVSpeed;

					uniform half4 _TintColor;
					uniform half  _Exposure;
					uniform half  _Dis;
					uniform half4 _DisColor;
					uniform half  _DisSmooth;
					uniform half  _ExposureDis;
					uniform half _Mode;
					CB_ANIM_DECLARE
					CBUFFER_END


					struct appdata_effect
					{
						VS_DECLARE
						float4 texcoord : TEXCOORD0;
						half4 color : COLOR;
					};

					struct v2f
					{
						float4 pos : SV_POSITION;
						float2 uv : TEXCOORD0;
						half2 maskUV : TEXCOORD1;

						half4 color   : COLOR;
						float2 noiseUV : TEXCOORD2;
						half2 disUV : TEXCOORD3;
						half4 fogFactor : TEXCOORD4;
					};

					v2f vert(appdata_effect v)
					{
						VS_SKINNING(v)
						v2f o;
						float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
						o.pos = mul(UNITY_MATRIX_VP, positionWS);
						o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
						float deltaTime = _Time.y % 100.0f;

						if (_MainTexUVSpeed.w > 0)
						{
							o.uv.x += deltaTime * _MainTexUVSpeed.x;
							o.uv.y += deltaTime * _MainTexUVSpeed.y;
						}

						if (_MaskTexUVSpeed.z > 0)
						{
							o.maskUV = TRANSFORM_TEX(v.texcoord, _MaskTex);

							if (_MaskTexUVSpeed.w > 0)
							{
								o.maskUV.x += deltaTime * _MaskTexUVSpeed.x;
								o.maskUV.y += deltaTime * _MaskTexUVSpeed.y;
							}
						}

						if (_NoiseTexUVSpeed.w > 0)
						{
							o.noiseUV = TRANSFORM_TEX(v.texcoord, _NoiseTex);
							o.noiseUV += deltaTime * _NoiseTexUVSpeed.xy;
						}

						if (_DisTexUVSpeed.w > 0)
						{
							o.disUV = TRANSFORM_TEX(v.texcoord, _NoiseTex);
							o.disUV += deltaTime * _DisTexUVSpeed.xy;
						}

						o.color = v.color;
						o.color.rgb = o.color.rgb*_TintColor.rgb*_Exposure;

						o.fogFactor = _Mode > 0 ? ComputeLinearFogFactor(positionWS.xyz, o.pos.z) : 1;
						
						return o;
					}

					half4 frag(v2f i) : COLOR
					{
						float2 mainUV = i.uv;

						if (_NoiseTexUVSpeed.w > 0)
						{
							float noiseUV = tex2D(_NoiseTex, i.noiseUV).r;
							mainUV = mainUV + noiseUV * _NoiseTexUVSpeed.w;
						}

						half4 c = tex2D(_MainTex, mainUV);
						half3 inColor = i.color.rgb;

						if (_MaskTexUVSpeed.z > 0)
						{
							c.a *= tex2D(_MaskTex, i.maskUV).r;
						}

						if (_DisTexUVSpeed.w > 0)
						{
							half disValue = (tex2D(_NoiseTex, i.disUV).r + _DisTexUVSpeed.z) / max((1 + _DisTexUVSpeed.z), 0.001);

							float sourceValue = i.color.a * disValue - _Dis;
							clip(sourceValue);

							if (_DisColor.w > 0)
							{
								if (sourceValue < _DisColor.w)
								{
									inColor = _DisColor.xyz * _ExposureDis;
								}
							}

							if (_DisSmooth < 10)
							{
								disValue = smoothstep(0, max(1 - _Dis, 0.001), sourceValue);
								c.a *= saturate(disValue * _DisSmooth);
								c.a *= _ExposureDis;
							}
						}
						else
						{
							c.a *= i.color.a * _Exposure;
						}
						c.a *= _TintColor.a;
						c.xyz = c.xyz * inColor;

					c.rgb = MixFog(c.rgb, i.fogFactor);
						return c;
					}

					ENDHLSL
				}
			}
				CustomEditor "EffectShaderGUI"
}
