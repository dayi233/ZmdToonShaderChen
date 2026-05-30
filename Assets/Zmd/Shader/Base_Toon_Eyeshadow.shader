Shader "Zmd/Base_Toon_Eyeshadow"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Stencil
        {
            Ref  0
            Comp Always
            Pass Replace
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // UV.y → 颜色渐变系数 → Mix Shader Fac
                float rampFac = saturate(i.uv.y);
                float4 col = lerp(float4(1, 1, 1, 0), float4(0, 0, 0, 0), rampFac);
                return col;
            }
            ENDHLSL
        }
    }
}
