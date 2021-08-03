$input a_position
$output v_wpos, v_vdir, v_lightdir

/*
 * Copyright 2020 Pyry Matikainen
 */

#include "common.sh"

uniform mat4 u_invModel;
uniform vec4 u_lightDir;

void main()
{
  vec4 wpos = vec4(a_position, 1.0); 

  // Why this works: suppose the current point is x,
  // then transformed to clip space x' = P*x (and x = inv(P)*x')
  // in clip space, the point y' = (x' + [0,0,1,0]) is along the same view ray
  // back to world space: y = inv(P)*(x' + [0,0,1,0]) = x + inv(P)*[0,0,1,0]
  // Then we compute viewdir = y - x, after doing w-division on y
  v_vdir = wpos + mul(u_invModel, mul(u_invViewProj, vec4(0.0, 0.0, 1, 0.0)));
  v_vdir /= v_vdir.w;
  v_vdir -= wpos;
  v_wpos = wpos.xyz;

  v_lightdir = normalize(mul(u_invModel, vec4(u_lightDir.xyz, 0.0)).xyz);

  gl_Position = mul(u_viewProj, mul(u_model[0], wpos));
}
