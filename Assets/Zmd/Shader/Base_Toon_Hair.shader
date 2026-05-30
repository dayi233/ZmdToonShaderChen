Shader "Zmd/Base_Toon_Hair"
{
    Properties
    {
        _DiffuseTex ("Diffuse", 2D) = "white" {}
        _OrmTex ("Orm", 2D) = "black" {}
        _HNnormalTex("HNormal",2D) = "white" {}
        _NormalStrength("Normal Strength",Float) = 0
        _HNormalStrength("HNormal Strength",Float) = 0
        _MetallicMax ("MetallicMax", Float) = 1
        _SmoothnessMax ("SmoothnessMax", Float) = 0
        [HDR] _BaseColor ("Base Color",Color) = (1,1,1,1)
        //HighLight
        _HighLightColorA("HighLight ColorA",Color) = (1,1,1,1)
        _HighLightColorB("HighLight ColorB",Color) = (1,1,1,1)
        _FHighLightPos("FHighLight Pos",Float) = 0
        //Fresnel
        _HighLight_Length("HighLight Length",Float) = 0
        //shadow
        _CastShadow_Center("CastShadow Center",Float) = 0
        _CastShadow_Sharp("CastShadow Sharp",Float) = 0
        _RemapHalfLam_Center("RemapHalfLam Center",Float) = 0
        _RemapHalfLam_Sharp("RemapHalfLam Sharp",Float) = 0
        //Pre integrate GGX FGD
        _GGXFGDDiffuse("GGX FGD Diffuse",2D) = "white" {}
        //dirLight
        [HDR]_SpecularColor("Specular Color",Color) = (1,1,1,1)
        _dirLight_Color("dirLight Color",Color) = (1,1,1,1)
        _directOcclusion("Direct Occlusion",Color) = (1,1,1,1)
        _RampTex("Ramp",2D) = "white" {}
        //BrightnessAdjust
        _ShadowBrightnessAdjust("Shadow Brightness Adjust",Float) = 0
        _ToonFresnelSMO_L("Fresnel SMO_L",Float) = 0
        _ToonFresnelSMO_H("Fresnel SMO_H", Float) = 0
        [HDR]_FresnelColorInside("Fresnel Color Inside",Color) = (1,1,1,1)
        _FresnelColorOutside("Fresnel Color Outside", Color) = (1,1,1,1)
        _ToonFresnelPow("Fresnel Pow", Float) = 0
        //Rim
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimColorStrength("Rim ColorStrength",Float) = 0
        _RimDirLightAtten("Rim DirLight Atten", Float) = 0
        _RimWidthX("Rim WidthX",Float) = 0
        _RimWidthY("Rim WidthY",Float) = 0
        _Final_Brightness("Final Brightness",Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        Cull Back
        ZWrite On

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
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 radialTangentWS : TEXCOORD4;
                float3 worldNormal : TEXCOORD5;
                float  tangentSign : TEXCOORD6; // tangent.w (bitangent handedness)
            };

            sampler2D _DiffuseTex;
            sampler2D _OrmTex;
            sampler2D _HNnormalTex;
            float _NormalStrength;
            float _HNormalStrength;
            float _MetallicMax;
            float _SmoothnessMax;
            float4 _BaseColor;
            float4 _HighLightColorA;
            float4 _HighLightColorB;
            float _FHighLightPos;
            float _HighLight_Length;
            float _CastShadow_Center;
            float _CastShadow_Sharp;
            float _RemapHalfLam_Center;
            float _RemapHalfLam_Sharp;
            sampler2D _GGXFGDDiffuse; 
            float4 _SpecularColor;
            float4 _dirLight_Color;
            float4 _directOcclusion;
            sampler2D _RampTex;
            float _ShadowBrightnessAdjust;
            float _ToonFresnelSMO_L;
            float _ToonFresnelSMO_H;
            float4 _FresnelColorInside;
            float4 _FresnelColorOutside;
            float _ToonFresnelPow;
            float4 _RimColor;
            float _RimColorStrength;
            float _RimDirLightAtten;
            float _RimWidthX;
            float _RimWidthY;
            float _Final_Brightness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                // UV Tangent
                o.tangentWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.tangentSign = v.tangent.w;
                // Radial Tangent (Y-up)
                float3 orco_y = v.vertex.xyz.zyx * float3(-0.5, 0.0, 0.5) + float3(0.25, 0.0, -0.25);
                o.radialTangentWS = TransformObjectToWorldDir(orco_y);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {   
                float4 diffuseTex = tex2D(_DiffuseTex, i.uv);
                float4 ormTex = tex2D(_OrmTex, i.uv);
                float4 HNormalTex = tex2D(_HNnormalTex,i.uv);
                //基本向量
                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);
                float3 V = normalize(i.viewDir);
                float3 N = DecodeNormal(HNormalTex.r,HNormalTex.g,_NormalStrength);
                float3 HN = DecodeNormal(HNormalTex.b,HNormalTex.a,_HNormalStrength);

                // --- Tangent space normal map
                float3 T = normalize(i.tangentWS);
                float3 B = i.tangentSign * cross(i.worldNormal, T);
                // Strength in tangent space (before TBN, 与 GLSL 一致)
                N.xy *= _NormalStrength;
                N.z = lerp(1.0, N.z, saturate(_NormalStrength));
                // TBN transform: tangent space → world space
                N = N.x * T + N.y * B + N.z * i.worldNormal;
                N = normalize(N);

                // HN: same tangent space transform for hair normal
                HN.xy *= _HNormalStrength;
                HN.z = lerp(1.0, HN.z, saturate(_HNormalStrength));
                HN = HN.x * T + HN.y * B + HN.z * i.worldNormal;
                HN = normalize(HN);
                // Shader Info: N → Cast Shadows, Ambient Lighting
                Light mainLight_shadow = GetMainLight();
                float CastShadows = mainLight_shadow.shadowAttenuation;
                float3 AmbientLighting = SampleSH(N);

                //基础数据
                float NdotL_Unsaturate = dot(N,L);
                float NdotV = dot(N,V);
                float LdotV = dot(L,V);
                float ClampNdotV = max(NdotV,0);
                float invLenLV = GetinvLenLV(LdotV);
                float NdotH = saturate((NdotL_Unsaturate + NdotV) * invLenLV);
                float LdotH = saturate((invLenLV * LdotV) + invLenLV);
                float abs_NdotL = abs(NdotL_Unsaturate);
                float ClampNdotL = saturate(NdotL_Unsaturate);
                float RemaphalfLam = NdotL_Unsaturate * 0.5 + 0.5;

                //Alebedo
                float3 albedo = diffuseTex.rgb * _BaseColor;
                //fresnel0
                float metallic = _MetallicMax;
                float3 fresnel0 = ComputerFresnel0(albedo,metallic,0.08);
                //roughness
                float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(_SmoothnessMax);
                float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
                //diffuseColor
                float3 diffuseColor = ComputeDiffuseColor(albedo,metallic);
                //HairLight
                float HairArea = ormTex.r;
                //Pre integrate GGX FGD
                float3 pre = Remap01ToHalfTexelCoord(float3(sqrt(ClampNdotV), perceptualRoughness, 0));
                pre = float3(pre.x, pre.y, 0);
                float4 preSample = tex2D(_GGXFGDDiffuse, pre.xy);
                float3 preFGD = preSample.rgb;
                float diffuseFGD = preFGD.z + 0.5;
                float reflectivity = max(preFGD.y, 1e-6);
                float3 specularFGD = float3(lerp(preFGD.x, preFGD.y, fresnel0.x), lerp(preFGD.x, preFGD.y, fresnel0.y), lerp(preFGD.x, preFGD.y, fresnel0.z));
                float3 F = F_Schlick(fresnel0, 1, LdotH);
                float a2 = roughness * roughness;
                float partLambdaV = GetSmithJointGGetSmithJointGGXPartLambdaV(ClampNdotV,a2);
                float lambdaV = partLambdaV * abs_NdotL;
                float DV = DV_SmithJointGGX_Custom(lambdaV,NdotH,abs_NdotL,ClampNdotV,a2);
                float3 specTerm = F * DV;
                //energyCompensation
                float energyComp = (1 / reflectivity) - 1; 
                float3 energyCompensation = float3(energyComp,energyComp,energyComp);
                //AO
                float AO = ormTex.b;
                float3 directOcclusion = lerp(_directOcclusion.rgb, float3(1,1,1), AO);
                //shadow
                float shadowScene = SigmoidSharp(CastShadows,_CastShadow_Center,_CastShadow_Sharp);
                float shadowNdotL = SigmoidSharp(RemaphalfLam,_RemapHalfLam_Center,_RemapHalfLam_Sharp);
                float shadowmin = min(shadowScene,shadowNdotL);
                float2 shadowArea = float2(shadowmin, 0.5);
                float4 RampTex = tex2D(_RampTex,shadowArea);
                float3 shadowRampColor = RampTex.rgb;
                //directing_Specular
                float3 directing_Specular = ClampNdotL * (specTerm * _SpecularColor) * CastShadows * _dirLight_Color * directOcclusion;
                //directing_Diffuse
                float3 directing_Diffuse = directLighting_Diffuse(shadowRampColor,directOcclusion,diffuseColor,_dirLight_Color);
                // Brightness/Contrast: B=0, C=-0.3 → Ambient * 0.7 + 0.15
                float3 indirectLighting_diffuse = max(0, AmbientLighting * 0.7 + 0.15);
                float3 Mid = ((energyCompensation * fresnel0) + 1) * directing_Specular + directing_Diffuse;
                float3 FacB = diffuseFGD * diffuseColor * indirectLighting_diffuse + Mid + (specularFGD * energyComp);  
                //Shadow Adjust
                float GlobalShadowBrightnessAdjustment = smoothstep(_ShadowBrightnessAdjust, 1, RampTex.a);
                GlobalShadowBrightnessAdjustment = clamp(1, 0, GlobalShadowBrightnessAdjustment);
                //Unity Y=up
                float3 NewV_shifted = normalize(float3(V.x, V.y + _FHighLightPos, V.z));
                float3 NewV = normalize(lerp(NewV_shifted, V, saturate(HairArea)));
                //Binormal
                // Tangent (Radial): orco径向, 对几何法线正交化 (node_tangent)
                float3 tangentRadial = cross(i.worldNormal, normalize(cross(i.radialTangentWS, i.worldNormal)));
                // Tangent (UV): 贴图坐标切线, 仅归一化 (node_tangentmap)
                float3 tangentUV = normalize(i.tangentWS);
                float3 Mixtangent = lerp(tangentRadial, tangentUV, saturate(HairArea));
                float3 Binormal = normalize(cross(Mixtangent,HN));
                float3 AnisoTropic_HighLight = dot(NewV,Binormal);
                float HighLight_Fac = smoothstep(0, 1, sqrt(max(0, AnisoTropic_HighLight * -1)));
                float3 finalcol = lerp(_HighLightColorA,_HighLightColorB,saturate(HighLight_Fac));
                //Fresnel
                float Fresnel = smoothstep(_HighLight_Length,0,abs(AnisoTropic_HighLight));
                Fresnel = Fresnel * ormTex.g * pow(dot(V,HN),5) * ormTex.a;
                finalcol = finalcol * Fresnel;
                finalcol = lerp(finalcol,finalcol * shadowmin,0.9);              
                finalcol = (finalcol + FacB) * GlobalShadowBrightnessAdjustment;
                //Rim                
                float Direction_Light_Atten = Directional_light_attenuation(NdotL_Unsaturate, _RimDirLightAtten);
                float Fresnel_Atten = Fresnel_attenuation(NdotV);
                float Vertical_Atten = i.worldNormal.y * 0.5 + 0.5;
                //Depth_Rim
                float3 N_vs = TransformWorldToViewDir(i.worldNormal);
                float3 num = float3(_RimWidthX * 0.1 * N_vs.x, _RimWidthY * 0.1 * N_vs.y, N_vs.z * 0) + TransformWorldToView(i.worldPos);
                // SceneDepth 有输入: num → 投影 → 采样深度
                float4 clipPos_depth = mul(UNITY_MATRIX_P, float4(num, 1.0));
                float4 screenPos_depth = ComputeScreenPos(clipPos_depth);
                float2 screenUV_depth = screenPos_depth.xy / screenPos_depth.w;
                float depth_input_raw = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV_depth).r;
                float depth_input = LinearEyeDepth(depth_input_raw, _ZBufferParams);

                // SceneDepth 无输入: 当前片段深度
                float2 currentScreenUV = GetNormalizedScreenSpaceUV(i.vertex.xy);
                float depth_self_raw = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, currentScreenUV).r;
                float depth_self = LinearEyeDepth(depth_self_raw, _ZBufferParams);

                float depthDiff = depth_input - depth_self;
                float depthRim = saturate(depthDiff);
                float3 Rim_color = Rim_Color(albedo, _dirLight_Color.rgb, _RimColor.rgb, _RimColorStrength, LdotV);
                float3 rim = Direction_Light_Atten * Fresnel_Atten * Vertical_Atten * depthRim * Rim_color;
                float normalWSdotviewWS = saturate(NdotV);
                float Frepow = pow(normalWSdotviewWS,_ToonFresnelPow);
                float FreSmooth = smoothstep(_ToonFresnelSMO_L, _ToonFresnelSMO_H, Frepow);
                float3 fre = lerp(_FresnelColorOutside.rgb, _FresnelColorInside.rgb, saturate(FreSmooth));

                //额外光源
                for (uint lightIdx = 0; lightIdx < 8; lightIdx++)
                {
                    Light addLight = GetAdditionalLight(lightIdx, i.worldPos, 1);
                    if (addLight.distanceAttenuation <= 0.0) continue;
                    float addNdotL = saturate(dot(N, addLight.direction));
                    float addAtten = addLight.distanceAttenuation * addLight.shadowAttenuation;
                    finalcol += addNdotL * addAtten * addLight.color * diffuseColor * 0.318;
                }
                finalcol = (finalcol * fre + rim) * _Final_Brightness;
                return float4(finalcol, 1);
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
            Cull Off

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
