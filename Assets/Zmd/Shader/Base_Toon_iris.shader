Shader "Zmd/Base_Toon_iris"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EyePush ("Eye Push", Range(0, 0.1)) = 0.01
        _HeadCenter("HeadCenter", Vector) = (0,0,0,0)
        _HeadForward("HeadForward", Vector) = (0,0,1,0)
        _HeadRight("HeadRight", Vector) = (1,0,0,0)
        _HeadUp("HeadUp", Vector) = (0,1,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // 阴影和多光源关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile _ _FORWARD_PLUS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "ToonTools.hlsl"

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
                float3 viewDir : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float  eyeDepth : TEXCOORD4;
                float3 worldNormal : TEXCOORD5;
            };

            sampler2D _MainTex;
            float _EyePush;
            float4 _HeadCenter;
            float4 _HeadForward;
            float4 _HeadRight;
            float4 _HeadUp;

            v2f vert (appdata v)
            {
                v2f o;

                // 眼透位移: 顶点向摄像机方向推（对应 Blender GN: Camera→Vertex Normalize → Scale → SetPosition）
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                float3 toCamera = normalize(_WorldSpaceCameraPos - worldPos);
                worldPos += toCamera * _EyePush;

                o.vertex = TransformWorldToHClip(worldPos);
                o.uv = v.uv;
                o.worldPos = worldPos;
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.eyeDepth = distance(_WorldSpaceCameraPos, worldPos);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {   
                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);
                // Geometry: Incoming
                float3 V = normalize(i.viewDir);
                //Angel
                float3 lightDirectionProjHeadWS = normalize(L - (dot(L,_HeadUp) * _HeadUp));
                float Flip_threshold = dot(lightDirectionProjHeadWS,_HeadRight);
                float sZ = dot(lightDirectionProjHeadWS,_HeadForward.xyz * -1);
                float angel = atan2(Flip_threshold, sZ);
                angel = angel / PI;
                float angleThreshold = lerp(angel + 1,1 - angel,saturate(angel > 0));

                float4 col = tex2D(_MainTex, i.uv);
                float3 finalcol = col.rgb * clamp((1 - angleThreshold), 0.5, 1.0);
                finalcol = finalcol * lerp(1.1,4.0,saturate(col.a));
                // Eyes: 深度缓冲
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float sceneRaw = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
                float sceneDepth = LinearEyeDepth(sceneRaw, _ZBufferParams);
                float eyevalue = sceneDepth < i.eyeDepth - 0.001 ? 1.0 : 0.0;

                //Alpha
                float mid = dot(_HeadForward,V);
                float fac = saturate((smoothstep(0.35,1,mid)- 0.7) * (1 - eyevalue));
                // 替换材质 Alpha版：前层(alphacol,alpha=fac) 叠 后层(finalcol)
                float3 alphacol = col.rgb * 1.4;
                float3 result = lerp(finalcol, alphacol, fac);
                //额外光源
                for (uint lightIdx = 0; lightIdx < 8; lightIdx++)
                {
                    Light addLight = GetAdditionalLight(lightIdx, i.worldPos, 1);
                    if (addLight.distanceAttenuation <= 0.0) continue;
                    float addNdotL = saturate(dot(i.worldNormal, addLight.direction));
                    float addAtten = addLight.distanceAttenuation * addLight.shadowAttenuation;
                    result += addNdotL * addAtten * addLight.color * col.rgb * 0.318;
                }
                return float4(result, 1);
            }
            ENDHLSL
        }
    }
}
