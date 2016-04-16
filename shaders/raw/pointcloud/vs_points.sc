$input a_position, a_normal, a_texcoord0
$output v_color

#include "../common/common.sh"

SAMPLER2D(s_texColorDepth, 0);
uniform vec4 u_pointParams; // x: point size, y: depth scale,
                            // z, w: scale multiplier
void main() {
  vec3 scaledPos = a_position.xyz * vec3(u_pointParams.zw, 1.0);
  vec4 centerPoint = mul(u_modelView, vec4(scaledPos, 1.0));

  vec4 pointcolordepth = texture2D(s_texColorDepth, a_texcoord0);
  float depth = pointcolordepth.w * u_pointParams.y;
  centerPoint.xyz *= depth;
  centerPoint.xyz += a_normal * u_pointParams.x;
  centerPoint = mul(u_proj, centerPoint);

  v_color = pointcolordepth.xyz;

  gl_Position = centerPoint;
}
