Shader "Unlit/NewUnlitShader"
{
    Properties //input data
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Value ("Value", Float) = 1.0
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Value;

            struct MeshData //appdata
            {
                float4 vertex : POSITION; //vertex position
                float3 normals : NORMAL;
                float4 tangent : TANGENT;
                float4 uv0 : TEXCOORD0; //uv0 diffuse/normal map textures
                float4 uv1 : TEXCOORD1; //uv1 coordinates lightmap coordinates
            };

            struct Interpolators //FragmentInputs//v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv0 : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
            };


            Interpolators vert (appdata v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
