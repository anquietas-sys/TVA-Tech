#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);

struct PS_INPUT {
	float2 uv            : TEXCOORD0;	
	float3 pos           : TEXCOORD1;
	float3 normal        : TEXCOORD2;
};

float4 main(PS_INPUT input) : COLOR {
	float3 depth = length(cEyePos - input.pos);

	return float4(depth, 1.0f);
};