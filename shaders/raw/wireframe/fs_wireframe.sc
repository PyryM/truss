$input v_wpos, v_bc

#include "common.sh"

uniform vec4 u_baseColor;
uniform vec4 u_edgeColor;
uniform vec4 u_lineParams;

void main()
{
	float thickness = u_lineParams.x;

	vec3 fw = abs(dFdx(v_bc)) + abs(dFdy(v_bc));
	vec3 val = smoothstep(vec3_splat(0.0), fw*thickness, v_bc);
	float edge = 1.0 - min(min(val.x, val.y), val.z);

	vec4 rgba = edge*u_edgeColor + (1.0 - edge)*u_baseColor;
	gl_FragColor = rgba;
}
