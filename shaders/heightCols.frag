#include<flutter/runtime_effect.glsl>

uniform vec3 resolution;
uniform float time;

out vec4 fragColor;

mat2 rot2D(float angle){
	
	float c=cos(angle),s=sin(angle);
	return mat2(c,-s,s,c);
	
}

void main(){
	
	vec2 uv=(2.*FlutterFragCoord()-resolution.xy)/resolution.y;
	
	vec3 col;
	
	for(float i=1.;i<=4.;i++){
		
		uv.x+=.6/i*cos(uv.y*i*3.+time*.25);
		uv.y+=.2/i*sin(uv.x*i*3.+time*.25);
		uv*=rot2D(time*.1);
		
	}
	
	float t=time*.25;
	
	vec3 a=.5*vec3(
		sin(uv.x+cos(uv.y)+t),
		cos(dot(uv,uv)+t),
		sin(sin(uv.x)+cos(uv.y)+t)
	)+.5;
	
	col=mix(
		mix(
			//vec3(1.0, 1.0, 1.0),
			//vec3(0.0, 0.1961, 0.9882),
			vec3(.6941,.8353,1.),
			vec3(.3961,.5059,.9922),
			a.x
		),
		vec3(.1333,.5804,1.),
		a.z
	);
	
	fragColor=vec4(col,1);
	
}