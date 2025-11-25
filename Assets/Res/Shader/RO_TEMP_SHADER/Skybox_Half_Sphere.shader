// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "RO/Skybox/HalfSphere" 
{
	Properties {
		// _Tex ("Albedo", 2D) = "grey" {}
		// [Toggle(_NO_FOG_ON)]_NoFog("No Fog", Float) = 1
		// _HeightFogStart ("HeightFogStart", Range(-0.1, 0.3)) = 0.032
		// _HeightFogEnd ("HeightFogEnd", Range(-0.1, 0.3)) = 0.088
		// _SkyBox_SunColor ("Sun Color", color) = (1, 1, 1, 1)
		// _SkyBox_SunRadius ("Sun Radius", float) = 20
		// _SkyBox_SunLightness ("Sun Lightness", float) = 20
		// _SkyBox_OtherTex("_SkyBoxOtherTex", 2D) = "grey" {}
		// _SkyBox_BlendFactor("_SkyBox_BlendFactor", Range(0, 1)) = 1
	}
	
	SubShader 
		{
		Tags { "Queue"="Geometry+500" "RenderType"="Background"}
		//ZWrite Off
		ZClip  False
	
		Stencil {
			Ref 5
			Comp Always
			Pass Replace
			Fail Keep
		}
	
		Pass {
			Cull Back
			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
			#pragma multi_compile __ FOG_LINEAR
			
			#pragma multi_compile __ RO_OPT_SUBPASS_LOAD 
			#pragma multi_compile __ RO_FORCE_STORE_READ
			#include "Assets/Res/Shader/AtmosphereCommon.hlsl"
			#include "Assets/Res/Shader/ROOPTSubPassLoadUntils.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			uniform sampler2D _SkyBox_Tex;
			uniform half4 _SkyBox_Tex_ST;
			uniform sampler2D _SkyBox_OtherTex;
			uniform half4 _SkyBox_OtherTex_ST;
			uniform half _SkyBox_BlendFactor;
			uniform half4 _SkyBox_SunColor;
			uniform half _SkyBox_SunRadius;
			uniform half _SkyBox_SunLightness;
	
			uniform half _SkyBox_HeightFogStart;
			uniform half _SkyBox_HeightFogEnd;
	
	
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord: TEXCOORD0;
			};
	
			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD0;
				float4 positionWS: TEXCOORD1;
			};
	
			v2f vert (appdata_t v)
			{
				v2f o;
				float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
				o.vertex = mul(UNITY_MATRIX_VP, positionWS);
	
				
	
	#if UNITY_REVERSED_Z
				o.vertex.z = 1.0e-9f;
	#else
				o.vertex.z = o.vertex.w - 1.0e-6f;
	#endif
				o.positionWS = float4(positionWS.xyz, o.vertex.z);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _SkyBox_Tex);
				return o;
			}
	
			RO_OPAQUE_PIXEL_SHADER_FUNCTION (frag, v2f i)
			{
				Light mainlight = GetMainLight();
				float3 lDir = normalize(mainlight.direction);
				float pDotL = dot(lDir, normalize(i.positionWS.xyz));
				float sun = pow(saturate(pDotL), 100 * _SkyBox_SunRadius) * _SkyBox_SunLightness * step(-0.05, lDir.y);
	
				float dayOtherFactor = smoothstep(0, 0.1, lDir.y + 0.1);
				//dayOtherFactor = saturate(lDir.y);
				half4 texDay = tex2D(_SkyBox_Tex, i.texcoord);
				half4 texOther = tex2D(_SkyBox_OtherTex, i.texcoord);
				half3 c = lerp(texOther.rgb, texDay.rgb, _SkyBox_BlendFactor);
				half4 fogFactor = 0;
				fogFactor.x = smoothstep(_SkyBox_HeightFogStart, _SkyBox_HeightFogEnd, i.texcoord.y);
				fogFactor.z = 1;
				c += sun * _SkyBox_SunColor;
				c.rgb = MixFog(c.rgb, fogFactor);
	
				return SubPassOutputColor(half4(c, 1), i.vertex.z);
			}
			ENDHLSL
		}
	}
	
}
	