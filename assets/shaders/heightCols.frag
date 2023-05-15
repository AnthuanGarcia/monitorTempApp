#include<flutter/runtime_effect.glsl>

uniform vec3 resolution;
uniform float time;
uniform float temperature;

out vec4 fragColor;

mat2 rot2D(float angle){
	
	float c=cos(angle),s=sin(angle);
	return mat2(c,-s,s,c);
	
}

void main(){
	
	vec2 uv=(2.*FlutterFragCoord()-resolution.xy)/resolution.y;
	
	vec3 col;
	
	uv.x+=.6*cos(uv.y*3.+time*.25);
	uv.y+=.2*sin(uv.x*3.+time*.25);
	uv*=rot2D(time*.1);
	
	uv.x+=.6/2.*cos(uv.y*2.*3.+time*.25);
	uv.y+=.2/2.*sin(uv.x*2.*3.+time*.25);
	uv*=rot2D(time*.1);
	
	uv.x+=.6/3.*cos(uv.y*3.*3.+time*.25);
	uv.y+=.2/3.*sin(uv.x*3.*3.+time*.25);
	uv*=rot2D(time*.1);
	
	uv.x+=.6/4.*cos(uv.y*4.*3.+time*.25);
	uv.y+=.2/4.*sin(uv.x*4.*3.+time*.25);
	uv*=rot2D(time*.1);
	
	float t=time*.25;
	
	vec3 a=.5*vec3(
		sin(uv.x+cos(uv.y)+t),
		cos(dot(uv,uv)+t),
		sin(sin(uv.x)+cos(uv.y)+t)
	)+.5;
	
	col = mix(
		mix(
			//vec3(1.0, 1.0, 1.0),
			//vec3(0.0, 0.1961, 0.9882),
			mix(
				vec3(.6941,.8353,1.),
				vec3(1.0, 0.6941, 0.6941),
				temperature
			),
			mix(
				vec3(.3961,.5059,.9922),
				vec3(0.9922, 0.3961, 0.3961),
				temperature
			),
			a.x
		),
		mix(
			vec3(.1333,.5804,1.),
			vec3(1.0, 0.1333, 0.1333),
			temperature
		),
		a.z
	);
	
	fragColor=vec4(col,1);
	
}