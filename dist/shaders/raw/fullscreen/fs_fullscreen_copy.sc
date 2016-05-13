$input v_texcoord0

#include "common.sh"

SAMPLER2D(s_srcTex, 0);

void main()
{
	gl_FragColor = texture2D(s_srcTex, v_texcoord0);
}
