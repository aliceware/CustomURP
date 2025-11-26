using UnityEditor;
using UnityEngine;

public class TutorialBaker : MonoBehaviour
{
    public Cubemap skybox;
    public Cubemap irradianceMap;

    public ComputeShader IBLBaker;
    public string savePath = "Assets/MyPBR/Tutorial/Textures";
    private const int irradianceBakeKernel = 0;

    [ContextMenu("Bake CubeMap To IrradianceMap")]
    public void BakeCubeMapToIrradiance()
    {
        PrefilterDiffuseCubemap(skybox, out irradianceMap);
        AssetDatabase.CreateAsset(irradianceMap, $"{savePath}/IrrMap.asset");
        AssetDatabase.Refresh();
    }

    private void PrefilterDiffuseCubemap(Cubemap envCubemap, out Cubemap outputCubemap)
    {
        int size = 128;
        outputCubemap = new Cubemap(size, TextureFormat.RGBAFloat, false);
        ComputeBuffer reslutBuffer = new ComputeBuffer(size * size, sizeof(float) * 4);
        Color[] tempColors = new Color[size * size];
        for (int face = 0; face < 6; ++face)
        {
            IBLBaker.SetInt("_Face", face);
            IBLBaker.SetTexture(irradianceBakeKernel, "_Skybox", envCubemap);
            IBLBaker.SetInt("_Resolution", size);
            IBLBaker.SetBuffer(irradianceBakeKernel, "_Reslut", reslutBuffer);
            IBLBaker.Dispatch(irradianceBakeKernel, size / 8, size / 8, 1);
            reslutBuffer.GetData(tempColors);
            outputCubemap.SetPixels(tempColors, (CubemapFace)face);
        }

        reslutBuffer.Release();
        outputCubemap.Apply();
    }


    public Vector3[] shCoefficients;

    [ContextMenu("Bake SH Coefficients")]
    public void BaekSHCoefficients()
    {
        shCoefficients = BakeSH(irradianceMap);
    }

    /// <summary>
    /// 进行球谐系数的计算
    /// </summary>
    /// <param name="map"></param>
    /// <returns></returns>
    private Vector3[] BakeSH(Cubemap map)
    {
        if (map == null)
        {
            return null;
        }

        Vector3[] coefficients = new Vector3[9];
        float[] sh9 = new float[9];
        for (int face = 0; face < 6; ++face)
        {
            var colors = map.GetPixels((CubemapFace)face);
            for (int texel = 0; texel < map.width * map.width; ++texel)
            {
                float u = (texel % map.width) / (float)map.width;
                float v = ((int)(texel / map.width)) / (float)map.width;
                //uv转直角坐标
                Vector3 dir = DirectionFromCubemapTexel(face, u, v);
                //获取CubeMap的颜色值
                Color radiance = colors[texel];
                //微元换算，链式积分
                float d_omega = DifferentialSolidAngle(map.width, u, v);

                //球谐分量
                HarmonicsBasis(dir, sh9);

                for (int c = 0; c < 9; ++c)
                {
                    float sh = sh9[c];
                    coefficients[c].x += radiance.r * d_omega * sh;
                    coefficients[c].y += radiance.g * d_omega * sh;
                    coefficients[c].z += radiance.b * d_omega * sh;
                }
            }
        }

        return coefficients;
    }

    void HarmonicsBasis(Vector3 pos, float[] sh9)
    {
        //系数来自wiki，直接查表即可。https://zh.wikipedia.org/wiki/%E7%90%83%E8%B0%90%E5%87%BD%E6%95%B0
        const float sh0_0 = 0.28209479f;
        const float sh1_1 = 0.48860251f;
        const float sh2_n2 = 1.09254843f;
        const float sh2_n1 = 1.09254843f;
        const float sh2_0 = 0.31539157f;
        const float sh2_1 = 1.09254843f;
        const float sh2_2 = 0.54627421f;

        //计算直角坐标系中，某一点上，每一个基函数的对应结果。
        Vector3 normal = pos;
        float x = normal.x;
        float y = normal.y;
        float z = normal.z;
        sh9[0] = sh0_0;
        sh9[1] = sh1_1 * y;
        sh9[2] = sh1_1 * z;
        sh9[3] = sh1_1 * x;
        sh9[4] = sh2_n2 * x * y;
        sh9[5] = sh2_n1 * z * y;
        sh9[6] = sh2_0 * (2 * z * z - x * x - y * y);
        sh9[7] = sh2_1 * z * x;
        sh9[8] = sh2_2 * (x * x - y * y);
    }

    public static Vector3 DirectionFromCubemapTexel(int face, float u, float v)
    {
        Vector3 dir = Vector3.zero;

        switch (face)
        {
            case 0: //+X
                dir.x = 1;
                dir.y = v * -2.0f + 1.0f;
                dir.z = u * -2.0f + 1.0f;
                break;

            case 1: //-X
                dir.x = -1;
                dir.y = v * -2.0f + 1.0f;
                dir.z = u * 2.0f - 1.0f;
                break;

            case 2: //+Y
                dir.x = u * 2.0f - 1.0f;
                dir.y = 1.0f;
                dir.z = v * 2.0f - 1.0f;
                break;

            case 3: //-Y
                dir.x = u * 2.0f - 1.0f;
                dir.y = -1.0f;
                dir.z = v * -2.0f + 1.0f;
                break;

            case 4: //+Z
                dir.x = u * 2.0f - 1.0f;
                dir.y = v * -2.0f + 1.0f;
                dir.z = 1;
                break;

            case 5: //-Z
                dir.x = u * -2.0f + 1.0f;
                dir.y = v * -2.0f + 1.0f;
                dir.z = -1;
                break;
        }

        return dir.normalized;
    }

    public static float DifferentialSolidAngle(int textureSize, float U, float V)
    {
        float inv = 1.0f / textureSize;
        float u = 2.0f * (U + 0.5f * inv) - 1;
        float v = 2.0f * (V + 0.5f * inv) - 1;
        float x0 = u - inv;
        float y0 = v - inv;
        float x1 = u + inv;
        float y1 = v + inv;
        return AreaElement(x0, y0) - AreaElement(x0, y1) - AreaElement(x1, y0) + AreaElement(x1, y1);
    }

    public static float AreaElement(float x, float y)
    {
        return Mathf.Atan2(x * y, Mathf.Sqrt(x * x + y * y + 1));
    }


    public Vector3[] zhCoefficients;
    [ContextMenu("Bake ZH Coefficients")]
    public void BaekZHCoefficients()
    {
        zhCoefficients = BakeSH(skybox);
    }


    private const int prefilterSpecularBakeKernel = 1;
    public Cubemap specularMap;

    [ContextMenu("Bake Prefilter Specular Cubemap")]
    public void BakePrefilterSpecularCubemap()
    {
        PrefilterSpecularCubemap(skybox, out specularMap);
        AssetDatabase.CreateAsset(specularMap, $"{savePath}/SpecularMap.asset");
        AssetDatabase.Refresh();
    }

    private void PrefilterSpecularCubemap(Cubemap cubemap, out Cubemap outputCubemap)
    {
        int bakeSize = 128;
        outputCubemap = new Cubemap(bakeSize, TextureFormat.RGBAFloat, true);
        int maxMip = outputCubemap.mipmapCount;
        int sampleCubemapSize = cubemap.width;
        outputCubemap.filterMode = FilterMode.Trilinear;
        for (int mip = 0; mip < maxMip; mip++)
        {
            int size = bakeSize;
            size = size >> mip;
            int size2 = size * size;
            Color[] tempColors = new Color[size2];
            float roughness = (float)mip / (float)(maxMip - 1);
            ComputeBuffer reslutBuffer = new ComputeBuffer(size2, sizeof(float) * 4);
            for (int face = 0; face < 6; ++face)
            {
                IBLBaker.SetInt("_Face", face);
                IBLBaker.SetTexture(prefilterSpecularBakeKernel, "_Skybox", cubemap);
                IBLBaker.SetFloat("_SampleCubemapSize", sampleCubemapSize);
                IBLBaker.SetInt("_Resolution", size);
                IBLBaker.SetFloat("_FilterMipRoughness", roughness);
                IBLBaker.SetBuffer(prefilterSpecularBakeKernel, "_Reslut", reslutBuffer);
                IBLBaker.Dispatch(prefilterSpecularBakeKernel, size, size, 1);
                reslutBuffer.GetData(tempColors);
                outputCubemap.SetPixels(tempColors, (CubemapFace)face, mip);
            }
            reslutBuffer.Release();
        }
        outputCubemap.Apply(false);
    }

    private const int brdfLutKernel = 2;
    public Texture2D brdfLut;

    [ContextMenu("Bake BRDF LUT")]
    public void BakeBRDFLut()
    {
        BRDFLut(out brdfLut);
        AssetDatabase.CreateAsset(brdfLut, $"{savePath}/BrdfLut.asset");
        AssetDatabase.Refresh();
    }
    private void BRDFLut(out Texture2D tex)
    {
        int resolution = 512;
        int resolution2 = resolution * resolution;
        tex = new Texture2D(resolution, resolution, TextureFormat.RGBA32, false, true);
        tex.wrapMode = TextureWrapMode.Clamp;
        tex.filterMode = FilterMode.Point;
        Color[] tempColors = new Color[resolution2];
        ComputeBuffer reslutBuffer = new ComputeBuffer(resolution2, sizeof(float) * 4);
        IBLBaker.SetBuffer(brdfLutKernel, "_Reslut", reslutBuffer);
        IBLBaker.SetInt("_Resolution", resolution);
        IBLBaker.Dispatch(brdfLutKernel, resolution / 8, resolution / 8, 1);
        reslutBuffer.GetData(tempColors);
        tex.SetPixels(tempColors, 0);
        tex.Apply();
    }
}
