$input v_texcoord0

#include "common.sh"
#define M_PI 3.1415926535897932384626433832795

SAMPLERCUBE(s_srcTex, 0);

vec3 panoMap(vec2 upos) {
  float theta = (upos.x * 2.0 - 1.0) * M_PI; // [0,1] => [-pi, pi]
  float phi = (upos.y - 0.5) * M_PI; // [0,1] => [-pi/2, pi/2]
  float r = cos(phi);
  vec3 viewdir = vec3(r * sin(theta), -sin(phi), r * cos(theta));
  return textureCube(s_srcTex, viewdir).rgb;
}

void main()
{
    gl_FragColor.rgb = panoMap(v_texcoord0.xy);
	gl_FragColor.a = 1.0;
    //gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
}
