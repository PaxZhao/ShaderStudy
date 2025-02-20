#ifndef FUR_SHELL_MOD_DEPTH_HLSL
#define FUR_SHELL_MOD_DEPTH_HLSL

#include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
#include "./Modified_Param.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float  fogCoord : TEXCOORD1;
    float  layer : TEXCOORD2;
};

Attributes vert(Attributes input)
{
    return input;
}

void AppendShellVertex(inout TriangleStream<Varyings> stream, Attributes input, int index)
{
    Varyings output = (Varyings)0;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float moveFactor = pow(abs((float)index / _ShellAmount), _BaseMove.w);
    float3 posOS = input.positionOS.xyz;
    float3 windAngle = _Time.w * _WindFreq.xyz;
    float3 windMove = moveFactor * _WindMove.xyz * sin(windAngle + posOS * _WindMove.w);
    float3 move = moveFactor * _BaseMove.xyz;

    float3 shellDir = normalize(normalInput.normalWS + move + windMove);
    float3 posWS = vertexInput.positionWS + shellDir * (_ShellStep * index);
    float4 posCS = TransformWorldToHClip(posWS);
    
    output.vertex = posCS;
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.fogCoord = ComputeFogFactor(posCS.z);
    output.layer = (float)index / _ShellAmount;

    stream.Append(output);
}

[maxvertexcount(128)]
void geom(triangle Attributes input[3], inout TriangleStream<Varyings> stream)
{
    [loop] for (float i = 0; i < _ShellAmount; ++i)
    {
        [unroll] for (float j = 0; j < 3; ++j)
        {
            AppendShellVertex(stream, input[j], i);
        }
        stream.RestartStrip();
    }
}

void frag(
    Varyings input, 
    out float4 outColor : SV_Target, 
    out float outDepth : SV_Depth)
{
    // Custom addition to create a mask that limits where the fur appears.
    // Created an unscaled UV in order to avoid the fur map from accidentally mis-placing the mask
    float2 unscaledFurUV = input.uv / _BaseMap_ST.xy;
    float4 furMask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, unscaledFurUV);

    // Multiplied the furColor.r by the furMask.g in order to take the fur patterning from the fur map and cross it with the limited areas of the fur mask. 
    // Used the furMask.g in order to allow for the furMask to be an RGB map that controls skin, fur and other configurable colours using the different channels. (prefer to put r as skin, g as fur/hair, b as other)
    float4 furColor = SAMPLE_TEXTURE2D(_FurMap, sampler_FurMap, input.uv / _BaseMap_ST.xy * _FurScale);
    float alpha = furColor.r * furMask.g * (1.0 - input.layer);
    if (input.layer > 0.0 && alpha < _AlphaCutout) discard;

    outColor = outDepth = input.vertex.z / input.vertex.w;
}

#endif