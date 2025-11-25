#ifndef SHADOW_PROB_INCLUDED
#define SHADOW_PROB_INCLUDED

half3 _ShadowProbOffset;
half3 _ShadowProbTiling;
half3 _ShadowProbCount;
float _ShadowProbFactors[300];

half SampleShadowProb(float3 positionWS)
{
	float3 uvw = (positionWS + _ShadowProbOffset) * _ShadowProbTiling;
	uvw = saturate(uvw) * _ShadowProbCount;
	float3 uvwFrac = frac(uvw);
	float3 uvwFloor = floor(uvw);
	float3 uvwCeil = ceil(uvw);
	int index[8];
	half coeff[8];
	int scaleX = (_ShadowProbCount.y + 1) * (_ShadowProbCount.z + 1);
	int scaleY = (_ShadowProbCount.z + 1);

	index[0] = uvwFloor.x * scaleX + uvwFloor.y * scaleY + uvwFloor.z;
	coeff[0] = (1 - uvwFrac.x) * (1 - uvwFrac.y) * (1 - uvwFrac.z);

	index[1] = uvwCeil.x * scaleX + uvwFloor.y * scaleY + uvwFloor.z;
	coeff[1] = uvwFrac.x * (1 - uvwFrac.y) * (1 - uvwFrac.z);

	index[2] = uvwFloor.x * scaleX + uvwCeil.y * scaleY + uvwFloor.z;
	coeff[2] = (1 - uvwFrac.x) * uvwFrac.y * (1 - uvwFrac.z);

	index[3] = uvwCeil.x * scaleX + uvwCeil.y * scaleY + uvwFloor.z;
	coeff[3] = uvwFrac.x * uvwFrac.y * (1 - uvwFrac.z);

	index[4] = uvwFloor.x * scaleX + uvwFloor.y * scaleY + uvwCeil.z;
	coeff[4] = (1 - uvwFrac.x) * (1 - uvwFrac.y) * uvwFrac.z;

	index[5] = uvwCeil.x * scaleX + uvwFloor.y * scaleY + uvwCeil.z;
	coeff[5] = uvwFrac.x * (1 - uvwFrac.y) * uvwFrac.z;

	index[6] = uvwFloor.x * scaleX + uvwCeil.y * scaleY + uvwCeil.z;
	coeff[6] = (1 - uvwFrac.x) * uvwFrac.y * uvwFrac.z;

	index[7] = uvwCeil.x * scaleX + uvwCeil.y * scaleY + uvwCeil.z;
	coeff[7] = uvwFrac.x * uvwFrac.y * uvwFrac.z;

	half factor = 0;

    for (int i = 0; i < 8; i++) {
    	factor = factor + _ShadowProbFactors[index[i]] * coeff[i];
    }

	return factor;
}

#endif // SHADOW_PROB_INCLUDED