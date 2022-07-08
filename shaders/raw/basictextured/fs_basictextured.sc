$input v_wpos, v_wnormal, v_uv // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

SAMPLER2D(s_texAlbedo, 0);
uniform vec3 u_lightDir[4];
uniform vec3 u_lightRgb[4];
uniform vec3 u_baseColor;

vec3 lambertian(int _idx, vec3 _normal)
{
	float val = max(0.0, dot(_normal, u_lightDir[_idx]));
	return u_lightRgb[_idx] * val;
}

void main()
{
	// normalize normal because fragment interpolation
	// of vertex normals will denormalize it
	vec3 normal = normalize(v_wnormal);

	vec3 lightColor;
	lightColor =  lambertian(0, normal);
	lightColor += lambertian(1, normal);
	lightColor += lambertian(2, normal);
	lightColor += lambertian(3, normal);

	// Assume that the texture is already gamma encoded, so
	// exponentiate the rgb values to get 'physical' light intensities
	// back out (this is kind of a hack because most textures
	// are produced by artists by hand and aren't really a
	// principled encoding of any sort)
	vec4 albedo = toLinear(texture2D(s_texAlbedo, v_uv) );

	gl_FragColor.xyz = albedo.xyz * u_baseColor * lightColor;
	gl_FragColor.w = 1.0;
	// convert to gamma so we can use 'physical'
	// light intensities (i.e., not clamped [0,1])
	gl_FragColor = toGamma(gl_FragColor);
}
