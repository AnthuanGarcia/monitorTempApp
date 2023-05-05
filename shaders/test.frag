#include <flutter/runtime_effect.glsl>

uniform vec3 resolution;
uniform float time;
uniform float radius;
uniform vec2 position;

out vec4 fragColor;

#define GLOW(r, d, i) pow(r/(d), i)

mat2 rot2D(float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);
}

float noise(vec2 st) {

    return fract(sin( dot( st.xy, vec2(12.9898,78.233) ) ) * 43758.5453123);

}

float smoothNoise(vec2 st) {

    vec2 ipos = floor(st);
    vec2 fpos = fract(st);

    fpos = fpos*fpos * (3.0 - 2.0 * fpos);

    float bl = noise(ipos);
    float br = noise(ipos + vec2(1, 0));
    float b  = mix(bl, br, fpos.x);
    
    float tl = noise(ipos + vec2(0, 1));
    float tr = noise(ipos + vec2(1));
    float t  = mix(tl, tr, fpos.x);

    return mix(b, t, fpos.y);

}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

// TODO: Lava lamp effect
void main() {

    vec2 uv = (2.0*FlutterFragCoord() - resolution.xy) / resolution.y;
    vec2 pos = 2.0*position - 1.0;

    pos.x *= resolution.x / resolution.y;

    vec4 col = vec4(0);
    
    float s = smoothNoise(uv + time) * 0.05;
    float circle = length(uv - s) - radius;
    
    //vec2 orbit = vec2(cos(time) * 0.4472135 /* 1 / sqrt(5.0) */, sin(time)) * 0.15;
    //orbit *= rot2D(-radians(45.0));
    float planet = length(uv - pos) - 0.025;

    col = mix(
        col,
        vec4(1, 1, 2, 1),
        GLOW(0.0035, abs(opSmoothUnion(circle, planet, 0.25)), 0.9)
    );

    fragColor = col;

}