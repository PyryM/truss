$input v_vpos

/*
 * Copyright 2015 Pyry Matikainen
 * MIT License
 */

#include "../common/common.sh"

uniform vec3 u_baseColor;

void main()
{
	float depthMax = 1.0;
	float rawDepth = clamp(v_vpos.z / depthMax, 0.0, 1.0);
	gl_FragColor = vec4(rawDepth, u_baseColor.x, u_baseColor.y, 1.0);
}
