Shader "ShaderStudy/RoundedEdgeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _BorderSize("Border Size", Range(0, 0.5)) = 0.1
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _BorderSize;

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                float2 coords = i.uv;
                coords.x *=10;

                float2 pointOnLineSeg = float2(clamp(coords.x,0.5,9.5),0.5);
                float sdf = distance(coords, pointOnLineSeg)*2 - 1;

                float borderSdf = sdf + _BorderSize;
                float pd = fwidth(borderSdf);//fwidth() is like fragment's width,is a simple way to get the rate of change
                                            //fwidth(borderSdf)is the screen space partial derivative of the Signed Distance Field
                //float borderMask = step(borderSdf,0);
                float borderMask = 1-saturate(borderSdf/pd); //will have a range of 0 to 1 along the border

                clip(-sdf);

                return float4(borderMask.xxx,1);
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
