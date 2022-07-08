$input a_position, a_normal, a_texcoord0
$output v_wpos, v_wnormal, v_viewdir, v_uv

/*
 * Copyright 2015 Pyry Matikainen. All rights reserved.
 * License: MIT
 */

#include "common.sh"

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
    v_uv = a_texcoord0;
	v_uv.y = 1.0 - v_uv.y; // flip vertically
}
