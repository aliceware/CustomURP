#ifndef RO_OPT_SubPassLoad_Untils
#define RO_OPT_SubPassLoad_Untils

#include "./ROOPTSubPassLoadUntilsDep.hlsl"


//RO_OPT_SUBPASS_LOAD
//RO_TERRAIN_LOAD
//RO_MS_READ
//RO_FORCE_STORE_READ
 
// ---------- 用于支持Vulkan, Metal, Dx ----------
#if ((defined(RO_OPT_SUBPASS_LOAD) && (defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_D3D11)))||defined(RO_FORCE_STORE_READ))
     #define RO_OPT_SUBPASS_LOAD_MRT
#endif

#if (defined(RO_TERRAIN_LOAD) && (defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_D3D11) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE))) || defined(RO_OPT_SUBPASS_LOAD_MRT)
    #define RO_OPT_TERRAIN_LOAD_MRT
#endif

// ---------- 用于支持es ----------
#if (defined(RO_OPT_SUBPASS_LOAD) && (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
    #define RO_OPT_OPENGLES_COLOR_FETCH 
#endif

#if defined(RO_OPT_OPENGLES_COLOR_FETCH)
    static half4 ro_global_fetchColor;
    #define RO_TRANSPARENT_PIXEL_SHADER_FUNCTION(functionName, vertexOutput) void functionName(vertexOutput, inout half4 fetchColor : CoLoR)
    #define RO_TRANSPARENT_PIXEL_INPUT ro_global_fetchColor = fetchColor;
    #define RO_TRANSPARENT_PIXEL_OUTPUT(color) fetchColor = color;
#else
    #define RO_TRANSPARENT_PIXEL_SHADER_FUNCTION(functionName, vertexOutput) half4 functionName(vertexOutput) : SV_TARGET
    #define RO_TRANSPARENT_PIXEL_INPUT
    #define RO_TRANSPARENT_PIXEL_OUTPUT(color) return color;
#endif

// MRT结构体
#if defined(RO_OPT_SUBPASS_LOAD_MRT)                   
    struct ROFragmentOutput
    {
        half4 ColorAttachment     : SV_Target0;
        half3 Color               : SV_Target1;
		half  Depth               : SV_Target2;
    };
#endif

//地表MRT结构体
#if defined(RO_OPT_TERRAIN_LOAD_MRT)
    struct ROTerrainOutput
    {
       half4 ColorAttachment : SV_Target0;
       #if(defined(RO_TERRAIN_LOAD) && defined(RO_OPT_SUBPASS_LOAD_MRT))
            half3 Color              : SV_Target1;
		    half  Depth              : SV_Target2;
		    half4 TerrainDepth       : SV_Target3;
            half4 TerrainDepthEXT    : SV_Target4;
       #elif defined(RO_TERRAIN_LOAD)
            half4 TerrainDepth       : SV_Target1;
            half4 TerrainDepthEXT    : SV_Target2;
       #else
            half3 Color               : SV_Target1;
		    half  Depth               : SV_Target2;
       #endif
    };
 #endif    
    
// 定义函数体, 输出Color和Depth, 用于支持Vulkan和Metal
 #if defined(RO_OPT_SUBPASS_LOAD_MRT)
     #define RO_OPAQUE_PIXEL_SHADER_FUNCTION(functionName, vertexOutput) ROFragmentOutput functionName(vertexOutput)       
 #else
     #define RO_OPAQUE_PIXEL_SHADER_FUNCTION(functionName, vertexOutput) half4 functionName(vertexOutput) : SV_TARGET
#endif

// 输出MRT
#if defined(RO_OPT_SUBPASS_LOAD_MRT)
     ROFragmentOutput SubPassOutputColor(half4 color, half depth)
#else
     half4 SubPassOutputColor(half4 color, half depth)
#endif
    { 
         #if defined(RO_OPT_SUBPASS_LOAD_MRT) 
                ROFragmentOutput output;
                output.ColorAttachment = color;
                output.Color           = color.rgb;
#if defined(UNITY_REVERSED_Z)
                output.Depth = depth;
#else
                output.Depth = 1 - depth;
#endif
                return output;
        #else
           return color;
        #endif
    }

// 定义函数体, 输出Color和Depth, 用于支持Vulkan和Metal
#if defined(RO_OPT_TERRAIN_LOAD_MRT)
    #define RO_TERRAIN_SHADER_FUNCTION(functionName, vertexOutput) ROTerrainOutput functionName(vertexOutput)
#else
    #define RO_TERRAIN_SHADER_FUNCTION(functionName, vertexOutput) half4 functionName(vertexOutput) : SV_TARGET
#endif


#if defined(RO_OPT_TERRAIN_LOAD_MRT)
    ROTerrainOutput TerainOutputColor(half4 color, half depth, half3 depthColor, half3 depthEXT)
#else
    half4 TerainOutputColor(half4 color, half depth, half3 depthColor, half3 depthEXT)
#endif
    {
         #if defined(RO_OPT_TERRAIN_LOAD_MRT)
                        ROTerrainOutput output;
                        output.ColorAttachment = color;
                        #if defined(RO_OPT_SUBPASS_LOAD_MRT) 
                            output.Color           = color.rgb;
                            #if defined(UNITY_REVERSED_Z)
                                output.Depth = depth;
                            #else
                                output.Depth = 1 - depth;
                            #endif
                        #endif
                        #if defined(RO_TERRAIN_LOAD)
                                Depth16bit depthOut = EncodeDepth16bit(depth);
                                output.TerrainDepth.rgb    = depthColor;
                                output.TerrainDepth.a  = depthOut.depthFront;
                                output.TerrainDepthEXT.rgb = depthEXT;
                                output.TerrainDepthEXT.a = depthOut.depthBack;

                         #endif
                        return output;
        #else
            return color;
        #endif
    }

//// ---------------------------------------------------------------------

#if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE))
    #define COMPUTER_UV(uv)       uv/ _ScreenParams.xy
#else
    #define COMPUTER_UV(uv)       uv/_ScaledScreenParams.xy
#endif


//// ---------- 使用Fetch ------------------------------------------------- 
#if defined(RO_OPT_SUBPASS_LOAD)
    #if defined(RO_FORCE_STORE_READ)
        #define RO_FRAMEBUFFER_INPUT_FLOAT_COLOR(idx)   sampler2D _FetchColorTexture; 
        #define RO_FRAMEBUFFER_INPUT_FLOAT_DEPTH(idx)   sampler2D _FetchDepthTexture;
        #define GET_SUBPASS_LOAD_COLOR(uv)       (tex2D(_FetchColorTexture, COMPUTER_UV(uv)).rgb)
        #if defined(UNITY_REVERSED_Z)
                #define GET_SUBPASS_LOAD_DEPTH(uv)       (tex2D(_FetchDepthTexture, COMPUTER_UV(uv)).r)
        #else
                #define GET_SUBPASS_LOAD_DEPTH(uv)       1 - (tex2D(_FetchDepthTexture, COMPUTER_UV(uv)).r)
        #endif
        #define GET_SUBPASS_LOAD_COLOR_DEPTH(uv) half4(GET_SUBPASS_LOAD_COLOR(uv), GET_SUBPASS_LOAD_DEPTH(uv))
    #else
        #if defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL)
                #if defined(RO_MS_READ)
                    #define RO_FRAMEBUFFER_INPUT_FLOAT_COLOR(idx) FRAMEBUFFER_INPUT_FLOAT_MS(idx)
                    #define RO_FRAMEBUFFER_INPUT_FLOAT_DEPTH(idx) FRAMEBUFFER_INPUT_FLOAT_MS(idx)
                    #define GET_SUBPASS_LOAD_COLOR(uv) LOAD_FRAMEBUFFER_INPUT_MS(0, 0, COMPUTER_UV(uv)).rgb
                    #define GET_SUBPASS_LOAD_DEPTH(uv) LOAD_FRAMEBUFFER_INPUT_MS(1, 0, COMPUTER_UV(uv)).r
                    #define GET_SUBPASS_LOAD_COLOR_DEPTH(uv) half4(GET_SUBPASS_LOAD_COLOR(uv), GET_SUBPASS_LOAD_DEPTH(uv))
                #else
                    #define RO_FRAMEBUFFER_INPUT_FLOAT_COLOR(idx) FRAMEBUFFER_INPUT_FLOAT(idx)
                    #define RO_FRAMEBUFFER_INPUT_FLOAT_DEPTH(idx) FRAMEBUFFER_INPUT_FLOAT(idx) 
                    #define GET_SUBPASS_LOAD_COLOR(uv) LOAD_FRAMEBUFFER_INPUT(0, COMPUTER_UV(uv)).rgb
                    #define GET_SUBPASS_LOAD_DEPTH(uv) LOAD_FRAMEBUFFER_INPUT(1, COMPUTER_UV(uv))
                    #define GET_SUBPASS_LOAD_COLOR_DEPTH(uv) half4(GET_SUBPASS_LOAD_COLOR(uv), GET_SUBPASS_LOAD_DEPTH(uv))      
                #endif
        #elif defined(SHADER_API_D3D11) 
                #define RO_FRAMEBUFFER_INPUT_FLOAT_COLOR(idx)   sampler2D _FetchColorTexture; 
                #define RO_FRAMEBUFFER_INPUT_FLOAT_DEPTH(idx)   sampler2D _FetchDepthTexture; 
                #define GET_SUBPASS_LOAD_COLOR(uv)       (tex2D(_FetchColorTexture, COMPUTER_UV(uv)).rgb)
                #define GET_SUBPASS_LOAD_DEPTH(uv)       (tex2D(_FetchDepthTexture, COMPUTER_UV(uv)).r)
                #define GET_SUBPASS_LOAD_COLOR_DEPTH(uv) half4(GET_SUBPASS_LOAD_COLOR(uv), GET_SUBPASS_LOAD_DEPTH(uv))
        #else //es
                #define RO_FRAMEBUFFER_INPUT_FLOAT_COLOR(idx);
                #define RO_FRAMEBUFFER_INPUT_FLOAT_DEPTH(idx);
                #define GET_SUBPASS_LOAD_DEPTH(uv) PLATFORM_SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, COMPUTER_UV(uv))
                #define GET_SUBPASS_LOAD_COLOR(uv) ro_global_fetchColor.rgb
                #define GET_SUBPASS_LOAD_COLOR_DEPTH(uv) half4(GET_SUBPASS_LOAD_COLOR(uv), GET_SUBPASS_LOAD_DEPTH(uv))
                //float4 get_subpass_depth_color(float2 uv)
                //{
                //    float4 r;
                //    r.xyz = GET_SUBPASS_LOAD_COLOR(uv);
                //    r.w = GET_SUBPASS_LOAD_DEPTH(uv);
                //    return r;
                //}
                //#define GET_SUBPASS_LOAD_COLOR_DEPTH(uv) get_subpass_depth_color(uv)
        #endif
    #endif
#else
    #define RO_FRAMEBUFFER_INPUT_FLOAT_COLOR(idx);
    #define RO_FRAMEBUFFER_INPUT_FLOAT_DEPTH(idx);
    #define GET_SUBPASS_LOAD_DEPTH(uv) 1
    #define GET_SUBPASS_LOAD_COLOR(uv) float3(1, 1, 0)
    #define GET_SUBPASS_LOAD_COLOR_DEPTH(uv) float4(1, 1, 0,1)

#endif
#define RO_FRAMEBUFFER_DECLARE_INPUT \
        RO_FRAMEBUFFER_INPUT_FLOAT_COLOR(0);\
        RO_FRAMEBUFFER_INPUT_FLOAT_DEPTH(1);     

#define COMPUTER_UV2(uv)       uv/_ScaledScreenParams.xy

#if defined(RO_TERRAIN_LOAD)
    #if defined(RO_FORCE_STORE_READ)
        #define RO_TERRAIN_INPUT_FLOAT(idx)             sampler2D _TerrainDepthTexture;
        #define RO_TERRAIN_INPUT_FLOAT_EXT(idx)         sampler2D _TerrainDepthTextureEXT;
        #define GET_TERRAIN_LOAD_COLOR_DEPTH(uv)        (tex2D(_TerrainDepthTexture, COMPUTER_UV2(uv)))
        #define GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(uv)    (tex2D(_TerrainDepthTextureEXT, COMPUTER_UV2(uv)))
    #else
        #if defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) 
                #if defined(RO_MS_READ)
                #define RO_TERRAIN_INPUT_FLOAT(idx) FRAMEBUFFER_INPUT_FLOAT_MS(idx);
                #define RO_TERRAIN_INPUT_FLOAT_EXT(idx) FRAMEBUFFER_INPUT_FLOAT_MS(idx);
                #define GET_TERRAIN_LOAD_COLOR_DEPTH(uv) LOAD_FRAMEBUFFER_INPUT_MS(0,0, COMPUTER_UV2(uv))
                #define GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(uv) LOAD_FRAMEBUFFER_INPUT_MS(1,0, COMPUTER_UV2(uv))
                #else
                #define RO_TERRAIN_INPUT_FLOAT(idx) FRAMEBUFFER_INPUT_FLOAT(idx); 
                #define RO_TERRAIN_INPUT_FLOAT_EXT(idx) FRAMEBUFFER_INPUT_FLOAT(idx);
                #define GET_TERRAIN_LOAD_COLOR_DEPTH(uv) LOAD_FRAMEBUFFER_INPUT(0, COMPUTER_UV2(uv))
                #define GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(uv) LOAD_FRAMEBUFFER_INPUT(1, COMPUTER_UV2(uv))
                #endif
        #elif defined(SHADER_API_D3D11) 
                #define RO_TERRAIN_INPUT_FLOAT(idx)          sampler2D _TerrainDepthTexture;
                #define RO_TERRAIN_INPUT_FLOAT_EXT(idx)      sampler2D _TerrainDepthTextureEXT;
                #define GET_TERRAIN_LOAD_COLOR_DEPTH(uv)     (tex2D(_TerrainDepthTexture, COMPUTER_UV2(uv)))
                #define GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(uv) (tex2D(_TerrainDepthTextureEXT, COMPUTER_UV2(uv)))

        #else //es
                #define RO_TERRAIN_INPUT_FLOAT(idx)          sampler2D _TerrainDepthTexture;
                #define RO_TERRAIN_INPUT_FLOAT_EXT(idx)      sampler2D _TerrainDepthTextureEXT;
                #define GET_TERRAIN_LOAD_COLOR_DEPTH(uv)     (tex2D(_TerrainDepthTexture, COMPUTER_UV2(uv)))
                #define GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(uv) (tex2D(_TerrainDepthTextureEXT, COMPUTER_UV2(uv)))
        #endif
    #endif
#else
    #define RO_TERRAIN_INPUT_FLOAT(idx);
    #define RO_TERRAIN_INPUT_FLOAT_EXT(idx);
    #define GET_TERRAIN_LOAD_COLOR_DEPTH(uv) float4(0, 0, 1, 1)
    #define GET_TERRAIN_LOAD_COLOR_DEPTH_EXT(uv) float4(0, 0, 1, 1)
#endif

#define RO_TERRAIN_DECLARE_INPUT \
        RO_TERRAIN_INPUT_FLOAT(0); \
        RO_TERRAIN_INPUT_FLOAT_EXT(1);
#endif