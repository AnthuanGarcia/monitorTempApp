#include<flutter/runtime_effect.glsl>

uniform vec3 resolution;
uniform float time;
//uniform float temperature;
uniform float colInt;
uniform vec3 priCol; // Primary
uniform vec3 secCol; // Secondary
uniform vec3 mainCol; // Main

out vec4 fragColor;

mat2 rot2D(float angle){
	
	float c=cos(angle),s=sin(angle);
	return mat2(c,-s,s,c);
	
}

void main(){
	
	vec2 uv=(2.*FlutterFragCoord()-resolution.xy)/resolution.y;
	
	vec3 col;

	float t=time*.25;

	for(float i = 1.0; i <= 4.0; i += 1.0) {
		uv.x+=length(uv.y*0.5)/i*cos(uv.y*5.+t);
		uv.y+=length(uv.x*0.5)/i*sin(uv.x*3.+t);
		uv*=rot2D(time*.1);
	}
	
	col = mix(
		mix(
			priCol,
			secCol,
			uv.x * 0.5 + 0.5
		),
		mainCol,
		uv.y * 0.5 + 0.5
	);
	
	fragColor=vec4(col,1);
	
}