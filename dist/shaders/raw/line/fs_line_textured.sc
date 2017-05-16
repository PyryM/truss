$input v_wpos, v_uv // in...

#include "../common/common.sh"

uniform vec4 u_baseColor;
SAMPLER2D(s_texAlbedo, 0);

void main()
{
	gl_FragColor = texture2D(s_texAlbedo, v_uv) * u_baseColor;
}
