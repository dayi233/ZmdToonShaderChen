Shader "Zmd/Base_Toon_Body"
{
    Properties
    {
        [Header(Main)]
        _MainTex ("Alebdo", 2D) = "white" {}
        _Normal ("Normal", 2D) = "black" {}
        _OrmTex ("Orm", 2D) = "black" {}
        _EmiTex ("Emission",2D) = "black" {}
        _EmiColor ("自发光颜色", Color) = (0,0,0,0)
        [HDR] _BaseColor ("Base Color",Color) = (1,1,1,1)
        _NormalStrength ("Normal Strength", Float) = 1
        _MetallicMax ("MetallicMax", Float) = 1
        _SmoothnessMax ("SmoothnessMax", Float) = 0
        _Aniso_SmoothnessMaxT("Aniso SmoothnessMaxT",Float) = 0
        _Aniso_SmoothnessMaxB("Aniso SmoothnessMaxB",Float) = 0
        _directOcclusionColor("Direct Occlusion", Color) = (0, 0, 0, 1)
        [Header(Rim)]
        _dirLight_lightColor("DirLight LightColor", Color) = (1,1,1,1)
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimColorStrength("Rim ColorStrength",Float) = 0
        _RimDirLightAtten("Rim DirLight Atten", Float) = 0
        _RimWidthX("Rim WidthX",Float) = 0
        _RimWidthY("Rim WidthY",Float) = 0

        [Header(Fresnel)]
        _ToonFresnelPow("Fresnel Pow", Float) = 0
        _ToonFresnelSMO_L("Fresnel SMO_L",Float) = 0
        _ToonFresnelSMO_H("Fresnel SMO_H", Float) = 0
        [HDR] _FresnelColorInside("Fresnel Color Inside",Color) = (1,1,1,1)
        [HDR] _FresnelColorOutside("Fresnel Color Outside", Color) = (1,1,1,1)

        [Header(Global Shadow)]
        _GlobalShadowAd("Global Shadow Adjust",Float) = 0

        [Header(Indirect Lighting Diffuse)]
        [HDR]_AmbientLightColorTint("Ambient LightColor Tint",Color) = (0,0,0,1)

        [Header(GGX FGD)]
        _GGXFGDDiffuse("GGXFGD", 2D) = "white" {}

        [Header(Shadow)]
        _CastShadow_Center("CastShadow Center", Float) = 0
        _CastShadow_Sharp("CastShadow Sharp", Float) = 0
        _RemapHalfLam_Center("RemaphalfLam Center", Float) = 0
        _RemapHalfLam_Sharp("RemaphalfLam Sharp", Float) = 0
        _RampIndex("RampIndex", Float) = 0
        _Cloth_Ramp("Cloth Ramp",2D) = "white" {}
        _Body_Ramp("Body Ramp",2D) = "white" {}

        [Header(Specular)]
        [HDR] _SpecularColor("Specular Color",Color) = (1,1,1,1)
        _Anisotropic_mask("AnisoTropic Mask",Float) = 0

        [Header(Toggles)]
        [Toggle(_USENORMALTEX)] _UseNormalTex("Use NormalTex", Float) = 0
        [Toggle(_ISSKIN)] _IsSkin("Is Skin", Float) = 0
        [Toggle(_USETOONANISO)] _UseToonAniso("Use Toon Aniso", Float) = 0
        [Toggle(_USEANISOTROPY)] _UseAnisoTropy("Use AnisoTropic", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100

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
            #include "ToonTools.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 biTangentWS : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
            };

            //采样纹理
            sampler2D _MainTex;
            sampler2D _Normal;
            sampler2D _OrmTex;
            sampler2D _EmiTex;
            float4 _EmiColor;
            float _NormalStrength;
            float _UseNormalTex;
            float _Aniso_SmoothnessMaxT;
            float _Aniso_SmoothnessMaxB;
            float _SmoothnessMax;
            float _IsSkin;
            float4 _directOcclusionColor;
            float _MetallicMax;
            float4 _BaseColor;
            float4 _dirLight_lightColor;
            float4 _RimColor;
            float _RimColorStrength;
            float _RimDirLightAtten;
            float _RimWidthX;
            float _RimWidthY;
            float _ToonFresnelPow;
            float _ToonFresnelSMO_L;
            float _ToonFresnelSMO_H;
            float4 _FresnelColorInside;
            float4 _FresnelColorOutside;
            float _GlobalShadowAd;
            float4 _AmbientLightColorTint;
            sampler2D _GGXFGDDiffuse;
            float _CastShadow_Center;
            float _CastShadow_Sharp;
            float _RemapHalfLam_Center;
            float _RemapHalfLam_Sharp;
            float _RampIndex;
            sampler2D _Cloth_Ramp;
            sampler2D _Body_Ramp;
            float _UseToonAniso;
            float _Anisotropic_mask;
            float _UseAnisoTropy;
            float4 _SpecularColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.tangentWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.biTangentWS = cross(o.worldNormal,o.tangentWS) * v.tangent.w;
                o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float4 ormTex = tex2D(_OrmTex, i.uv);
                float4 normalTex = tex2D(_Normal,i.uv);
                float4 mainTex = tex2D(_MainTex, i.uv);
                float3 normalTS = DecodeNormal(normalTex.x, normalTex.y, _NormalStrength);


                //计算基础向量
                Light mainLight = GetMainLight();
                float3 T = normalize(i.tangentWS);
                float3 B = normalize(i.biTangentWS);
                // Tangent space → world space
                normalTS.xy *= _NormalStrength;
                normalTS.z = lerp(1.0, normalTS.z, saturate(_NormalStrength));
                float3 normalWS = normalTS.x * T + normalTS.y * B + normalTS.z * i.worldNormal;
                normalWS = normalize(normalWS);
                float3 L = normalize(mainLight.direction);
                float3 N = normalize(lerp(i.worldNormal, normalWS, _UseNormalTex));
                float3 V = normalize(i.viewDir);

                //得到点积值
                float TdotL = dot(T,L);
                float TdotV = dot(T,V);
                float BdotL = dot(B,L);
                float BdotV = dot(B,V);
                float NoL_Unsaturate = dot(L,N);
                float NdotV = dot(N,V);
                float LdotV = dot(L,V);
                float invLenLV = GetinvLenLV(LdotV);
                float NdotH = saturate((NoL_Unsaturate + NdotV) * invLenLV);
                float LdotH = saturate((invLenLV * LdotV) + invLenLV);
                float TdotH = saturate((TdotV + TdotL) * invLenLV);
                float BdotH = saturate((BdotV + BdotL) * invLenLV);

                // Shader Info: N → Cast Shadows, Ambient Lighting
                Light mainLight_shadow = GetMainLight();
                float CastShadows = mainLight_shadow.shadowAttenuation;
                float3 AmbientLighting = SampleSH(N);

                //计算基本参数
                float Toon_Aniso = saturate(dot(cross(N,T),V));
                float Abs_NdotL = abs(NoL_Unsaturate);
                float clampedNdotL = saturate(NoL_Unsaturate);
                float clampedNdotV = max(0, NdotV);
                float RemaphalfLam = NoL_Unsaturate * 0.5 + 0.5;
                float normalWSdotviewWS = saturate(NdotV);

                //OrmTex_A通道处理
                float SmoothnessMaxT = lerp(0, _Aniso_SmoothnessMaxT, saturate(ormTex.a));
                float SmoothnessMaxB = lerp(0, _Aniso_SmoothnessMaxB, saturate(ormTex.a));
                float SmoothnessMax = lerp(0, _SmoothnessMax, saturate(ormTex.a));
                float roughnessT = PerceptualRoughnessToRoughness(PerceptualSmoothnessToPerceptualRoughness(SmoothnessMaxT));
                float roughnessB = PerceptualRoughnessToRoughness(PerceptualSmoothnessToPerceptualRoughness(SmoothnessMaxB));
                float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(SmoothnessMax);
                float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
                
                //Alebdo
                float3 albedo = mainTex.rgb * _BaseColor;

                //OrmTex_B通道处理
                float AO = lerp(ormTex.b, mainTex.a, saturate(_IsSkin));
                float4 directOccusion = lerp(_directOcclusionColor, float4(1,1,1,1), AO);

                //OrmTex_R通道处理
                float metallic = lerp(0,_MetallicMax,saturate(ormTex.r));
                float3 fresnel0 = ComputerFresnel0(albedo,metallic,0.08);
                float3 diffuseColor = ComputeDiffuseColor(albedo,metallic);


                //Specular BRDF
                float a2 = roughness * roughness;
                float partLambdaV = GetSmithJointGGetSmithJointGGXPartLambdaV(clampedNdotV,a2);
                float lambdaV = partLambdaV * Abs_NdotL;
                float DV = DV_SmithJointGGX_Custom(lambdaV,NdotH,Abs_NdotL,clampedNdotV,a2);
                float AnisoPartLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV,BdotV,NdotV,roughnessT,roughnessB);
                float AnisoDV = DV_SmithJointGGXAniso_Custom(NdotH,roughnessT,roughnessB,TdotH,BdotH,AnisoPartLambdaV,Abs_NdotL,NdotV,TdotL,BdotL);
                float3 F = F_Schlick(fresnel0,1.0,LdotH);
                float3 specTermAniso = F * AnisoDV;
                float3 specTerm = F * DV;
                float3 spe = lerp(specTermAniso, float3(Toon_Aniso, Toon_Aniso, Toon_Aniso), saturate(_UseToonAniso));
                spe = spe * _Anisotropic_mask;
                spe = lerp(specTerm,spe,saturate(_UseAnisoTropy));
                spe = spe * _SpecularColor.rgb;

                float3 finalcol = spe * clampedNdotL * CastShadows * _dirLight_lightColor.rgb * directOccusion;

                //Diffuse BRDF
                float shadowScene = SigmoidSharp(CastShadows,_CastShadow_Center,_CastShadow_Sharp);
                float shadowNdotL = SigmoidSharp(RemaphalfLam,_RemapHalfLam_Center,_RemapHalfLam_Sharp);
                float2 shadowArea = float2(min(shadowNdotL,shadowScene),0.5);
                float4 RD0  = tex2D(_Cloth_Ramp,shadowArea);
                float4 RD1 =  tex2D(_Body_Ramp,shadowArea);
                float3 RampColor = lerp(RD0.rgb,RD1.rgb,saturate(_RampIndex));
                float RampAlpha = lerp(RD0.a,RD1.a,saturate(_RampIndex));
                //DirLighting_Diffuse
                float3 DirectLighting_diffuse = directLighting_Diffuse(RampColor, directOccusion.xyz, diffuseColor, _dirLight_lightColor.rgb);
                //Pre integrate GGX FGD
                float3 pre = Remap01ToHalfTexelCoord(float3(sqrt(clampedNdotV), perceptualRoughness, 0));
                pre = float3(pre.x, pre.y, 0);
                float4 preSample = tex2D(_GGXFGDDiffuse, pre.xy);
                float3 preFGD = preSample.rgb;
                float diffuseFGD = preFGD.z + 0.5;
                float reflectivity = max(preFGD.y, 1e-6);
                float3 specularFGD = float3(lerp(preFGD.x, preFGD.y, fresnel0.x), lerp(preFGD.x, preFGD.y, fresnel0.y), lerp(preFGD.x, preFGD.y, fresnel0.z));
                float energyCompensation = (1 / reflectivity) - 1;
                float3 mid = float3(energyCompensation,energyCompensation,energyCompensation) * fresnel0 + 1;
                
                finalcol = finalcol * mid + DirectLighting_diffuse;
                //indirectingLighting
                float3 indirectingLighting_diffuse = AmbientLighting * _AmbientLightColorTint.rgb;

                float3 FGD1 = diffuseFGD * diffuseColor * indirectingLighting_diffuse;
                float3 FGD2 = specularFGD * energyCompensation;

                //Shadow Adjust
                float GlobalShadowBrightnessAdjustment = smoothstep(_GlobalShadowAd, 1, RampAlpha);
                GlobalShadowBrightnessAdjustment = clamp(1, 0, GlobalShadowBrightnessAdjustment);

                finalcol = (finalcol + FGD1 + FGD2) * GlobalShadowBrightnessAdjustment;
                //Fresnel
                float Frepow = pow(normalWSdotviewWS,_ToonFresnelPow);
                float FreSmooth = smoothstep(_ToonFresnelSMO_L, _ToonFresnelSMO_H, Frepow);
                float3 Fresnel = lerp(_FresnelColorOutside.rgb, _FresnelColorInside.rgb, saturate(FreSmooth));
                //Rim                
                float3 RimColor = Rim_Color(albedo, _dirLight_lightColor.rgb, _RimColor.rgb, _RimColorStrength, LdotV);
                float Direction_Light_Atten = Directional_light_attenuation(NoL_Unsaturate, _RimDirLightAtten);
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
                float3 Rim = Direction_Light_Atten * Fresnel_Atten * Vertical_Atten * depthRim * RimColor;

                //Emission
                float4 EmiTex = tex2D(_EmiTex, i.uv);
                float3 emission = EmiTex.xyz * _EmiColor.xyz;
                
                finalcol = finalcol * Fresnel + Rim + emission;
                //额外光源
                for (uint lightIdx = 0; lightIdx < 8; lightIdx++)
                {
                    Light addLight = GetAdditionalLight(lightIdx, i.worldPos, 1);
                    if (addLight.distanceAttenuation <= 0.0) continue;
                    float addNdotL = saturate(dot(N, addLight.direction));
                    float addAtten = addLight.distanceAttenuation * addLight.shadowAttenuation;
                    finalcol += addNdotL * addAtten * addLight.color * diffuseColor * 0.318;
                }
                //Clip
                float clip = _IsSkin > 0.5;
                clip = lerp(mainTex.a,1,saturate(clip));
                //output
                finalcol = finalcol * 1.1;


                // Mix Shader: A=Transparent(1,1,1,0), B=finalcol, Fac=clip
                return lerp(float4(1,1,1,0), float4(finalcol, 1), clip);
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
