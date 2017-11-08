$input v_wpos, v_wnormal, v_uv // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "../common/common.sh"

SAMPLERCUBE(s_texAlbedo, 0);
uniform vec3 u_baseColor;

void main()
{
  // we've shoved in the viewing direction into the normal,
  // so use that to look up a color in the cubemap
  vec3 viewDir = normalize(v_wnormal.xyz);
  vec4 albedo = textureCube(s_texAlbedo, viewDir);

  gl_FragColor.xyz = albedo.xyz * u_baseColor;
  gl_FragColor.w = 1.0;
}
