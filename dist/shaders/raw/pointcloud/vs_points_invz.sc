$input a_position, a_normal, a_texcoord0
$output v_color

#include "../common/common.sh"

SAMPLER2D(s_texColorDepth, 0);
uniform vec4 u_pointParams; // x: point size, y: depth scale,
                            // z, w: scale multiplier
uniform vec4 u_depthParams; // x: a, y: b

void main() {
    vec4 pointcolordepth = texture2DLod(s_texColorDepth, a_texcoord0, 0);
    // z = a/(d-b)
    float depth = u_depthParams.x / (pointcolordepth.w - u_depthParams.y);

    vec3 scaledPos = a_position.xyz; // * vec3(u_pointParams.zw, 1.0);
    scaledPos.xy *= u_pointParams.zw;
    scaledPos *= depth;
    vec4 centerPoint = mul(u_modelView, vec4(scaledPos, 1.0));
    centerPoint.xy += a_normal.xy * u_pointParams.x;
    centerPoint = mul(u_proj, centerPoint);

    v_color.xyz = pointcolordepth.xyz;

    gl_Position = centerPoint;
}
