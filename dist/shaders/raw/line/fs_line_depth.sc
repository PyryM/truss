$input v_wpos // in...

#include "../common/common.sh"

uniform vec4 u_color;

void main()
{
    float d = (v_wpos.y + 10.0) / 20.0;
	gl_FragColor = vec4(d, d, d, 1.0);
}
