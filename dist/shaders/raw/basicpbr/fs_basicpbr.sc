$input v_wpos, v_wnormal, v_viewdir

/*
 * Copyright 2015 Pyry Matikainen.
 * License: MIT
 */

#include "../common/common.sh"
#include "../common/truss_pbr.sh"

uniform vec4 u_lightDir[4];
uniform vec4 u_lightRgb[4];

uniform vec4 u_baseColor;
uniform vec4 u_pbrParams;

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

	// apply specular to first light only
	vec3 diffuse = lambertian(0, normal) * u_baseColor.rgb;
	vec3 spec = specularGGX(viewDir, 
							u_lightDir[0].xyz, 
							normal, 
							u_pbrParams.xyz,
							u_pbrParams.w, 
							u_lightRgb[0].xyz,
							diffuse);
	// vec3 spec = cookTorranceSpecular(viewDir,
	// 								u_lightDir[0].xyz, 
	// 						normal, 
	// 						0.1,
	// 						u_pbrParams.w);
	// totalColor += diffuse;
	totalColor += spec;
	totalColor += lambertian(1, normal) * u_baseColor.rgb;
	totalColor += lambertian(2, normal) * u_baseColor.rgb;
	totalColor += lambertian(3, normal) * u_baseColor.rgb;

	gl_FragColor.xyz = totalColor;
	//gl_FragColor.xyz = viewDir * 0.5 + 0.5;
	gl_FragColor.w = 1.0;
	// convert to gamma so we can use 'physical'
	// light intensities (i.e., not clamped [0,1])
	gl_FragColor = toGamma(gl_FragColor);
}
