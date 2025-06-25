#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);
float4 SCREEN       : register(c0);
float FEATHERING    : register(c1);
float4 CUSTOM_COLOR : register(c2);

struct PS_INPUT {
	float2 viewPos       : VPOS;
	float2 uv            : TEXCOORD0;	
	float3 pos           : TEXCOORD1;
	float3 normal        : TEXCOORD2;
};

float4 main(PS_INPUT input) : COLOR {
	float portalDepth = length(cEyePos - input.pos);

	float childDepth = tex2D(BASETEXTURE, input.viewPos * SCREEN.xy).x ;

	float someShit = min(FEATHERING/abs(portalDepth-childDepth), 1);
	// i am having a stroke
	float4 color = float4(someShit,someShit,someShit,someShit)*CUSTOM_COLOR;
	
	return FinalOutput(color, 0, PIXEL_FOG_TYPE_NONE, TONEMAP_SCALE_LINEAR);
};