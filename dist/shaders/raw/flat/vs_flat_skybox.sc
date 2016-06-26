$input a_position, a_normal, a_texcoord0
$output v_wpos, v_wnormal, v_uv

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 *
 * Also Copyright 2015 Pyry Matikainen
 */

#include "../common/common.sh"

void main()
{
    // ignore translation component of the view matrix
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
    vec3 viewpos = mul(u_view, vec4(wpos, 0.0)).xyz;
	gl_Position = mul(u_proj, vec4(viewpos, 1.0) );

	vec3 normal = a_normal; // use float normals * 2.0 - 1.0;
	vec3 wnormal = mul(u_model[0], vec4(normal.xyz, 0.0) ).xyz;

	v_wpos = wpos;
	v_wnormal = wnormal;
	v_uv = a_texcoord0;
	v_uv.y = 1.0 - v_uv.y; // flip vertically
}
