$input v_wpos, v_wnormal // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "../common/common.sh"

uniform vec4 u_lightDir[4];
uniform vec4 u_lightRgb[4];
uniform vec4 u_baseColor;

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

	vec3 lightColor;
	lightColor =  lambertian(0, normal);
	lightColor += lambertian(1, normal);
	lightColor += lambertian(2, normal);
	lightColor += lambertian(3, normal);

	gl_FragColor.xyz = u_baseColor.rgb * lightColor;
	gl_FragColor.w = 1.0;
	// convert to gamma so we can use 'physical'
	// light intensities (i.e., not clamped [0,1])
	gl_FragColor = toGamma(gl_FragColor);
}
