Shader "Zmd/Base_Toon_Face"
{
    Properties
    {
        _DiffuseTex ("Diffuse", 2D) = "white" {}
        _OrmTex ("Orm", 2D) = "black" {}
        _SphereNormal_Strength("SphereNormal Strength",Float) = 0
        _HeadCenter("HeadCenter", Vector) = (0,0,0,0)
        _HeadForward("HeadForward", Vector) = (0,0,1,0)
        _HeadRight("HeadRight", Vector) = (1,0,0,0)
        _HeadUp("HeadUp", Vector) = (0,1,0,0)
        _SmoothnessMax("Smoothness Max",Float) = 0
        //Albedo
        _Front_R_SMO("Front R SMO",Float) = 0
        _Front_R_Color("Front R Color",Color) = (1,1,1,1)
        _Front_R_Pow("Front R Pow",Float) = 0
        [HDR]_BaseColor("Base Color",Color) = (1,1,1,1)
        //Pre integrate GGX FGD
        _GGXFGDDiffuse("GGX FGD Diffuse",2D) = "white" {}
        //Fresnel
        _MetallicMax("Metallic Max",Float) = 0
        [HDR]_SpecularColor("Specular Color",Color) = (1,1,1,1)
        //dirlight
        _dirLight_Color("dirLight Color",Color) = (1,1,1,1)
        _directOcclusion("Direct Occlusion",Color) = (1,1,1,1)
        //shadow
        _CastShadow_Center("CastShadow Center",Float) = 0
        _CastShadow_Sharp("CastShadow Sharp",Float) = 0
        _RampTex("Ramp",2D) = "white" {}
        //SDF
        _CustmMask("custm Mask",2D) = "white" {}
        _SDFTex("SDF Tex",2D) = "white" {}
        _RemapHalfLam_Center("RemapHalfLam Center",Float) = 0
        _RemapHalfLam_Sharp("RemapHalfLam Sharp",Float) = 0
        //FGD
        [HDR]_AmbientLightColorTint("AmbientLight Color Tint",Color) = (1,1,1,1)
        //BrightnessAdjust
        _ShadowBrightnessAdjust("Shadow Brightness Adjust",Float) = 0
        //Rim
        _Rim_Color("Rim Color",Color) = (1,1,1,1)
        //Nose Shadow
        _Nose_shadow_color("Nose Shadow Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Stencil
            {
                Ref  1
                Comp Always
                Pass Replace
            }

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
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            sampler2D _DiffuseTex;
            sampler2D _OrmTex;
            float _SphereNormal_Strength;
            float4 _HeadCenter;
            float4 _HeadForward;
            float4 _HeadRight;
            float4 _HeadUp;
            float4 _Front_R_Color;
            float _Front_R_Pow;
            float _Front_R_SMO;
            float4 _BaseColor;
            float _MetallicMax;
            float _SmoothnessMax;
            sampler2D _GGXFGDDiffuse;
            float4 _SpecularColor;
            float4 _dirLight_Color;
            float4 _directOcclusion;
            float _CastShadow_Center;
            float _CastShadow_Sharp;
            sampler2D _CustmMask;
            sampler2D _SDFTex;
            float _RemapHalfLam_Center;
            float _RemapHalfLam_Sharp;
            sampler2D _RampTex;
            float4 _AmbientLightColorTint;
            float _ShadowBrightnessAdjust;
            float4 _Rim_Color;
            float4 _Nose_shadow_color;
 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 diffuseTex = tex2D(_DiffuseTex, i.uv);
                float4 ormTex = tex2D(_OrmTex, i.uv);

                // L: 平行光方向
                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);

                // V: 几何数据 引入 (表面→摄像机)
                float3 V = normalize(i.viewDir);
                
                //N
                float3 N = Recalculate_Normal(_SphereNormal_Strength, _HeadCenter.xyz, i.worldPos, i.worldNormal, ormTex.g);

                // Shader Info: N → Cast Shadows, Ambient Lighting
                Light mainLight_shadow = GetMainLight();
                float CastShadows = mainLight_shadow.shadowAttenuation;
                float3 AmbientLighting = SampleSH(N);

                //基础值
                float NdotL_Unsaturate = dot(N,L);
                float NdotV = dot(N,V);
                float LdotV = dot(L,V);
                float ClampNdotV = max(NdotV,0);
                float invLenLV = GetinvLenLV(LdotV);
                float NdotH = saturate((NdotL_Unsaturate + NdotV) * invLenLV);
                float LdotH = saturate((invLenLV * LdotV) + invLenLV);
                float abs_NdotL = abs(NdotL_Unsaturate);
                float ClampNdotL = saturate(NdotL_Unsaturate);
                float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(_SmoothnessMax);
                float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

                //Albedo
                float3 BaseColor = _BaseColor.rgb * diffuseTex.rgb;
                float3 frontRed = Front_Transparent_Red(_Front_R_SMO, dot(_HeadForward.xyz, V), _Front_R_Color.rgb, ormTex.x, _Front_R_Pow);
                BaseColor = lerp(BaseColor,BaseColor * frontRed, CastShadows);
                //fresnel0
                float metallic = _MetallicMax;
                float3 fresnel0 = ComputerFresnel0(BaseColor,metallic,0.08);
                float3 diffuseColor = ComputeDiffuseColor(BaseColor,metallic);

                //Pre integrate GGX FGD
                float3 pre = Remap01ToHalfTexelCoord(float3(sqrt(ClampNdotV), perceptualRoughness, 0));
                pre = float3(pre.x, pre.y, 0);
                float4 preSample = tex2D(_GGXFGDDiffuse, pre.xy);
                float3 preFGD = preSample.rgb;
                float diffuseFGD = preFGD.z + 0.5;
                float reflectivity = max(preFGD.y, 1e-6);
                float3 specularFGD = float3(lerp(preFGD.x, preFGD.y, fresnel0.x), lerp(preFGD.x, preFGD.y, fresnel0.y), lerp(preFGD.x, preFGD.y, fresnel0.z));
                //energyCompensation
                float energyComp = (1 / reflectivity) - 1; 
                float3 energyCompensation = float3(energyComp,energyComp,energyComp);
                float3 finalCol = (energyCompensation * fresnel0) + 1;
                float3 F = F_Schlick(fresnel0, 1, LdotH);
                float a2 = roughness * roughness;
                float partLambdaV = GetSmithJointGGetSmithJointGGXPartLambdaV(ClampNdotV,a2);
                float lambdaV = partLambdaV * abs_NdotL;
                float DV = DV_SmithJointGGX_Custom(lambdaV,NdotH,abs_NdotL,ClampNdotV,a2);
                float3 specTerm = F * DV;
                //Angel
                float3 lightDirectionProjHeadWS = normalize(L - (dot(L,_HeadUp) * _HeadUp));
                float Flip_threshold = dot(lightDirectionProjHeadWS,_HeadRight);
                float sZ = dot(lightDirectionProjHeadWS,_HeadForward.xyz * -1);
                float angel = atan2(Flip_threshold, sZ);
                angel = angel / PI;
                float angleThreshold = lerp(angel + 1,1 - angel,saturate(angel > 0));
                float Flip_threshold_above = Flip_threshold > 0;
                float AngelUV_x = lerp(1 - i.uv.x,i.uv.x,saturate(Flip_threshold_above));
                float2 AngelUV = float2(AngelUV_x,i.uv.y);
                float4 SDFTex = tex2D(_SDFTex,AngelUV);
                float SDFmin = SigmoidSharp((SDFTex.x + SDFTex.y) / 2,angleThreshold + _RemapHalfLam_Center,_RemapHalfLam_Sharp);
                SDFmin = min(SDFmin,CastShadows);

                //SDF
                // Camera Data Node
                float3 viewVector = mul(UNITY_MATRIX_V, float4(-V, 0.0)).xyz; // 视图矢量 (View Space)
                float viewDistance = distance(_WorldSpaceCameraPos, i.worldPos); // 视图距离
                // Map Range: viewDistance [0,1] → [0,7.2] + 1
                float mapResult = viewDistance * 7.2 + 1;
                // Mapping Node: Location(0.01,0.03,0), Rotation不变, Scale=mapResult
                float3 ViewPos = viewVector * mapResult + float3(0.01, 0.03, 0);
                // ScreenSpace Info: ViewPos → Scene Depth
                float4 clipPos_SDF = mul(UNITY_MATRIX_P, float4(ViewPos, 1.0));
                float4 screenPos_SDF = ComputeScreenPos(clipPos_SDF);
                float2 screenUV_SDF = screenPos_SDF.xy / screenPos_SDF.w;
                float SDFSceneDepth_raw = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV_SDF).r;
                float SDFSceneDepth = LinearEyeDepth(SDFSceneDepth_raw, _ZBufferParams);
                // ScreenSpace Info: 无输入 → Scene Depth (当前片段深度)
                float2 currentScreenUV_SDF = GetNormalizedScreenSpaceUV(i.vertex.xy);
                float SelfSceneDepth_raw = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, currentScreenUV_SDF).r;
                float SelfSceneDepth = LinearEyeDepth(SelfSceneDepth_raw, _ZBufferParams);
                float depthDiff = SelfSceneDepth - SDFSceneDepth;
                float sdfLessThan = depthDiff < 0.005;
                // Texture Coordinate → UV.y → Color Ramp (黑到白, stop at 0.386)
                float3 sdfRamp = saturate((i.uv.y - 0.386) / (1.0 - 0.386));
                float4 csutmMask = tex2D(_CustmMask,i.uv);
                float SDFshadow = lerp(sdfRamp, float3(1,1,1), saturate(csutmMask.z)).r;
                SDFshadow = SDFshadow > csutmMask.x;
                SDFshadow = sdfLessThan < SDFshadow;
                SDFshadow = max(0,(1 - SDFshadow) + 0.1);
                float Fac = dot(V,_HeadUp) * 0.5 + 0.5;
                // Map Range: Fac [0.5,1] → [1,0] (钳制)
                Fac = saturate(2.0 * (1.0 - clamp(Fac, 0.5, 1.0)));
                Fac = max(smoothstep(0.5, 1, Fac), 0);
                SDFshadow = lerp(1,SDFshadow,saturate(Fac));
                SDFshadow = min(SDFshadow,SDFmin);


                //Remove Shadows
                float Remove_shadows = lerp(1,CastShadows,saturate(ormTex.g));
                //shadow
                float shadowScene = SigmoidSharp(Remove_shadows,_CastShadow_Center,_CastShadow_Sharp);
                float chinLambertShadow = SigmoidSharp(NdotL_Unsaturate * 0.5 + 0.5,0.5,0.1);
                float2 shadowArea = float2(min(shadowScene,lerp(SDFshadow,chinLambertShadow,saturate(ormTex.g))),0.5);
                float4 RampTex = tex2D(_RampTex,shadowArea);
                float3 shadowRampColor = RampTex.rgb;
                //directing_Specular
                float3 directing_Specular = ClampNdotL * (specTerm * _SpecularColor) * Remove_shadows * _dirLight_Color * _directOcclusion;
                //directing_Diffuse
                float3 directing_Diffuse = directLighting_Diffuse(shadowRampColor,_directOcclusion,diffuseColor,_dirLight_Color);

                float3 indirectLighting_diffuse = lerp(max(float3(0,0,0),AmbientLighting * 0.7 + 0.15),AmbientLighting,saturate(ormTex.g));
                
                finalCol = finalCol * directing_Specular + directing_Diffuse;
                //FGD
                float3 FGD1 = (diffuseFGD * diffuseColor) * (indirectLighting_diffuse * _AmbientLightColorTint);
                float3 FGD2 = specularFGD * float3(0.02,0.02,0.02); 
                finalCol = finalCol + FGD1 + FGD2;

                //Shadow Adjust
                float GlobalShadowBrightnessAdjustment = smoothstep(_ShadowBrightnessAdjust, 1, RampTex.a);
                GlobalShadowBrightnessAdjustment = clamp(1, 0, GlobalShadowBrightnessAdjustment);
                finalCol = finalCol * GlobalShadowBrightnessAdjustment;
                //Rim
                float RimA = i.uv.x > 0.5; 
                RimA = lerp(RimA,1 - RimA,saturate(Flip_threshold_above));
                RimA = RimA * ormTex.a - angleThreshold;
                RimA = saturate(RimA * smoothstep(0,0.2,angleThreshold) * smoothstep(0.8,1.0,dot(_HeadForward,V)));
                float3 Rim = RimA * _Rim_Color;
                finalCol = finalCol + Rim;
                //额外光源
                for (uint lightIdx = 0; lightIdx < 8; lightIdx++)
                {
                    Light addLight = GetAdditionalLight(lightIdx, i.worldPos, 1);
                    if (addLight.distanceAttenuation <= 0.0) continue;
                    float addNdotL = saturate(dot(N, addLight.direction));
                    float addAtten = addLight.distanceAttenuation * addLight.shadowAttenuation;
                    finalCol += addNdotL * addAtten * addLight.color * diffuseColor * 0.318;
                }
                //Nose Shadow
                float3 noseshadow = lerp(_Nose_shadow_color,float3(1,1,1),diffuseTex.a);
                finalCol = finalCol * noseshadow;

                float alpha = lerp(1.15, 1.3, saturate(csutmMask.y > 0.5));
                finalCol = finalCol * alpha;
                return float4(finalCol, 1);
            }
            ENDHLSL
        }
    }
}
