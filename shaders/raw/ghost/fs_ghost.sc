$input v_wpos, v_wnormal, v_viewdir

/*
 * Copyright 2015 Pyry Matikainen.
 * License: MIT
 */

#include "common.sh"

uniform vec4 u_baseColor;

void main()
{
	// normalize normal because fragment interpolation
	// of vertex normals will denormalize it
	vec3 normal = normalize(v_wnormal);
	vec3 viewDir = normalize(v_viewdir);

	float dp = clamp(dot(normal, viewDir), 0.0, 1.0);

	gl_FragColor = u_baseColor * (1.0 - dp);
}
