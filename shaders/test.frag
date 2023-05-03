#include <flutter/runtime_effect.glsl>

uniform vec2 resolution;
uniform float time;

out vec4 fragColor;

#define GLOW(r, d, i) pow(r/(d), i)

void main() {

    vec2 uv = (FlutterFragCoord() - 0.5 * resolution) / resolution.y;

    vec3 col;
    
    float s = 0.5*sin(time) + 0.5;
    col = mix(
        col,
        vec3(1, 1, 2),
        GLOW(0.005, abs(length(uv) - 0.25 * s), 0.9)
    );

    fragColor = vec4(col, 1.0);

}