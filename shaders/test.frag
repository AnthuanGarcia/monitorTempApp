#include <flutter/runtime_effect.glsl>

uniform vec2 resolution;
uniform float time;

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

void main() {

    vec2 uv = (FlutterFragCoord() - 0.5 * resolution) / resolution.y;

    vec3 col;
    
    float s = smoothNoise(uv + u_time) * 0.05;
    float circle = length(uv - s) - 0.25;
    
    vec2 orbit = vec2(cos(u_time) / sqrt(5.0), sin(u_time)) * 0.3;
    orbit *= rot2D(-radians(45.0));
    float planet = length(uv - orbit) - 0.05;

    col = mix(
        col,
        vec3(1, 1, 2),
        GLOW(0.0035, abs(opSmoothUnion(circle, planet, 0.25)), 0.9)
    );

    fragColor = vec4(col, 1.0);

}