Shader "Zmd/Cloth_Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineWidth ("Outline Width", Range(0.0001, 0.1)) = 0.001
        [Toggle] _USE_VC ("Use Vertex Color", Float) = 0
        [Toggle] _USE_ST ("Use ST Texture", Float) = 0
        _STTex ("ST Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
        LOD 100
        Cull Back

        // ── Pass 1: 本体 ──
        Pass
        {
            Name "Body"
            AlphaToMask On

            HLSLPROGRAM
            #pragma vertex vert_body
            #pragma fragment frag_body

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

            sampler2D _MainTex;

            v2f vert_body(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                return o;
            }

            half4 frag_body(v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.5);

                // B: CastShadows
                Light light = GetMainLight();
                col.rgb *= (0.2 + light.shadowAttenuation * 0.8);

                return col;
            }
            ENDHLSL
        }

        // ── Pass 2: 描边外壳 ──
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

            sampler2D _MainTex;
            sampler2D _STTex;
            float4 _STTex_ST;
            float _OutlineWidth;

            v2f vert_outline(appdata v)
            {
                v2f o;

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
                o.worldPos = worldPos;
                o.worldNormal = N;
                return o;
            }

            half4 frag_outline(v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.5);

                float3 N = normalize(i.worldNormal);
                N *= isFrontFace ? 1 : -1;

                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                Light light = GetMainLight();
                float3 L = light.direction;
                float3 H = normalize(L + V);

                float NdotL = saturate(dot(N, L));
                float NdotH = saturate(dot(N, H));
                float spec = pow(NdotH, 32.0);

                float3 diffuse  = col.rgb * light.color * NdotL * 0.3;
                float3 specular = light.color * spec * col.rgb * 0.5;

                // B: Mix(MULTIPLY) 暗色 — tex × (1-F + darkColor×F), F=0.5
                float3 emission = col.rgb * (0.5 + 0.017 * 0.5) * 0.5;

                // B: CastShadows
                float3 color = (diffuse + specular + emission) * (0.2 + light.shadowAttenuation * 0.8);

                return half4(color, col.a);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata_shadow
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f_shadow
            {
                float4 vertex : SV_POSITION;
            };

            v2f_shadow ShadowVert(appdata_shadow v)
            {
                v2f_shadow o;
                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                float3 normalWS = TransformObjectToWorldNormal(v.normal);
                float3 lightDir = normalize(_MainLightPosition.xyz);
                float invNdotL = 1.0 - saturate(dot(normalWS, lightDir));
                positionWS += normalWS * (0.004 * invNdotL);
                o.vertex = TransformWorldToHClip(positionWS);
                return o;
            }

            half4 ShadowFrag(v2f_shadow i) : SV_Target
            {
                return half4(1, 1, 1, 1);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
