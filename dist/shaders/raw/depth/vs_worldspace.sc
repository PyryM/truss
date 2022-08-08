$input a_position
$output v_vpos

/*
 * Copyright 2021 Pyry Matikainen
 * MIT License
 */

#include "common.sh"

void main()
{
  v_vpos = mul(u_model[0], vec4(a_position, 1.0) );
  gl_Position = mul(u_viewProj, vec4(v_vpos.xyz, 1.0));
}