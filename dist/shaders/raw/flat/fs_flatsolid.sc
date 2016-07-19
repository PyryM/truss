$input v_wpos, v_wnormal, v_uv // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "../common/common.sh"

uniform vec3 u_baseColor;

void main()
{
	gl_FragColor.xyz = u_baseColor;
	gl_FragColor.w = 1.0;
}
