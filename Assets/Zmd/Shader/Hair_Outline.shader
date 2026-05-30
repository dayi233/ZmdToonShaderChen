Shader "Zmd/Hair_Outline"
{
    Properties
    {
        _OutlineWidth ("Outline Width", Range(0.0001, 0.1)) = 0.001
        [Toggle] _USE_VC ("Use Vertex Color", Float) = 0
        [Toggle] _USE_ST ("Use ST Texture", Float) = 0
        _STTex ("ST Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        LOD 100
        Cull Back

        // ── Pass 1: 头发本体 ──
        Pass
        {
            AlphaToMask On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Shader Info: CastShadows
                Light mainLight = GetMainLight();
                float CastShadows = mainLight.shadowAttenuation;
                float3 finalcol = lerp(float3(0.039,0.039,0.039),CastShadows * float3(0.039,0.039,0.039),0.8);
                clip(0.5); // Alpha Clamp placeholder (threshold 0.5)
                return float4(finalcol, 1);
            }
            ENDHLSL
        }

        // ── Pass 2: 描边外壳（仅新增外扩逻辑） ──
        Pass
        {
            Name "Outline"
            Cull Off

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert_outline
            #pragma fragment frag_outline
            #pragma shader_feature_local _USE_VC
            #pragma shader_feature_local _USE_ST

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            sampler2D _STTex;
            float4 _STTex_ST;
            float _OutlineWidth;

            v2f vert_outline(appdata v)
            {
                v2f o;

                // === A: 法线挤出 ===
                float3 N = TransformObjectToWorldNormal(v.normal);

                float stFactor = 0.8;
                #ifdef _USE_ST
                float4 stCol = tex2Dlod(_STTex, float4(v.uv * _STTex_ST.xy + _STTex_ST.zw, 0, 0));
                stFactor = stCol.r;
                #endif

                float outlineW = _OutlineWidth * stFactor;

                float3 offsetWS;
                #ifdef _USE_VC
                offsetWS = normalize(N) * outlineW * v.color.rgb;
                #else
                offsetWS = normalize(N) * outlineW;
                #endif

                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.vertex = TransformWorldToHClip(worldPos + offsetWS);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldNormal = N;
                return o;
            }

            half4 frag_outline(v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                // === FlipFaces: 只在背面翻法线 ===
                float3 N = normalize(i.worldNormal);
                N *= isFrontFace ? 1 : -1;

                // === 光照 ===
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                Light light = GetMainLight();
                float3 L = light.direction;
                float3 H = normalize(L + V);

                float NdotL = saturate(dot(N, L));
                float NdotH = saturate(dot(N, H));
                float spec = pow(NdotH, 32.0);

                float3 diffuse  = light.color * NdotL * 0.3;
                float3 specular = light.color * spec * 0.5;

                // === 沿用原有 0.039 暗色逻辑 ===
                float CastShadows = light.shadowAttenuation;
                float3 finalcol = lerp(float3(0.039,0.039,0.039),CastShadows * float3(0.039,0.039,0.039),0.8);

                float3 color = diffuse + specular + finalcol;
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
