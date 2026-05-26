#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);
float AMOUNT        : register(c1);
float MULT        : register(c0);

struct PS_INPUT {
	float2 uv            : TEXCOORD0;	
	float3 pos           : TEXCOORD1;
	float3 normal        : TEXCOORD2;
};

float4 main(PS_INPUT input) : COLOR {
	float r = tex2D(BASETEXTURE, input.uv - AMOUNT).x * MULT;
	float g = tex2D(BASETEXTURE, input.uv).y * MULT;
	float b = tex2D(BASETEXTURE, input.uv + AMOUNT).z * MULT;

	return float4(r,g,b, 1.0f);
};