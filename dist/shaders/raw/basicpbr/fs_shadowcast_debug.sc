$input v_wpos

/*
 * Copyright 2013-2014 Dario Manesku. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

void main()
{
	gl_FragColor = vec4(v_wpos.z, -v_wpos.z, v_wpos.z, 1.0);
}
