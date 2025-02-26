Shader "ShaderStudy/Healthbar"
{
    Properties
    {
        //_Color ("Color", Color) = (1,1,1,1)
        [NoScaleOffset]_MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Health ("Health", Range(0,1)) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

        Pass
        {
            //Cull Off
            ZWrite Off

            //sourceColor * X + destinationColor * Y //blending formula, src is the color output of this shader, dst is the existing color in the frame buffer we're rendering to
            //src*srcAlpha + dst*(1-srcAlpha) //alpha blending
            Blend SrcAlpha OneMinusSrcAlpha


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 

            #include "UnityCG.cginc"



            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _Health;

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);//change tiling
                o.uv = v.uv;
                return o;
            }

            float InverseLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }

            float4 frag (Interpolators i) : SV_Target
            {
                

                float healthbarMask = _Health > i.uv.x;
                //clip(healthbarMask - 0.001); //if the value is less than zero, it will discard the current fragment being rendered.

                // float tHealthColor = saturate(InverseLerp(0.2,0.8, _Health));
                // float3 healthbarColor = lerp(float3(1,0,0),float3(0,1,0),tHealthColor);

                float3 healthbarCol = tex2D(_MainTex, float2(_Health,i.uv.y));
                //float3 bgColor = float3(0,0,0);
                //float3 outColor = lerp(bgColor,healthbarColor, healthbarMask);

                if(_Health < .2)
                {
                    float flash = cos(_Time.y*6)*.5 + 1;
                    healthbarCol *= flash;
                    //return float4(healthbarCol * flash,1);
                }
                    

                return float4(healthbarCol.xyz*healthbarMask,1);

            }
            ENDCG
        }

    }
    
}
