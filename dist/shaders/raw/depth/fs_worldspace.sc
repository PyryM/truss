$input v_vpos

/*
 * Copyright 2015 Pyry Matikainen
 * MIT License
 */

#include "common.sh"

void main()
{
  gl_FragColor = vec4(v_vpos.xyz, 1.0);
}
