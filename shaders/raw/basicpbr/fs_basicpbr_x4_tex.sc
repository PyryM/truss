$input v_wpos, v_wnormal, v_viewdir, v_uv

/*
 * Copyright 2015 Pyry Matikainen.
 * License: MIT
 */

#include "common.sh"
#include "../common/truss_pbr.sh"

uniform vec4 u_lightDir[4];
uniform vec4 u_lightRgb[4];

uniform vec4 u_baseColor;
uniform vec4 u_pbrParams;

SAMPLER2D(s_texAlbedo, 0);

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
    //vec4 texalbedo = toLinear(texture2D(s_texAlbedo, v_uv));
    vec3 texalbedo = texture2D(s_texAlbedo, v_uv).rgb * u_baseColor.rgb;

	// apply specular to all four lights
	vec3 diffuse = lambertian(0, normal) * texalbedo;
	vec3 spec = specularGGX(viewDir,
							u_lightDir[0].xyz,
							normal,
							u_pbrParams.xyz,
							u_pbrParams.w,
							u_lightRgb[0].xyz,
							diffuse);
	totalColor += spec;

	diffuse = lambertian(1, normal) * texalbedo;
	spec = specularGGX(viewDir,
							u_lightDir[1].xyz,
							normal,
							u_pbrParams.xyz,
							u_pbrParams.w,
							u_lightRgb[1].xyz,
							diffuse);
	totalColor += spec;

	diffuse = lambertian(2, normal) * texalbedo;
	spec = specularGGX(viewDir,
							u_lightDir[2].xyz,
							normal,
							u_pbrParams.xyz,
							u_pbrParams.w,
							u_lightRgb[2].xyz,
							diffuse);
	totalColor += spec;

	diffuse = lambertian(3, normal) * texalbedo;
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
