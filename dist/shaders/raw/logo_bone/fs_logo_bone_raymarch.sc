$input v_wpos, v_vdir, v_lightdir

#include "common.sh"

SAMPLER3D(s_volume, 0);

uniform vec4 u_marchParams; // (step, thresh, normstep, lightarea)
uniform vec4 u_scaleParams; // (xyz: scale, w: lightstrength)
uniform vec4 u_timeParams; // (x: time, y: ?)

#include "logo_rayutil.sh"

#define NUM_RAYS u_timeParams.y

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
  float lighting = 0.0;
  vec3 collisionSeed = collision.xyz + (u_timeParams.x*NUM_RAYS);

  for(float ii = 0; ii < NUM_RAYS; ++ii) {
    vec3 randseed = collisionSeed + vec3(ii, ii, ii);
    vec3 v = randomHemispherePoint(randseed, normal);

    vec4 newcol = sdfToCollision(collision.xyz + v*stepsize*3, v, stepsize, thresh);

    float intensity = dot(v, v_lightdir);
    intensity = step(lightThresh, intensity);
    //clamp(v.z, 0.0, 1.0); //clamp(v.x*10 - 9, 0.0, 1.0);
    lighting += (1.0 - newcol.w) * dot(normal, v) * intensity;
  }
  lighting *= u_scaleParams.w;
  lighting /= (0.5*NUM_RAYS + 0.001);
  lighting = clamp(lighting, 0.0, 1.0);

  //gl_FragColor = vec4(normal.xyz * 0.5 + 0.5, 1.0);
  gl_FragColor = toGamma(vec4(lighting, lighting, lighting, 1.0));
  vec4 truePos = mul(u_modelViewProj, vec4(collision.xyz, 1.0));
  truePos /= truePos.w;
  gl_FragDepth = truePos.z;
}
