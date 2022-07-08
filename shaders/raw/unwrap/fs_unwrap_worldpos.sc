$input v_wpos, v_uv

#include "common.sh"

void main()
{
	gl_FragColor = vec4(v_wpos.xyz, 1.0);
}
