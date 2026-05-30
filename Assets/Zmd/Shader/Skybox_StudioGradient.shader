Shader "Zmd/Skybox_StudioGradient"
{
    Properties
    {
        _EnvTex ("Environment HDR", Cube) = "" {}
        _EnvStrength ("Environment Blend", Range(0, 1)) = 0.8
        _Rotation ("Rotation Y", Range(0, 360)) = 0
        _Exposure ("Exposure", Float) = 1.0

        // ColorRamp stops (replicating Blender color ramp)
        _Stop0Pos ("Stop0 Pos", Range(0, 1)) = 0.0
        _Stop0Color ("Stop0 Color", Color) = (0.414, 0.414, 0.414, 1)
        _Stop1Pos ("Stop1 Pos", Range(0, 1)) = 0.0284
        _Stop1Color ("Stop1 Color", Color) = (1.1, 1.1, 1.1, 1)
        _Stop2Pos ("Stop2 Pos", Range(0, 1)) = 0.1418
        _Stop2Color ("Stop2 Color", Color) = (0.535, 0.535, 0.535, 1)
        _Stop3Pos ("Stop3 Pos", Range(0, 1)) = 0.3369
        _Stop3Color ("Stop3 Color", Color) = (0.0826, 0.0826, 0.0826, 1)
        _Stop4Pos ("Stop4 Pos", Range(0, 1)) = 0.9909
        _Stop4Color ("Stop4 Color", Color) = (0.0221, 0.0221, 0.0221, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Background" "Queue"="Background" "PreviewType"="Skybox" }
        Cull Off
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURECUBE(_EnvTex);
            SAMPLER(sampler_EnvTex);

            float _EnvStrength;
            float _Rotation;
            float _Exposure;

            float _Stop0Pos, _Stop1Pos, _Stop2Pos, _Stop3Pos, _Stop4Pos;
            float4 _Stop0Color, _Stop1Color, _Stop2Color, _Stop3Color, _Stop4Color;

            struct Attributes
            {
                float4 vertex : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 worldDir : TEXCOORD0;
            };

            // Evaluate 5-stop color ramp at a given position
            float3 EvalColorRamp(float t)
            {
                float3 color;

                if (t <= _Stop0Pos)
                    color = _Stop0Color.rgb;
                else if (t <= _Stop1Pos)
                    color = lerp(_Stop0Color.rgb, _Stop1Color.rgb, (t - _Stop0Pos) / (_Stop1Pos - _Stop0Pos));
                else if (t <= _Stop2Pos)
                    color = lerp(_Stop1Color.rgb, _Stop2Color.rgb, (t - _Stop1Pos) / (_Stop2Pos - _Stop1Pos));
                else if (t <= _Stop3Pos)
                    color = lerp(_Stop2Color.rgb, _Stop3Color.rgb, (t - _Stop2Pos) / (_Stop3Pos - _Stop2Pos));
                else if (t <= _Stop4Pos)
                    color = lerp(_Stop3Color.rgb, _Stop4Color.rgb, (t - _Stop3Pos) / (_Stop4Pos - _Stop3Pos));
                else
                    color = _Stop4Color.rgb;

                return color;
            }

            // Rotate direction around Y axis
            float3 RotateY(float3 dir, float angleRad)
            {
                float c = cos(angleRad);
                float s = sin(angleRad);
                return float3(c * dir.x + s * dir.z, dir.y, -s * dir.x + c * dir.z);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                output.worldDir = input.vertex.xyz;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 dir = normalize(input.worldDir);
                dir = RotateY(dir, _Rotation * (PI / 180.0));

                // Z in Blender = Y up in Unity; normalize to 0~1 on the upper hemisphere
                float t = saturate(dir.y);

                // Sample env cubemap and gradient
                float3 envColor = SAMPLE_TEXTURECUBE_LOD(_EnvTex, sampler_EnvTex, dir, 0).rgb;
                float3 gradientColor = EvalColorRamp(t);

                // Mix: env blends toward gradient (Blender Mix node factor 0.8 → env is 0.2 weight)
                float3 result = lerp(gradientColor, envColor, 1.0 - _EnvStrength);

                result *= _Exposure;
                return half4(result, 1.0);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
