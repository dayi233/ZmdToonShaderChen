Shader "Zmd/Common_Outline"
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
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        LOD 100
        Cull Back   

        // ── Pass 1: 本体 ──
        Pass
        {
            Name "Main"
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.5);

                // Shader Info: Cast Shadows
                Light light = GetMainLight();
                float CastShadows = light.shadowAttenuation;
                float3 B = col.rgb * CastShadows;

                // Multiply: A(0.156,0.060,0.040) × B, Fac=0.8
                float3 A = float3(0.156, 0.060, 0.040);
                float3 multiply = lerp(A, A * B, 0.8);

                // Emission: Color=multiply, Strength=0.5
                float3 emission = multiply * 0.5;

                return float4(emission, col.a);
            }
            ENDHLSL
        }

        // ── Pass 2: 描边外壳（平滑描边逻辑） ──
        // Geometry Nodes (A): 法线挤出 → FlipFaces
        // Shader (B): 沿用本 shader 的 A(0.156,0.060,0.040) × B × CastShadows 逻辑
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

                // === A: 法线挤出 ===
                float3 N = TransformObjectToWorldNormal(v.normal);

                // ST 贴图 R 通道调制宽度（默认 0.8）
                float stFactor = 0.8;
                #ifdef _USE_ST
                float4 stCol = tex2Dlod(_STTex, float4(v.uv * _STTex_ST.xy + _STTex_ST.zw, 0, 0));
                stFactor = stCol.r;
                #endif

                float outlineW = _OutlineWidth * stFactor;

                // 顶点色逐通道缩放法线（Blender: Color.RGB → VM.001.Scale → 替代统一宽度）
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

            // 只在背面翻法线（等价于 Blender FlipFaces 节点）
            half4 frag_outline(v2f i, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.5);

                // === FlipFaces: 翻法线 ===
                float3 N = normalize(i.worldNormal);
                N *= isFrontFace ? 1 : -1;

                // === 光照（翻法线后 specular 更亮） ===
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                Light light = GetMainLight();   
                float3 L = light.direction;
                float3 H = normalize(L + V);

                float NdotL = saturate(dot(N, L));
                float NdotH = saturate(dot(N, H));
                float spec = pow(NdotH, 32.0);

                float3 diffuse  = col.rgb * light.color * NdotL * 0.3;
                float3 specular = light.color * spec * col.rgb * 0.5;

                // === B: 沿用本 shader 的 emission 逻辑 ===
                float CastShadows = light.shadowAttenuation;
                float3 texB = col.rgb * CastShadows;
                float3 A_base = float3(0.156, 0.060, 0.040);
                float3 emission = lerp(A_base, A_base * texB, 0.8) * 0.5;

                float3 color = diffuse + specular + emission;
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
                float bias = 0.004 * invNdotL;
                positionWS += normalWS * bias;
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
}
