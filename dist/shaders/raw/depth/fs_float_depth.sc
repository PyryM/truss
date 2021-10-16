$input v_vpos

/*
 * Copyright 2015 Pyry Matikainen
 * MIT License
 */

#include "common.sh"

void main()
{
  float rawDepth = v_vpos.z;
  gl_FragColor = vec4(rawDepth, 0.0, 0.0, 0.0);
}
