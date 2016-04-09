$input a_position, a_normal
$output v_wpos, v_wnormal

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "../common/common.sh"

void main()
{
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );
	
	vec4 normal = a_normal; // use float normals * 2.0 - 1.0;
	vec3 wnormal = mul(u_model[0], vec4(normal.xyz, 0.0) ).xyz;

	v_wpos = wpos;
	v_wnormal = wnormal;
}