/*
 * Copyright 2015 Pyry Matikainen
 * License: MIT
 *
 * Much of this is adapted from 
 * http://www.codinglabs.net/article_physically_based_rendering_cook_torrance.aspx
 */

#ifndef TRUSS_PBR_SHADER
#define TRUSS_PBR_SHADER

#include "bgfx_shader.sh"

#define PI 3.14159265359

// computes fresnel term
//
// For a non-metallic material tint = pow(abs((1.0 - ior) / (1.0 + ior)), 2)
//           metallic material tint = (any color)
vec3 fresnelSchlick(float cosT, vec3 tint)
{
  return tint + (1-tint) * pow( 1 - cosT, 5);
}

float chiGGX(float v)
{
    return v > 0.0 ? 1.0 : 0.0;
}

// n: normal,
// h: half-angle vector = normalize(viewdir + lightdir)
float distributionGGX(vec3 n, vec3 h, float alpha)
{
    float NoH = dot(n,h);
    float alpha2 = alpha * alpha;
    float NoH2 = NoH * NoH;
    float den = NoH2 * alpha2 + (1 - NoH2);
    return (chiGGX(NoH) * alpha2) / ( PI * den * den + 0.000001);
}

// this function works, and is from:
// http://graphicrants.blogspot.ca/2013/08/specular-brdf-reference.html
float geometryGGX2(vec3 v, vec3 n, vec3 h, float alpha)
{
    float VoN = dot(v, n);
    VoN = clamp(VoN, 0.025, 1.0);
    float alpha2 = alpha*alpha;

    return (2.0 * VoN) / (VoN + sqrt( alpha2 + (1.0-alpha2)*VoN*VoN ));
}

vec3 specularGGX(vec3 viewDir, vec3 lightDir, vec3 normal, vec3 fresnelTint, float roughness, vec3 lightColor, vec3 diffuseColor)
{
    // Calculate the half vector
    vec3 halfVector = normalize(lightDir + viewDir);

    // Fresnel
    vec3 fresnel = fresnelSchlick(clamp(dot(halfVector, viewDir), 0.0, 1.0), fresnelTint);
    // Geometry term
    float geometryA = geometryGGX2(viewDir, normal, halfVector, roughness);
    float geometryB = geometryGGX2(lightDir, normal, halfVector, roughness);
    float geometry = geometryA * geometryB;
    // Distribution
    float distribution = distributionGGX(normal, halfVector, roughness*roughness);

    // Calculate the Cook-Torrance denominator
    //float denominator = 4 * dot(normal, viewDir) * dot(normal, lightDir);
    float denominator = max(PI * dot(viewDir, normal), 0.05);

    vec3 ks = fresnel;
    vec3 kd = vec3(1.0, 1.0, 1.0) - ks;

    // Accumulate the radiance
    vec3 specRadiance = lightColor * geometry * fresnel * distribution / denominator;
    return specRadiance + diffuseColor * kd;
    //return vec3(distribution, distribution, distribution);
}

float cookTorranceSpecular(vec3 viewDirection, vec3 lightDirection, vec3 surfaceNormal, float fresnel, float roughness)
{

  float VdotN = max(dot(viewDirection, surfaceNormal), 0.0);
  float LdotN = max(dot(lightDirection, surfaceNormal), 0.0);

  //Half angle vector
  vec3 H = normalize(lightDirection + viewDirection);

  //Geometric term
  float NdotH = max(dot(surfaceNormal, H), 0.0);
  float VdotH = max(dot(viewDirection, H), 0.000001);
  float LdotH = max(dot(lightDirection, H), 0.000001);
  float G1 = (2.0 * NdotH * VdotN) / VdotH;
  float G2 = (2.0 * NdotH * LdotN) / LdotH;
  float G = min(1.0, min(G1, G2));
  
  //Distribution term
  float D = distributionGGX(surfaceNormal, H, roughness);

  //Fresnel term
  float F = pow(1.0 - VdotN, fresnel);

  //Multiply terms and done
  return  G * F * D / max(3.14159265 * VdotN, 0.000001);
}


#endif