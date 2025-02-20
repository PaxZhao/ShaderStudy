#ifndef FUR_SHELL_MOD_PARAM_HLSL
#define FUR_SHELL_MOD_PARAM_HLSL

int _ShellAmount;
float _ShellStep;
float _AlphaCutout;
float _Occlusion;
float _FurScale;
float4 _BaseMove;
float4 _WindFreq;
float4 _WindMove;
float3 _AmbientColor;
float _FaceViewProdThresh;

TEXTURE2D(_FurMap); 
SAMPLER(sampler_FurMap);
float4 _FurMap_ST;

TEXTURE2D(_NormalMap); 
SAMPLER(sampler_NormalMap);
float4 _NormalMap_ST;
float _NormalScale;

//Added the fur mask, which will limit where on the mesh the fur is permitted to appear.

TEXTURE2D(_FurMask);
SAMPLER(sampler_FurMask);
float4 _FurMask_ST;

//Added the standard normal map for areas not affected by fur
TEXTURE2D(_BaseNormal);
SAMPLER(sampler_BaseNormal);
float4 _BaseNormal_ST;

#endif