$input v_vpos

/*
 * Copyright 2015 Pyry Matikainen
 * MIT License
 */

#include "../common/common.sh"

uniform vec3 u_baseColor;

void main()
{
	float depthMax = 3.0;
	float rawDepth = clamp(v_vpos.z / depthMax, 0.0, 1.0);
	int idepth = rawDepth * 65535.0;
	float b1 = (float)((idepth >> 8) % 256) / 255.0;

	gl_FragColor = vec4(b1, u_baseColor.x, u_baseColor.y, 1.0);
}
