Shader "RO/Effect/FXCommonDecal"{
    Properties{
        [HDR] _Color ("Tint", Color) = (0, 0, 0, 1)
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader{
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent-400"  "DisableBatching"="True"}

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite off

        Pass{
            HLSLPROGRAM

            #include "./CommonHLSL.hlsl"

            //define vertex and fragment shader functions
            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            half4 _Color;

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            //the mesh data thats read by the vertex shader
            struct appdata{
                float4 positionOS : POSITION;
            };

            //the data thats passed from the vertex to the fragment shader and interpolated by the rasterizer
            struct v2f{
                float4 positionCS : SV_POSITION;
                float4 positionNDC : TEXCOORD0;
                float3 ray : TEXCOORD1;
            };

            //the vertex shader function
            v2f vert(appdata IN){
                v2f o;
                VertexPositionInputs PositionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                float3 positionWS = PositionInputs.positionWS;
                o.positionCS = PositionInputs.positionCS;
                o.positionNDC = PositionInputs.positionNDC;

                o.ray = positionWS - _WorldSpaceCameraPos;
                return o;
            }

            float3 getProjectedObjectPos(float2 screenPos, float3 worldRay){
                //get depth from depth texture
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos);
                // float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
                depth = Linear01Depth (depth,_ZBufferParams) * _ProjectionParams.z;
                //get a ray thats 1 long on the axis from the camera away (because thats how depth is defined)
                worldRay = normalize(worldRay);
                //the 3rd row of the view matrix has the camera forward vector encoded, so a dot product with that will give the inverse distance in that direction
                worldRay /= dot(worldRay, -UNITY_MATRIX_V[2].xyz);
                //with that reconstruct world and object space positions
                float3 worldPos = _WorldSpaceCameraPos + worldRay * depth;
                float3 objectPos =  mul (unity_WorldToObject, float4(worldPos,1)).xyz;
                //discard pixels where any component is beyond +-0.5
                clip(0.5 - abs(objectPos));
                //get -0.5|0.5 space to 0|1 for nice texture stuff if thats what we want
                objectPos += 0.5;
                return objectPos;
            }

            //the fragment shader function
            half4 frag(v2f i) : SV_TARGET{
                //unstretch screenspace uv and get uvs from function
                float4 scrPos = i.positionNDC;
                float2 screenPos = scrPos.xy / scrPos.w;
                float2 uv = getProjectedObjectPos(screenPos, i.ray).xz;
              //read the texture color at the uv coordinate
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                //multiply the texture color and tint color
                col *= _Color;
                //return the final color to be drawn on screen
                return col;
            }

            ENDHLSL
        }
    }
}