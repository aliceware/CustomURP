#ifndef CARTOON_LIT_AVATAR_OUTLINE_PASS
#define CARTOON_LIT_AVATAR_OUTLINE_PASS


float4 GetNewClipPosWithZOffset(float4 originalPositionCS, float viewSpaceZOffsetAmount)
{
    if(unity_OrthoParams.w == 0)
    {
        ////////////////////////////////
        //Perspective camera case
        ////////////////////////////////
        float2 ProjM_ZRow_ZW = UNITY_MATRIX_P[2].zw;
        float modifiedPositionVS_Z = -originalPositionCS.w + -viewSpaceZOffsetAmount; // push imaginary vertex
        float modifiedPositionCS_Z = modifiedPositionVS_Z * ProjM_ZRow_ZW[0] + ProjM_ZRow_ZW[1];
        originalPositionCS.z = modifiedPositionCS_Z * originalPositionCS.w / (-modifiedPositionVS_Z); // overwrite positionCS.z
        return originalPositionCS;    
    }
    else
    {
        ////////////////////////////////
        //Orthographic camera case
        ////////////////////////////////
        originalPositionCS.z += -viewSpaceZOffsetAmount / _ProjectionParams.z; // push imaginary vertex and overwrite positionCS.z
        return originalPositionCS;
    }
}

float GetCameraFOV()
{
    float t = unity_CameraProjection._m11;
    float Rad2Deg = 180 / 3.1415;
    float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
    return fov;
}

float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
{
    float cameraMulFix;
    if (unity_OrthoParams.w == 0)
    {
        cameraMulFix = abs(positionVS_Z);
        cameraMulFix = saturate(cameraMulFix);
        cameraMulFix *= GetCameraFOV();
    }
    else
    {
        float orthoSize = abs(unity_OrthoParams.y);
        orthoSize = saturate(orthoSize);
        cameraMulFix = orthoSize * 50;
    }

    return cameraMulFix * 0.0001;
}


struct a2v
{   
    float3 positionOS   : POSITION;
    float2 uv           : TEXCOORD0;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    half4 vertexColor   : COLOR0;
};

struct v2f{
    float4 positionCS   :SV_POSITION;
    float2 uv           :TEXCOORD0;
    float3 normalWS     :TEXCOORD1;
    float3 color     :COLOR0;
    half  screendepth               : TEXCOORD2;
};

v2f OutlineVertex(a2v input)
{
    v2f output;

    output.uv = input.uv;

    VertexPositionInputs PositionInputs = GetVertexPositionInputs(input.positionOS);
    half4 outline = SAMPLE_TEXTURE2D_LOD(_OutlineMap, sampler_OutlineMap, input.uv.xy, 0);
    float3 positionWS = PositionInputs.positionWS;
    float3 positionVS = PositionInputs.positionVS;
    float dist = distance(_WorldSpaceCameraPos, positionWS)/unity_CameraProjection._m11;
    dist = clamp(dist, 0.2, 1);
    float outlineExpandAmount = outline.a * _OutlineThickness * dist;//* GetOutlineCameraFovAndDistanceFixMultiplier(positionVS.z);

    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 normalWS = vertexNormalInput.normalWS;
    if(_OutlineType == 2)
    {
        output.normalWS = vertexNormalInput.tangentWS;
    }
    else
    {
        output.normalWS = vertexNormalInput.normalWS;
    }
    output.normalWS = normalize(output.normalWS);

    
    // positionWS += output.normalWS * outlineExpandAmount;
    output.positionCS = TransformWorldToHClip(positionWS + output.normalWS * outlineExpandAmount);

#ifdef _COLORGRADE
    half colorPart = 0;
    half colorGrade = step(0.95, outline.g);
    half4 color = half4(outline.rgb, colorGrade);
    if(colorGrade > 0.5){
        color.r *= 0.4;
        color.g = 0.3;
    }
    color = CalColorGrade(color, colorPart);
    if(colorGrade > 0.5){
        color.rgb = pow(color.rgb, 2.2);
        // color.rgb = RGB2HSV(color.rgb);
        // color.y = lerp(color.y, 1, 0.032);
        // color.z = lerp(color.z, 0, 0.3);
        // color.rgb = HSV2RGB(color.rgb);
        // color.rgb = saturate(color.rgb);
    }
    output.color = color.rgb;
#else
    output.color = outline.rgb;
#endif

    output.screendepth = output.positionCS.z/output.positionCS.w;

    
    #ifdef _VFX_DISSOLVE
        output.positionCS = 0;
    #elif _SCREEN_DOOR_TRANSPARENCY
        output.positionCS = 0;
    #endif



    return output;
}


// half4 frag(v2f input):SV_Target
RO_OPAQUE_PIXEL_SHADER_FUNCTION(OutlineFragment, v2f input)
{
    half4 result = 1;
    result.rgb = _OutlineColor.rgb * input.color;
    float _HitFactor = (_HitFxIntensity > 0.01) ? _HitFxIntensity : saturate((_Time.y - _HitStartTime)/(0.2));
    result.rgb = lerp(result.rgb, _HitFXColor.rgb, (1-_HitFactor));

    half3 lightCol = lerp(_LightOutShadow.xyz, _LightInShadow.xyz, 1 - _AvatarLightColor.a);

    result.rgb *= lerp(1, lightCol, _AvatarLightDir.w);
    result.rgb *= _UIColorMask;
    

    return SubPassOutputColor(result, input.screendepth);
}

#endif