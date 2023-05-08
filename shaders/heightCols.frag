#include <flutter/runtime_effect.glsl>

uniform vec3 resolution;
uniform float time;
uniform vec2 position;

mat2 rot2D(float angle) {

	float c = cos(angle), s = sin(angle);
	return mat2(c, -s, s, c);

}

void main() {

	vec2 uv = (2.0*gl_FragCoord.xy - u_resolution.xy)/u_resolution.y;

	vec3 col;

	for (float i = 1.0; i <= 3.0; i++) {
		uv.x += 0.6/i * cos(uv.y * i * 2.0 + u_time);
		uv.y += 0.2/i * sin(uv.x * i * 3.0 + u_time);
		uv *= rot2D(u_time*0.1);
	}

	col = mix(
		mix(
			vec3(1.0, 1.0, 1.0),
			vec3(0.0, 0.1961, 0.9882),
			-uv.x / 2.0 + 0.5
		),
		mix(
			vec3(0.9686, 0.5255, 0.8353),
			vec3(1.0, 0.0, 0.4353),
			uv.y / 2.0 + 0.5
		),
		uv.x / 2.0 + 0.5
	);

	fragColor = vec4(col, 1);

}