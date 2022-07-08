#define MAX_STEPS 128
#define PI 3.14159265359

float max3(vec3 v) {
    return max(v.x, max(v.y, v.z));
}

float min3(vec3 v) {
    return min(v.x, min(v.y, v.z));
}

float safeSample(vec3 p) {
    if(min3(p) < 0.0 || max3(p) > 1.0) {
        return 0.0;
    } else {
        return texture3DLod(s_volume, p, 0).r;
    }
}

vec4 sdfToCollision(vec3 p, vec3 d, float minStep, float thresh) {
    vec3 curpos = p;
    for(int i = 0; i < MAX_STEPS; ++i) {
        // have to use Lod variant inside loop for Reasons, but
        // this isn't going to have computed mip levels anyway so...
        float sdfDist = texture3DLod(s_volume, curpos, 0).r - thresh;
        if(sdfDist <= 0.0) {
            return vec4(curpos, 1.0);
        }
        if(min3(curpos) < 0.0 || max3(curpos) > 1.0) {
            return vec4(curpos, 0.0);
        } 
        curpos += max(sdfDist, minStep) * d;
    }
    return vec4(curpos, 0.0);
}

vec3 estimateNormalSdf(vec3 p, float delta) {
    float dx = safeSample(p + vec3(delta, 0.0, 0.0)) - safeSample(p - vec3(delta, 0.0, 0.0));
    float dy = safeSample(p + vec3(0.0, delta, 0.0)) - safeSample(p - vec3(0.0, delta, 0.0));
    float dz = safeSample(p + vec3(0.0, 0.0, delta)) - safeSample(p - vec3(0.0, 0.0, delta));
    vec3 n = vec3(dx, dy, dz);
    if(length(n)==0.0) {
        n = vec3(0.0, 1.0, 0.0);
    }
    return normalize(n);
}

float hash(vec3 p) {
    p = 17.0*fract( p*0.3183099+vec3(.11,.17,.13) );
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

vec2 hash2( float n ) {
    return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123));
}

vec3 hash3(float n) {
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423));
}

vec3 hash3_to_3(vec3 n) {
    return fract(sin(n)*vec3(43758.5453123,22578.1459123,19642.3490423));
}

// from: https://github.com/LWJGL/lwjgl3-demos/blob/master/res/org/lwjgl/demo/opengl/raytracing/randomCommon.glsl

vec3 randomSpherePoint(vec3 seed) {
    vec3 rand = hash3_to_3(seed);
    float ang1 = rand.x * 2.0 * PI; // [-1..1) -> [0..2*PI)
    float u = 2.0*rand.y - 1.0; // [-1..1), cos and acos(2v-1) cancel each other out, so we arrive at [-1..1)
    float u2 = u * u;
    float sqrt1MinusU2 = sqrt(1.0 - u2);
    float x = sqrt1MinusU2 * cos(ang1);
    float y = sqrt1MinusU2 * sin(ang1);
    float z = u;
    return vec3(x, y, z);
}

vec3 randomHemispherePoint(vec3 seed, vec3 n) {
    vec3 v = randomSpherePoint(seed);
    return v * sign(dot(v, n));
}