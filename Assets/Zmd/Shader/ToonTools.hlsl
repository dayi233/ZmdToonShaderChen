#pragma once

#ifndef PI
#define PI  3.14159265359
#endif
#ifndef INV_PI
#define INV_PI  0.31830988618379067154
#endif

float3 MF_ColorBlend(float3 BaseColor, float3 BlendColor, float BlendAlpha_A, float Alpha)
{
    float3 a = BaseColor * BlendColor;
    float3 lerp1 = lerp(a, BlendColor, BlendAlpha_A);
    float3 output = lerp(BaseColor, lerp1, Alpha);
    return output;
}

float MF_Adjust(float Input, float Smooth, float Offset)
{
    float output = saturate((Input / Smooth) - Offset);
    return output;
}

float HermiteSmooth(float x)
{
    float output = (x * x * (3 - 2 * x));
    return output;
}

float GGXSpecular(float3 Normal, float3 Light, float Roughness)
{
    float a = dot(Normal, Light);
    float a2 = dot(a, a);
    float Rou = dot(Roughness, Roughness);
    float Rou2 = dot(Rou, Rou);
    float Mid = dot(a2, Rou2 - 1) + 1;
    float Fin = max(1e-06, Mid * Mid * PI);
    float put = Rou2 / Fin;
    return put;
}

float3 FalttenNormal(float3 Normal, float Intensity)
{
    float3 FlatNormal = float3(0, 0, 1);
    float3 output = lerp(Normal, FlatNormal, Intensity);
    return output;
}

float3 DeriveNormalZ(float2 Input)
{
    float2 a = Input * Input;
    float normalz = sqrt(max(0, 1 - a.x - a.y));
    float3 output = float3(a, normalz);
    return output;
}

float3 BlendAngleCorrectedNormals(float3 BaseNormal, float3 AdditionalNormal)
{
    float3 Base1 = float3(BaseNormal.xy, BaseNormal.z + 1);
    float3 Add1 = float3(-1 * AdditionalNormal.xy, AdditionalNormal.z);
    float3 mul1 = Base1 * dot(Base1,Add1);
    float3 mul2 = Base1.z * Add1;
    float3 output = mul1 - mul2;
    return output;
}

float3 DecodeNormal(float x, float y, float normalstrength)
{
    float2 xy = float2(x, y) * 2 - 1;
    float z = sqrt(saturate(1 - dot(xy, xy)));
    return float3(xy, z);
}


float GetinvLenLV(float LoV)
{
    float invLenLV = 1.0 / sqrt(max((LoV * 2 + 2), 0));
    return invLenLV;
}


float Fresnel_Dielectric(float NdotV, float ior)
{
    float cosi = abs(NdotV);
    float eta = max(ior, 0.00001);
    float g = eta * eta - 1.0 + cosi * cosi;

    if (g > 0.0) {
        g = sqrt(g);
        float A = (g - cosi) / (g + cosi);
        float B = (cosi * (g + cosi) - 1.0) / (cosi * (g - cosi) + 1.0);
        return 0.5 * A * A * (1.0 + B * B);
    }
    else {
        return 1.0; // TIR
    }
}

float3 ComputerFresnel0 (float3 BaseColor, float metallic, float dielectricF0)
{
    float3 A = float3(dielectricF0, dielectricF0, dielectricF0);
    float3 output = lerp(A, BaseColor, saturate(metallic));
    return output;
}

float3 Rim_Color(float3 Albedo, float3 dirLightColor, float3 RimColor, float RimStrength, float LdotV)
{
    return RimColor * RimStrength;
}

float3 Outline_Color(float Fresnel_atten,float Vertical_atten)
{
    // Color Ramp: stop0=white(1,1,1)@0, stop1=black(0,0,0)@0.295, Fac=Vertical_atten
    float3 grad1 = lerp(float3(1,1,1), float3(0,0,0), saturate(Vertical_atten / 0.295));
    // Color Ramp: stop0=white(1,1,1)@0, stop1=black(0,0,0)@0.495, Fac=1 - Fresnel_atten
    float3 grad2 = lerp(float3(1,1,1), float3(0,0,0), saturate((1 - Fresnel_atten) / 0.495));
    float3 OutlineColor = grad2 * Fresnel_atten * grad1;
    return OutlineColor;
}

float Directional_light_attenuation(float NoL_Unsaturate, float Directional_Light_Adjust)
{
    float output = lerp(1 - Directional_Light_Adjust, 1, saturate(NoL_Unsaturate));
    return output;
}

float Fresnel_attenuation(float NdotV)
{
    float output = pow(1 - NdotV, 4);
    return output;
}

float3 Remap01ToHalfTexelCoord(float3 coord)
{
    float FGDTEXTURE_RESOLUTION = 64;
    float start = (1 / FGDTEXTURE_RESOLUTION) * 0.5;
    float len = 1 - (1 / FGDTEXTURE_RESOLUTION);
    float3 output = (coord * len) + start;
    return output;
}

float SigmoidSharp(float x, float center, float sharp)
{
    float output = x - center;
    output = output * (sharp * -3);
    output = 1 / (pow(100000, output) + 1);
    return output;
}

float3 directLighting_Diffuse(float3 shadowRampColor, float3 directOcclusion, float3 diffuseColor, float3 dirLightColor)
{
    float3 output = shadowRampColor * diffuseColor * dirLightColor * directOcclusion * 0.318;
    return output;
}

float GetSmithJointGGetSmithJointGGXPartLambdaV(float clampedNdotV, float a2)
{
    float output = (((clampedNdotV * -1 * a2) + clampedNdotV) * clampedNdotV) + a2;
    return output;
}

float DV_SmithJointGGX_Custom(float lambdaV, float NdotH, float Abs_NdotL, float clampedNdotV, float a2)
{
    float s = ((NdotH * a2 - NdotH) * NdotH) + 1;
    float lambdaL = sqrt(((Abs_NdotL * -1 * a2) + Abs_NdotL) * Abs_NdotL + a2) * clampedNdotV;
    float num1 = a2;
    float num2 = max(0, s * s * (lambdaL + lambdaV));
    float output = (INV_PI * 0.5) * (num1 / num2);
    return output;
}

float DV_SmithJointGGXAniso_Custom(float NdotH, float roughnessT, float roughnessB, float TdotH, float BdotH, float AnisoPartLambdaV, float NdotL, float NdotV, float TdotL, float BdotL)
{
    float lambdaL = length(float3(roughnessT * TdotL, roughnessB * BdotL, NdotL)) * NdotV;
    float lambdaV = AnisoPartLambdaV * NdotL;
    float a2_Aniso = roughnessT * roughnessB;
    float3 V = float3(roughnessB * TdotH, roughnessT * BdotH, NdotH * a2_Aniso);
    float S = dot(V, V);
    float2 D = float2(a2_Aniso * a2_Aniso * a2_Aniso, S * S);
    float2 G = float2(1, lambdaL + lambdaV);
    float output = (INV_PI * 0.5) * (D.x * G.x) / max(D.y * G.y, 1e-6);
    return output;
}

void rgb_to_hsv(float3 rgb, out float3 hsv)
{
    float cmax = max(rgb.r, max(rgb.g, rgb.b));
    float cmin = min(rgb.r, min(rgb.g, rgb.b));
    float cdelta = cmax - cmin;

    hsv.z = cmax;
    if (cmax != 0.0)
        hsv.y = cdelta / cmax;
    else {
        hsv.y = 0.0;
        hsv.x = 0.0;
    }

    if (hsv.y == 0.0)
        hsv.x = 0.0;
    else {
        float3 c = (cmax - rgb) / cdelta;
        if (rgb.r == cmax)      hsv.x = c.b - c.g;
        else if (rgb.g == cmax) hsv.x = 2.0 + c.r - c.b;
        else                    hsv.x = 4.0 + c.g - c.r;

        hsv.x /= 6.0;
        if (hsv.x < 0.0) hsv.x += 1.0;
    }
}

void hsv_to_rgb(float3 hsv, out float3 rgb)
{
    if (hsv.y == 0.0) {
        rgb = hsv.z;
    }
    else {
        float h = (hsv.x == 1.0) ? 0.0 : hsv.x;
        h *= 6.0;
        float i = floor(h);
        float f = h - i;
        float p = hsv.z * (1.0 - hsv.y);
        float q = hsv.z * (1.0 - hsv.y * f);
        float t = hsv.z * (1.0 - hsv.y * (1.0 - f));

        if (i == 0.0)      rgb = float3(hsv.z, t, p);
        else if (i == 1.0) rgb = float3(q, hsv.z, p);
        else if (i == 2.0) rgb = float3(p, hsv.z, t);
        else if (i == 3.0) rgb = float3(p, q, hsv.z);
        else if (i == 4.0) rgb = float3(t, p, hsv.z);
        else               rgb = float3(hsv.z, p, q);
    }
}

float3 HSV_Node(float3 Color, float Hue, float Sat, float Val, float Fac)
{
    float3 hsv, rgb;
    rgb_to_hsv(Color, hsv);

    hsv.x = frac(hsv.x + Hue + 0.5);
    hsv.y = clamp(hsv.y * Sat, 0.0, 1.0);
    hsv.z = hsv.z * Val;

    hsv_to_rgb(hsv, rgb);
    return lerp(Color, rgb, Fac);
}

float Desaturation(float Desaturation,float3 color)
{
    float3 In = dot(color, float3(0.213, 0.715, 0.072));
    float3 output = (color - In) * Desaturation + In;
    return output;
}

float3 Recalculate_Normal(float sphereNormal_Strength, float3 headCenter, float3 posWS, float3 normalWS, float ChinMask)
{
    float3 sphereNormal = normalize(posWS - headCenter);
    float3 output = lerp(normalWS, sphereNormal, sphereNormal_Strength);
    output = lerp(output, normalWS, ChinMask);
    return output;
}

float3 Front_Transparent_Red(float smo_max,float Positive_attenuation, float3 sideColor,float D_R,float Pow)
{
    float mid = smoothstep(0, smo_max, pow(D_R, Pow));
    float3 output = lerp(float3(1, 1, 1), sideColor, saturate(mid));
    output = lerp(float3(1, 1, 1), output, saturate(Positive_attenuation));
    return output;
}