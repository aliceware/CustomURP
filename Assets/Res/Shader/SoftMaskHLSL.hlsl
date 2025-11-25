#ifndef SOFTMASK_INCLUDED
#define SOFTMASK_INCLUDED

/*  API Reference
    -------------

    #define SOFTMASK_COORDS(idx)
        Add it to the declaration of the structure that is passed from the vertex shader
        to the fragment shader.
          idx    The number of interpolator to use. Specify the first free TEXCOORD index.

    #define SOFTMASK_CALCULATE_COORDS(OUT, pos)
        Use it in the vertex shader to calculate mask-related data.
          OUT    An instance of the output structure that will be passed to the fragment
                 shader. It should be of the type that contains a SOFTMASK_COORDS()
                 declaration.
          pos    A source vertex position that have been passed to the vertex shader.

    #define SOFTMASK_GET_MASK(IN)
        Use it in the fragment shader to finally compute the mask value.
          IN     An instance of the vertex shader output structure. It should be of type
                 that contains a SOFTMASK_COORDS() declaration.

  The following functions are defined only when one of SOFTMASK_SIMPLE, SOFTMASK_SLICED
  or SOFTMASK_TILED macro is defined. It's better to use the macros listed above when
  possible because they properly handle situation when Soft Mask is disabled.

    inline float SoftMask_GetMask(float2 maskPosition)
        Returns the mask value for a given pixel.
          maskPosition   A position of the current pixel in mask's local space.
                         To get this position use macro SOFTMASK_CALCULATE_COORDS().

    inline float4 SoftMask_GetMaskTexture(float2 maskPosition)
        Returns the color of the mask texture for a given pixel. maskPosition is the same
        as in SoftMask_GetMask(). This function returns the original pixel of the mask,
        which may be useful for debugging.
*/

#if defined(SOFTMASK_SIMPLE) || defined(SOFTMASK_SLICED) || defined(SOFTMASK_TILED)
#   define __SOFTMASK_ENABLE
#   if defined(SOFTMASK_SLICED) || defined(SOFTMASK_TILED)
#       define __SOFTMASK_USE_BORDER
#   endif
#endif

#if defined(SOFTMASK_SIMPLE_PARENT) || defined(SOFTMASK_SLICED_PARENT) || defined(SOFTMASK_TILED_PARENT)
#   define __SOFTMASK_ENABLE_PARENT
#   if defined(SOFTMASK_SLICED_PARENT) || defined(SOFTMASK_TILED_PARENT)
#       define __SOFTMASK_USE_BORDER_PARENT
#   endif
#endif

#if defined(__SOFTMASK_ENABLE) || defined(__SOFTMASK_ENABLE_PARENT)

inline float2 __SoftMask_Inset(float2 a, float2 a1, float2 a2, float2 u1, float2 u2, float2 repeat) {
    float2 w = (a2 - a1);
    float2 d = (a - a1) / w;
    // use repeat only when both w and repeat are not zeroes
    return lerp(u1, u2, (w * repeat != 0.0f ? frac(d * repeat) : d));
}

inline float2 __SoftMask_Inset(float2 a, float2 a1, float2 a2, float2 u1, float2 u2) {
    float2 w = (a2 - a1);
    return lerp(u1, u2, (w != 0.0f ? (a - a1) / w : 0.0f));
}
#endif

#ifdef __SOFTMASK_ENABLE

# define SOFTMASK_COORDS(idx)                  float4 maskPosition : TEXCOORD ## idx;
# define SOFTMASK_CALCULATE_COORDS(OUT, pos)   (OUT).maskPosition = mul(_SoftMask_WorldToMask, pos) ;
# define SOFTMASK_GET_MASK(IN)                 SoftMask_GetMask((IN).maskPosition.xy)

    sampler2D _SoftMask;
    float4 _SoftMask_Rect;
    float4 _SoftMask_UVRect;
    float4x4 _SoftMask_WorldToMask;
    float4 _SoftMask_ChannelWeights;
# ifdef __SOFTMASK_USE_BORDER
    float4 _SoftMask_BorderRect;
    float4 _SoftMask_UVBorderRect;
# endif
# ifdef SOFTMASK_TILED
    float2 _SoftMask_TileRepeat;
# endif
    bool _SoftMask_InvertMask;
    bool _SoftMask_InvertOutsides;

    // On changing logic of the following functions, don't forget to update
    // according functions in SoftMask.MaterialParameters (C#).

# ifdef __SOFTMASK_USE_BORDER
    inline float2 __SoftMask_XY2UV(
            float2 pos,
            float2 rectXY, float2 bordRectXY, float2 bordRectZW, float2 rectZW,
            float2 uvRectXY, float2 uvBorderRectXY, float2 uvBorderRecZW, float2 uvRectZW) {
        float2 s1 = step(bordRectXY, pos);
        float2 s2 = step(bordRectZW, pos);
        float2 s1i = 1 - s1;
        float2 s2i = 1 - s2;
        float2 s12 = s1 * s2;
        float2 s12i = s1 * s2i;
        float2 s1i2i = s1i * s2i;
        float2 aa1 = rectXY * s1i2i + bordRectXY * s12i + bordRectZW * s12;
        float2 aa2 = bordRectXY * s1i2i + bordRectZW * s12i + rectZW * s12;
        float2 uu1 = uvRectXY * s1i2i + uvBorderRectXY * s12i + uvBorderRecZW * s12;
        float2 uu2 = uvBorderRectXY * s1i2i + uvBorderRecZW * s12i + uvRectZW * s12;
        return
            __SoftMask_Inset(pos, aa1, aa2, uu1, uu2
#   if SOFTMASK_TILED
                , s12i * _SoftMask_TileRepeat
#   endif
            );
    }

    inline float2 SoftMask_GetMaskUV(float2 maskPosition) {
        return
            __SoftMask_XY2UV(
                maskPosition,
                _SoftMask_Rect.xy, _SoftMask_BorderRect.xy, _SoftMask_BorderRect.zw, _SoftMask_Rect.zw,
                _SoftMask_UVRect.xy, _SoftMask_UVBorderRect.xy, _SoftMask_UVBorderRect.zw, _SoftMask_UVRect.zw);
    }
# else
    inline float2 SoftMask_GetMaskUV(float2 maskPosition) {
        return
            __SoftMask_Inset(
                maskPosition,
                _SoftMask_Rect.xy, _SoftMask_Rect.zw, _SoftMask_UVRect.xy, _SoftMask_UVRect.zw);
    }
# endif
    inline float4 SoftMask_GetMaskTexture(float2 maskPosition) {
        return tex2D(_SoftMask, SoftMask_GetMaskUV(maskPosition));
    }

    inline float SoftMask_GetMask(float2 maskPosition) {
        //@horatio  scale into rect subPixel
        if(maskPosition.y < _SoftMask_Rect.y)
            maskPosition.y += 0.6;
        if(maskPosition.y > _SoftMask_Rect.w)
            maskPosition.y -= 0.6;
        if(maskPosition.x < _SoftMask_Rect.x)
            maskPosition.x += 0.6;
        if(maskPosition.x > _SoftMask_Rect.z)
            maskPosition.x -= 0.6;
        float2 uv = SoftMask_GetMaskUV(maskPosition);
        float4 sampledMask = tex2D(_SoftMask, uv);
        float weightedMask = dot(sampledMask * _SoftMask_ChannelWeights, 1);
        float maskInsideRect = _SoftMask_InvertMask ? 1 - weightedMask : weightedMask;
        float maskOutsideRect = _SoftMask_InvertOutsides;
        // float isInsideRect = UnityGet2DClipping(maskPosition, _SoftMask_Rect);
        float2 inside = step(_SoftMask_Rect.xy, maskPosition.xy) * step(maskPosition.xy, _SoftMask_Rect.zw);
        float isInsideRect = inside.x * inside.y;
        return lerp(maskOutsideRect, maskInsideRect, isInsideRect);
    }
#else // __SOFTMASK_ENABLED

# define SOFTMASK_COORDS(idx)
# define SOFTMASK_CALCULATE_COORDS(OUT, pos)
# define SOFTMASK_GET_MASK(IN)                 (1.0f)

    inline float4 SoftMask_GetMaskTexture(float2 maskPosition) { return 1.0f; }
    inline float SoftMask_GetMask(float2 maskPosition) { return 1.0f; }
#endif


//--------------------------------------------------------------------------------------------Parent
#ifdef __SOFTMASK_ENABLE_PARENT

# define SOFTMASK_COORDS_PARENT(idx)                  float4 maskPosition_PARENT : TEXCOORD ## idx;
# define SOFTMASK_CALCULATE_COORDS_PARENT(OUT, pos)   (OUT).maskPosition_PARENT = mul(_SoftMask_WorldToMask_PARENT, pos);
# define SOFTMASK_GET_MASK_PARENT(IN)                 SoftMask_GetMask_PARENT((IN).maskPosition_PARENT.xy)

    sampler2D _SoftMask_PARENT;
    float4 _SoftMask_Rect_PARENT;
    float4 _SoftMask_UVRect_PARENT;
    float4x4 _SoftMask_WorldToMask_PARENT;
    float4 _SoftMask_ChannelWeights_PARENT;
# ifdef __SOFTMASK_USE_BORDER_PARENT
    float4 _SoftMask_BorderRect_PARENT;
    float4 _SoftMask_UVBorderRect_PARENT;
# endif
# ifdef SOFTMASK_TILED_PARENT
    float2 _SoftMask_TileRepeat_PARENT;
# endif
    bool _SoftMask_InvertMask_PARENT;
    bool _SoftMask_InvertOutsides_PARENT;

    // On changing logic of the following functions, don't forget to update
    // according functions in SoftMask.MaterialParameters (C#).

# ifdef __SOFTMASK_USE_BORDER_PARENT
    inline float2 __SoftMask_XY2UV_PARENT(
            float2 a,
            float2 rectXY, float2 bordRectXY, float2 bordRectZW, float2 rectZW,
            float2 uvRectXY, float2 uvBorderRectXY, float2 uvBorderRecZW, float2 uvRectZW) {
        float2 s1 = step(bordRectXY, a);
        float2 s2 = step(bordRectZW, a);
        float2 s1i = 1 - s1;
        float2 s2i = 1 - s2;
        float2 s12 = s1 * s2;
        float2 s12i = s1 * s2i;
        float2 s1i2i = s1i * s2i;
        float2 aa1 = rectXY * s1i2i + bordRectXY * s12i + bordRectZW * s12;
        float2 aa2 = bordRectXY * s1i2i + bordRectZW * s12i + rectZW * s12;
        float2 uu1 = uvRectXY * s1i2i + uvBorderRectXY * s12i + uvBorderRecZW * s12;
        float2 uu2 = uvBorderRectXY * s1i2i + uvBorderRecZW * s12i + uvRectZW * s12;
        return
            __SoftMask_Inset(a, aa1, aa2, uu1, uu2
#   if SOFTMASK_TILED_PARENT
                , s12i * _SoftMask_TileRepeat_PARENT
#   endif
            );
    }

    inline float2 SoftMask_GetMaskUV_PARENT(float2 maskPosition) {
        return
            __SoftMask_XY2UV_PARENT(
                maskPosition,
                _SoftMask_Rect_PARENT.xy, _SoftMask_BorderRect_PARENT.xy, _SoftMask_BorderRect_PARENT.zw, _SoftMask_Rect_PARENT.zw,
                _SoftMask_UVRect_PARENT.xy, _SoftMask_UVBorderRect_PARENT.xy, _SoftMask_UVBorderRect_PARENT.zw, _SoftMask_UVRect_PARENT.zw);
    }
# else
    inline float2 SoftMask_GetMaskUV_PARENT(float2 maskPosition) {
        return
            __SoftMask_Inset(
                maskPosition,
                _SoftMask_Rect_PARENT.xy, _SoftMask_Rect_PARENT.zw, _SoftMask_UVRect_PARENT.xy, _SoftMask_UVRect_PARENT.zw);
    }
# endif
    inline float4 SoftMask_GetMaskTexture_PARENT(float2 maskPosition) {
        return tex2D(_SoftMask_PARENT, SoftMask_GetMaskUV_PARENT(maskPosition));
    }

    inline float SoftMask_GetMask_PARENT(float2 maskPosition) {
        float2 uv = SoftMask_GetMaskUV_PARENT(maskPosition);
        float4 sampledMask = tex2D(_SoftMask_PARENT, uv);
        float weightedMask = dot(sampledMask * _SoftMask_ChannelWeights_PARENT, 1);
        float maskInsideRect = _SoftMask_InvertMask_PARENT ? 1 - weightedMask : weightedMask;
        float maskOutsideRect = _SoftMask_InvertOutsides_PARENT;
        float isInsideRect = UnityGet2DClipping(maskPosition, _SoftMask_Rect_PARENT);
        return lerp(maskOutsideRect, maskInsideRect, isInsideRect);
    }
#else // __SOFTMASK_ENABLED_PARENT

# define SOFTMASK_COORDS_PARENT(idx)
# define SOFTMASK_CALCULATE_COORDS_PARENT(OUT, pos)
# define SOFTMASK_GET_MASK_PARENT(IN)                 (1.0f)

    inline float4 SoftMask_GetMaskTexture_PARENT(float2 maskPosition) { return 1.0f; }
    inline float SoftMask_GetMask_PARENT(float2 maskPosition) { return 1.0f; }
#endif

#endif

// UNITY_SHADER_NO_UPGRADE
