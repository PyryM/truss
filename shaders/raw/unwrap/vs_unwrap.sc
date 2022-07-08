$input a_position, a_texcoord0
$output v_wpos, v_uv

#include "common.sh"

void main()
{
	v_wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	v_uv = a_texcoord0;
	//v_uv += vec2(0.5/2048.0, 0.5/2048.0);
	//v_uv.x = 1.0 - v_uv.x;
	//v_uv.y = 1.0 - v_uv.y; // flip vertically

	gl_Position = vec4(v_uv.xy * 2.0 - vec2(1.0, 1.0), 0.5, 1.0);
}
