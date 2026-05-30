Shader "Zmd/Ground"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UVOffset ("UV Offset X", Float) = 4.7
        _UVScale ("UV Scale", Float) = 2.0
        _DistCenter ("Distance Center", Vector) = (0.5, 0.5, 0, 0)
        _RampLow ("Texture Ramp Low", Range(0, 1)) = 0.277
        _RampHigh ("Texture Ramp High", Range(0, 1)) = 0.577
        _ColorA ("Color A", Color) = (0.225, 0.225, 0.225, 1)
        _ColorB ("Color B", Color) = (0.327, 0.327, 0.327, 1)
        _DistMin ("Distance Bright Min", Color) = (0.614, 0.614, 0.614, 1)
        _DistMax ("Distance Bright Max", Color) = (3.03, 3.03, 3.03, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float _UVOffset;
            float _UVScale;
            float2 _DistCenter;
            float _RampLow;
            float _RampHigh;
            float4 _ColorA;
            float4 _ColorB;
            float4 _DistMin;
            float4 _DistMax;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv1 = i.uv * _UVScale + float2(_UVOffset, 0);
                float texGray = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv1).r;
                float ramp = smoothstep(_RampLow, _RampHigh, texGray);
                float3 mix1 = lerp(_ColorA.rgb, _ColorB.rgb, ramp);

                float dist = distance(i.uv, _DistCenter);
                float d = saturate(dist / 1.0);
                float3 distBright = lerp(_DistMin.rgb, _DistMax.rgb, d);

                float3 result = mix1 * distBright;

                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                Light mainLight = GetMainLight(shadowCoord);
                result *= mainLight.shadowAttenuation;

                return float4(result, 1);
            }
            ENDHLSL
        }
    }
}
