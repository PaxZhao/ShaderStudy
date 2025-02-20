#ifndef FUR_SHELL_MOD_LIT_HLSL
#define FUR_SHELL_MOD_LIT_HLSL

#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "./Modified_Param.hlsl"
#include "../Common/Common.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 tangentWS : TEXCOORD2;
    float2 uv : TEXCOORD4;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 5);
    float4 fogFactorAndVertexLight : TEXCOORD6; // x: fogFactor, yzw: vertex light
    float  layer : TEXCOORD7;
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
    float3 shellDir = SafeNormalize(normalInput.normalWS + move + windMove);
    float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    
    output.positionWS = vertexInput.positionWS + shellDir * (_ShellStep * index);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.layer = (float)index / _ShellAmount;

    float3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    stream.Append(output);
}

[maxvertexcount(42)]
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

inline float3 TransformHClipToWorld(float4 positionCS)
{
    return mul(UNITY_MATRIX_I_VP, positionCS).xyz;
}

float4 frag(Varyings input) : SV_Target
{
    float2 furUv = input.uv / _BaseMap_ST.xy * _FurScale;
    float4 furColor = SAMPLE_TEXTURE2D(_FurMap, sampler_FurMap, furUv);

    // Custom addition to create a mask that limits where the fur appears.
    // Created an unscaled UV in order to avoid the fur map from accidentally mis-placing the mask
    float2 unscaledFurUV = input.uv / _BaseMap_ST.xy;
    float4 furMask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, unscaledFurUV);

    // Multiplied the furColor.r by the furMask.g in order to take the fur patterning from the fur map and cross it with the limited areas of the fur mask. 
    // Used the furMask.g in order to allow for the furMask to be an RGB map that controls skin, fur and other configurable colours using the different channels. (prefer to put r as skin, g as fur/hair, b as other)
    float alpha = furColor.r * furMask.g * (1.0 - input.layer);
    if (input.layer > 0.0 && alpha < _AlphaCutout) discard;

    float3 viewDirWS = SafeNormalize(GetCameraPositionWS() - input.positionWS);
    float3 normalTS = UnpackNormalScale(
        SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, furUv), 
        _NormalScale);

    // Multiplying the normalTS by the hair areas to ensure it only changes the normals at those locations.
    normalTS *= alpha;

    float3 normalBase = SAMPLE_TEXTURE2D(_BaseNormal, sampler_BaseNormal, unscaledFurUV);
    normalTS += normalBase * (1 - alpha);

    float3 bitangent = SafeNormalize(viewDirWS.y * cross(input.normalWS, input.tangentWS));
    float3 normalWS = SafeNormalize(TransformTangentToWorld(
        normalTS, 
        float3x3(input.tangentWS, bitangent, input.normalWS)));

    SurfaceData surfaceData = (SurfaceData)0;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);
    surfaceData.occlusion = lerp(1.0 - _Occlusion, 1.0, input.layer);
    surfaceData.albedo *= surfaceData.occlusion;

    InputData inputData = (InputData)0;
    inputData.positionWS = input.positionWS;
    inputData.normalWS = normalWS;
    inputData.viewDirectionWS = viewDirWS;
#if (defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)) && !defined(_RECEIVE_SHADOWS_OFF)
    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif
    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, normalWS);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

    float4 color = UniversalFragmentPBR(inputData, surfaceData);

    ApplyRimLight(color.rgb, input.positionWS, viewDirWS, normalWS);

    // Removing the alpha section (the hair areas) from the final colour, then making sure ambient only applies to the alpha so that ambient controls hair colour.

    float3 ambientColor = _AmbientColor;

    color.r -= alpha;
    color.g -= alpha;
    color.b -= alpha;
    ambientColor.r *= alpha;
    ambientColor.g *= alpha;
    ambientColor.b *= alpha;
    color.rgb += ambientColor;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    return color;
}

#endif
