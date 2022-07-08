$input v_vpos

/*
 * Copyright 2015 Pyry Matikainen
 * MIT License
 */

#include "common.sh"

void main()
{
	float depthMax = 3.0;
	float rawDepth = clamp(v_vpos.z / depthMax, 0.0, 1.0);
	int idepth = int(rawDepth * 65535.0);
	float b0 = float(idepth % 256) / 255.0;
	float b1 = float((idepth >> 8) % 256) / 255.0;

	gl_FragColor = vec4(b1, b0, 1.0, 1.0);
}
