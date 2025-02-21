Shader "ShaderStudy/UnlitWavesShader"
{
    Properties //input data
    {
        //_MainTex ("Texture", 2D) = "white" {}
        //_Value ("Value", Float) = 1.0
        
        _ColorA ("Color A", Color) = (1,1,1,1)
        _ColorB ("Color B", Color) = (1,1,1,1)
        _Scale ("UV Scale", float) = 1
        _Offset ("UV offset", float ) = 0
        _ColorStart ("Color Start", Range(0,1)) = 0
        _ColorEnd ("Color End", Range(0, 1)) = 1
    }
    SubShader
    {
        //subshader tags
        Tags { "RenderType"="Transparent" //RenderType is most for tagging purpose, to inform the render pipeline of what type this is, for post process effects
                "Queue"="Transparent"} //Queue is the actual order that things are drawn

        LOD 100

        Pass
        {
            //pass tags

            Cull Off //Back is the default value, means it gets the back faces culling
            Blend One One // additive
            //Blend DstColor Zero // multiply
            ZWrite Off //this shader no longer writes to the depth buffer, but it still reads the depth buffer
            //ZTest Always //Default LEqual, less equal, when this object is less than the object that is already written in the depth buffer, show it.

            CGPROGRAM //equals to HLSL code
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define TAU 6.28318530718

            //sampler2D _MainTex;
            //float4 _MainTex_ST;

            //float _Value;
            float4 _ColorA;
            float4 _ColorB;
            float _Scale;
            float _Offset;
            float _ColorStart;
            float _ColorEnd;

            struct MeshData //appdata
            {
                float4 vertex : POSITION; //local space vertex position
                float3 normals : NORMAL;  // local space normal direction
                float4 tangent : TANGENT; //tangent direction (xyz) and tangent sign(w)
                //float4 color : COCLOR; //vertex color
                float4 uv0 : TEXCOORD0; //uv0 diffuse/normal map/textures
                float4 uv1 : TEXCOORD1; //uv1 coordinates lightmap coordinates
            };

            struct Interpolators //FragmentInputs//v2f
            {
                float4 vertex : SV_POSITION; //clip space position
                float3 normal : TEXCOORD0; //semantic corresponds to a data stream we pass from the vertex shader to the fragment shader
                float2 uv : TEXCOORD1; // TEXCOORDX are the channels we send the data through
                //float4 uv0 : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
            };


            Interpolators vert (MeshData v)
            {
                Interpolators o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);//local space to clip space
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);

                o.normal = UnityObjectToWorldNormal( v.normals);
                o.uv = (v.uv0 + _Offset) * _Scale;
                return o;
            }

            //float (32 bit float)
            //half (16 bit float)
            //fixed (12 bit float , lower precision)
            float InverseLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }

            float4 frag (Interpolators i) : SV_Target
            {
                //float4 myValue;
                //float2 otherValue = myValue.rg; //myValue.gr <- swizzling
              
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                //return float4(UnityObjectToWorldNormal(i.normal), 1);
                //float t = abs(frac(i.uv.x * 5)*2 -1);
                
                //_Time.xyzw // _Time.y is seconds, _Time.z is milliseconds, _Time.w is microseconds(senconds/20)


                float Xoffset =cos( i.uv.x * TAU * 8) *.01;
                float t = cos((i.uv.y + Xoffset - _Time.y *.1) * TAU * 5)*.5+.5; // will start and end at the same value
                //t = t * t * t * t * t; // add some curvature to the curve
                t *= 1-i.uv.y;

                float topBottomRemover = (abs(i.normal.y)<0.999);
                float waves = t * topBottomRemover;
                float4 gradient = lerp(_ColorA, _ColorB, i.uv.y) * waves;
                return gradient ;
            
                //lerp
                //float4 outColor = lerp(_ColorA, _ColorB, i.uv.x);                
                //return outColor;

                //InverseLerp
                //float x = saturate(InverseLerp(_ColorStart, _ColorEnd, i.uv.x));
                float y = saturate(InverseLerp(_ColorStart, _ColorEnd, i.uv.y));
                
                //frac = v - floor(v)
                //y = frac(y);
                //return y;
                float4 outColor;
                outColor = lerp(_ColorA, _ColorB,y);
                //outColor.y = lerp(_ColorA, _ColorB,y);
                return outColor;
            }

            ENDCG
        }
    }
}
