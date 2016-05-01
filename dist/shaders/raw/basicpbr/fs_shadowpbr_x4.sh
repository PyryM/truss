/*
 * Copyright 2015 Pyry Matikainen.
 * License: MIT
 */

/*
 * Shadowing code copyright 2013-2014 Dario Manesku. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

 $input v_wpos, v_wnormal, v_viewdir, v_shadowcoord

#include "../common/common.sh"
#include "../common/truss_pbr.sh"
#include "../common/shadowcommon.sh"

uniform vec4 u_lightDir[4];
uniform vec4 u_lightRgb[4];

uniform vec4 u_baseColor;
uniform vec4 u_pbrParams;

SAMPLER2DSHADOW(u_shadowMap, 0);

vec3 lambertian(int _idx, vec3 _normal)
{
	float val = max(0.0, dot(_normal, u_lightDir[_idx].xyz));
	return u_lightRgb[_idx].rgb * val;
}

void main()
{
	// normalize normal because fragment interpolation
	// of vertex normals will denormalize it
	vec3 normal = normalize(v_wnormal);
	vec3 viewDir = normalize(v_viewdir);

	vec3 totalColor = vec3(0,0,0);

	// apply specular to all four lights, but shadow only to first
	vec3 diffuse = lambertian(0, normal) * u_baseColor.rgb;
	vec3 spec = specularGGX(viewDir, 
							u_lightDir[0].xyz, 
							normal, 
							u_pbrParams.xyz,
							u_pbrParams.w, 
							u_lightRgb[0].xyz,
							diffuse);

	float shadowMapBias = 0.005;
	vec2 texelSize = vec2_splat(1.0/512.0);
	float visibility = PCF(u_shadowMap, v_shadowcoord, shadowMapBias, texelSize);
	totalColor += (spec * visibility);

	diffuse = lambertian(1, normal) * u_baseColor.rgb;
	spec = specularGGX(viewDir, 
							u_lightDir[1].xyz, 
							normal, 
							u_pbrParams.xyz,
							u_pbrParams.w, 
							u_lightRgb[1].xyz,
							diffuse);
	totalColor += spec;

	diffuse = lambertian(2, normal) * u_baseColor.rgb;
	spec = specularGGX(viewDir, 
							u_lightDir[2].xyz, 
							normal, 
							u_pbrParams.xyz,
							u_pbrParams.w, 
							u_lightRgb[2].xyz,
							diffuse);
	totalColor += spec;

	diffuse = lambertian(3, normal) * u_baseColor.rgb;
	spec = specularGGX(viewDir, 
							u_lightDir[3].xyz, 
							normal, 
							u_pbrParams.xyz,
							u_pbrParams.w, 
							u_lightRgb[3].xyz,
							diffuse);
	totalColor += spec;

	gl_FragColor.xyz = totalColor;
	//gl_FragColor.xyz = viewDir * 0.5 + 0.5;
	gl_FragColor.w = 1.0;
	// convert to gamma so we can use 'physical'
	// light intensities (i.e., not clamped [0,1])
	gl_FragColor = toGamma(gl_FragColor);
}
