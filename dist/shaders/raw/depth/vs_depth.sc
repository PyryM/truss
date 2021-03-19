$input a_position
$output v_vpos

/*
 * Copyright 2015 Pyry Matikainen
 * MIT License
 */

#include "common.sh"

void main()
{
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	v_vpos = mul(u_viewProj, vec4(wpos, 1.0) );
	
	gl_Position = v_vpos;
}