$input v_texcoord0

#include "common.sh"

void main()
{
	gl_FragColor = vec4(v_texcoord0.x, v_texcoord0.y, 0.0, 1.0);
}
