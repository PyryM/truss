$input a_position, a_normal, a_texcoord0
$output v_wpos, v_wnormal, v_uv

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 *
 * Also Copyright 2015 Pyry Matikainen
 */

#include "common.sh"

void main()
{
  // figure out world viewing direction
  vec3 campos = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz;
  vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
  gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );

  v_wpos = wpos;
  // shove viewing direction into normal
  // (don't bother to normalize because we do that in fragment shader anyway)
  v_wnormal = wpos - campos; // - wpos;
  v_wnormal.x = -v_wnormal.x; // not sure why I have to negate this
  v_uv = a_texcoord0;
  v_uv.y = 1.0 - v_uv.y; // flip vertically
}
