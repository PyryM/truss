$input a_position, a_normal
$output v_wpos, v_wnormal, v_viewdir

/*
 * Copyright 2015 Pyry Matikainen. All rights reserved.
 * License: MIT
 */

#include "../common/common.sh"

void main()
{
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );
	
	vec3 normal = a_normal; // use float normals * 2.0 - 1.0;
	vec3 wnormal = mul(u_model[0], vec4(normal, 0.0) ).xyz;
	vec3 campos = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	v_wpos = wpos;
	v_wnormal = wnormal;
	v_viewdir = normalize(campos - wpos);
}