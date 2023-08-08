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
		
	//vec3 a=.5*vec3(
	//	sin(uv.x+cos(uv.y)+t),
	//	cos(dot(uv,uv)+t),
	//	sin(sin(uv.x)+cos(uv.y)+t)
	//)+.5;
	
	col = mix(
		/*mix(
			//vec3(1.0, 1.0, 1.0),
			//vec3(0.0, 0.1961, 0.9882),
			mix(
				mix(
					vec3(.6941,.8353,1.),
					vec3(1.0, 0.6941, 0.6941),
					temperature
				),
		      	priCol //vec3(1.0, 0.5294, 0.0588),
				colInt
			),
			mix(
				mix(
					vec3(0.9176, 0.5176, 1.0),
					vec3(0.9922, 0.8039, 0.3961),
					temperature
				),
				secCol //vec3(0.949, 0.0431, 0.4824),
				colInt
			),
			uv.x * 0.5 + 0.5
		),*/
		mix(
			priCol,
			secCol,
			uv.x * 0.5 + 0.5
		),
		/*mix(
			mix(
				vec3(.1333,.5804,1.),
				vec3(1.0, 0.1333, 0.1333),
				temperature
			),
			mainCol //vec3(1.0, 0.6314, 0.2627),
			colInt
		),*/
		mainCol,
		uv.y * 0.5 + 0.5
	);
	
	fragColor=vec4(col,1);
	
}