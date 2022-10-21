$input v_wpos, v_vdir, v_lightdir

#include "common.sh"
#include "../common/truss_pbr.sh"

SAMPLER3D(s_volume, 0);

uniform vec4 u_marchParams; // (step, thresh, normstep, lightarea)
uniform vec4 u_scaleParams; // (xyz: scale, w: lightstrength)
uniform vec4 u_timeParams; // (x: time, y: ?)

uniform vec4 u_diffuseColor;
uniform vec4 u_pbrParams;

#include "logo_rayutil.sh"

#define NUM_RAYS u_timeParams.y

vec3 sample_skycolor(vec3 v) {
    return vec3(1.0, 1.0, 1.0) * clamp(v.z*30.0, 0.0, 1.0);
}

void main()
{
  vec3 scale = u_scaleParams.xyz;
  vec3 invScale = 1.0 / scale;
  vec3 viewDir = normalize(v_vdir.xyz);

  vec3 origin = v_wpos;
  float stepsize = u_marchParams.x;
  float thresh = u_marchParams.y;
  float lightThresh = u_marchParams.w;
  vec4 collision = sdfToCollision(origin, -viewDir, stepsize, thresh);
  if(collision.w < 0.5) {
    discard;
  }

  vec3 normal = estimateNormalSdf(collision.xyz, u_marchParams.z);
  //vec3 normal = estimateNormalAlt(collision.xyz - viewDir*stepsize*5, scale, stepsize, thresh);
  vec3 lighting = vec3(0.0, 0.0, 0.0);
  vec3 collisionSeed = collision.xyz + (u_timeParams.x*NUM_RAYS);

  for(float ii = 0.0; ii < NUM_RAYS; ++ii) {
    vec3 randseed = collisionSeed + vec3(ii, ii, ii);
    vec3 v = randomHemispherePoint(randseed, normal);
    vec4 newcol = sdfToCollision(collision.xyz + v*stepsize*3.0, v, stepsize, thresh);

    if(newcol.w <= 0.0) {
        vec3 skycolor = sample_skycolor(v);
        vec3 diffuse = skycolor * u_diffuseColor.rgb * max(0.0, dot(normal, v));
        vec3 spec = specularGGX(
            -viewDir, v, normal, 
            u_pbrParams.xyz, u_pbrParams.w,
            skycolor,
            diffuse
        );
        lighting += spec;
    }
  }
  lighting *= u_scaleParams.w;
  lighting /= (0.5*NUM_RAYS + 0.001);
  lighting = clamp(lighting, 0.0, 1.0);

  //gl_FragColor = vec4(normal.xyz * 0.5 + 0.5, 1.0);
  gl_FragColor = toGamma(vec4(lighting, 1.0));
  vec4 truePos = mul(u_modelViewProj, vec4(collision.xyz, 1.0));
  truePos /= truePos.w;
  gl_FragDepth = truePos.z;
}
