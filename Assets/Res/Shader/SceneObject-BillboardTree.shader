Shader "RO/SceneObject/BilloardTree" 
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
		_Color("Color", Color) = (1, 1, 1, 1)
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_VerticalBillboard("Vertical Billboard", Float) = 1.0
	}

	SubShader
	{
		Tags { "Queue"="AlphaTest+40" }

		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward" }
			Cull Front

			HLSLPROGRAM
			//BRG
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

			#include "./AtmosphereCommon.hlsl"
	
			#pragma target 3.0
			#pragma multi_compile __ FOG_LINEAR
			#pragma multi_compile __ LOCAL_HEIGHT_FOG

			#pragma vertex vert  
			#pragma fragment frag

			sampler2D _MainTex;

			CBUFFER_START(UnityPerMaterial)
			half4 _MainTex_ST;
			half4 _Color;
			half _Cutoff;
			half _VerticalBillboard;
			CBUFFER_END

			struct a2v
			{
				float4	vertex   : POSITION;
				half4	color	 : COLOR;
				float2	uv 		 : TEXCOORD0;
				float2	uv1		 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4	pos			: SV_POSITION;
				float2	uv			: TEXCOORD0;
				half4	fogFactor	: TEXCOORD1;
				float3 	positionWS	: TEXCOORD2;
				float3 	viewDirWS	: TEXCOORD3;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert(a2v v)
			{
				v2f o = (v2f)0;

				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 centerOffset = float3(v.uv1.xy, 0);
				float3 centerOS = v.vertex.xyz + centerOffset.xyz;
				float3 cameraPositionOS = mul(UNITY_MATRIX_I_M, float4(GetCameraPositionWS(), 1)).xyz;
				float3 viewDirOS = cameraPositionOS - centerOS;
				// float3 viewDirOS = mul((float3x3)UNITY_MATRIX_I_M, mul((float3x3)UNITY_MATRIX_I_V, float3(0, 0, 1)));
				viewDirOS.y *= _VerticalBillboard;
				viewDirOS = normalize(viewDirOS);
				float3 upOS;
				float3 rightOS;
				CalcOrthoNormal(viewDirOS, rightOS, upOS);
				float3 bbPosOS = centerOS - (rightOS * centerOffset.x + upOS * centerOffset.y);
				float4 positionWS = mul(UNITY_MATRIX_M, float4(bbPosOS, 1));
				// float4 positionWS = mul(UNITY_MATRIX_M, v.vertex);
				o.positionWS = positionWS.xyz;
				o.viewDirWS = GetCameraPositionWS() - positionWS.xyz;
				o.pos = mul(UNITY_MATRIX_VP, positionWS);
				o.fogFactor = ComputeLinearFogFactor(positionWS.xyz, o.pos.z);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				half4 c = tex2D(_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				clip(c.a - _Cutoff);

				c.rgb = MixFog(c.rgb, i.fogFactor);
				return c;
			}

			ENDHLSL
		}
	}
}
