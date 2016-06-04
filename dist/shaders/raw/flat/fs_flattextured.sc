$input v_wpos, v_wnormal, v_uv // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "../common/common.sh"

SAMPLER2D(s_texAlbedo, 0);
uniform vec3 u_baseColor;

void main()
{
	vec4 albedo = texture2D(s_texAlbedo, v_uv);

	gl_FragColor.xyz = albedo.xyz * u_baseColor;
	gl_FragColor.w = 1.0;
}
