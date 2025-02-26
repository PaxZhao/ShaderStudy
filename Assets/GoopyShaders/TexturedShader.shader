Shader "ShaderStudy/TexturedShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Pattern ("Pattern", 2D) = "white" {}
        _Rock ("Rock", 2D) = "white" {} 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define TAU 6.283185307179586476925286766559

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST; // Texture coordinates, add the tiling and offset

            sampler2D _Pattern;
            sampler2D _Rock;

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz,1)); // object to world, can use mul(UNITY_MATRIX_M, v.vertex) for the same result. 
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);//scaling and offseting the uv coordinates
                //o.uv.x -= _Time.y * .1;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float GetWave(float coord)
            {

 
                float wave = cos((coord - _Time.y *.1) * TAU * 5)*.5+.5; // will start and end at the same value
                wave *= coord;
                return wave;

            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                float2 topDownProjection = i.worldPos.xz;

                //return float4(topDownProjection,0,1);

                // sample the texture
                fixed4 moss = tex2D(_MainTex, topDownProjection);
                float4 rock = tex2D(_Rock, topDownProjection);
                float pattern = tex2D(_Pattern, i.uv).x;

                float4 finalColor = lerp(rock, moss, pattern);
                
                //GetWave(pattern);
                
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, moss);


                return finalColor;
            }
            ENDCG
        }
    }
}
