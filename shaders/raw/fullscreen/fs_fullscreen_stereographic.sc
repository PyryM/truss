$input v_texcoord0

#include "common.sh"
#define M_PI 3.1415926535897932384626433832795

SAMPLERCUBE(s_srcTex, 0);

vec3 panoMap(vec2 upos) {
  vec2 rpos = ((upos * 2.0) - 1.0) * 2.0;
  float d = rpos.x * rpos.x + rpos.y * rpos.y + 1.0;
  float x = 2.0*rpos.x / d;
  float y = 2.0*rpos.y / d;
  float z = (-1.0 + rpos.x*rpos.x + rpos.y*rpos.y) / d;

  return textureCube(s_srcTex, vec3(x, -y, -z)).rgb;
}

void main()
{
    gl_FragColor.rgb = panoMap(v_texcoord0.xy);
	gl_FragColor.a = 1.0;
    //gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
}
