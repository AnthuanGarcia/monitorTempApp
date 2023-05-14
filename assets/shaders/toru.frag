#include <flutter/runtime_effect.glsl>

uniform vec3 resolution;
uniform float time;

out vec4 fragColor;

#define ASPECT resolution.x / resolution.y
#define AA 1

#define GRID 0

#define SIZE 0.175
#define RADIUS 0.05

#define D2R 0.01745329
#define TWO_PI 6.283185

#define battery (0.5*sin(time*0.5)+0.5)

#define PAL2 vec3(0.530, 0.787, 0.485), vec3(0.420, 0.089, 0.758), vec3(0.133, 0.924, 0.008), vec3(4.820, 4.553, 2.869)

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {

    return a + b*cos( TWO_PI*(c*t + d) );

}

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

float randomRange (in vec2 seed, in float min, in float max) {
	return min + noise(seed) * (max - min);
}

float roundedboxIntersect( in vec3 ro, in vec3 rd, in vec3 size, in float rad )
{
    // bounding box
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*(size+rad);
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return -1.0;
    float t = tN;

    // convert to first octant
    vec3 pos = ro+t*rd;
    vec3 s = sign(pos);
    ro  *= s;
    rd  *= s;
    pos *= s;
        
    // faces
    pos -= size;
    pos = max( pos.xyz, pos.yzx );
    if( min(min(pos.x,pos.y),pos.z) < 0.0 ) return t;

    // some precomputation
    vec3 oc = ro - size;
    vec3 dd = rd*rd;
    vec3 oo = oc*oc;
    vec3 od = oc*rd;
    float ra2 = rad*rad;

    t = 1e20;        

    // corner
    {
    float b = od.x + od.y + od.z;
    float c = oo.x + oo.y + oo.z - ra2;
    float h = b*b - c;
    if( h>0.0 ) t = -b-sqrt(h);
    }
    // edge X
    {
    float a = dd.y + dd.z;
    float b = od.y + od.z;
    float c = oo.y + oo.z - ra2;
    float h = b*b - a*c;
    if( h>0.0 )
    {
        h = (-b-sqrt(h))/a;
        if( h>0.0 && h<t && abs(ro.x+rd.x*h)<size.x ) t = h;
    }
    }
    // edge Y
    {
    float a = dd.z + dd.x;
    float b = od.z + od.x;
    float c = oo.z + oo.x - ra2;
    float h = b*b - a*c;
    if( h>0.0 )
    {
        h = (-b-sqrt(h))/a;
        if( h>0.0 && h<t && abs(ro.y+rd.y*h)<size.y ) t = h;
    }
    }
    // edge Z
    {
    float a = dd.x + dd.y;
    float b = od.x + od.y;
    float c = oo.x + oo.y - ra2;
    float h = b*b - a*c;
    if( h>0.0 )
    {
        h = (-b-sqrt(h))/a;
        if( h>0.0 && h<t && abs(ro.z+rd.z*h)<size.z ) t = h;
    }
    }

    if( t>1e19 ) t=-1.0;
    
    return t;
}

vec3 roundedboxNormal( in vec3 pos, in vec3 siz, in float rad )
{
    return sign(pos)*normalize(max(abs(pos)-siz,0.0));
}

vec3 sun = vec3(50, 100, -50);

vec3 hsv2rgb(vec3 c) {

    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);

}

vec3 shade(vec3 p, vec3 ro) {

	vec3 n = roundedboxNormal(p, vec3(SIZE), RADIUS);

	vec3 lightDir = normalize(sun - p);
	vec3 viewDir  = normalize(ro - p);
	vec3 reflLight = normalize(reflect(-lightDir, n));

	float diff = max(dot(n, lightDir), 0.0);
	float spec = pow(max(dot(reflLight, viewDir), 0.0), 64.0);
	float rim  = 1.0 - dot(viewDir, n);

	//vec3 ambient = vec3(0.5, 0.0, 0.25);
	//vec3 diffuse = vec3(1.0, 0.0, 0.5);

    vec3 cc, cv;

	cc = hsv2rgb(vec3(0.45));
	cv = hsv2rgb(vec3(0.975));
    /*cv = hsv2rgb(
        vec3(
            18.0 * 0.00277,
            vec2(130, 110) * 0.01
        )
    );*/

    //cv = hsv2rgb(vec3(0.2888, 1.0, 0.7));

	float kw = (dot(n, lightDir) + 1.0) * 0.5; 

	vec3 ambient = mix(cc, cv, kw);

	//vec3 ambient = palette(time*0.25, PAL2) * 0.5;
	vec3 diffuse = vec3(0.75);
	vec3 rimLight = vec3(0.8);

	return clamp(
		ambient +
	    diff * diffuse +
		(1.0 - diff) * rim  * rimLight +
		spec,
		0.0, 1.0
	);
}

#define SPEED time * 0.25

vec2 brickTile(vec2 _st, float _zoom) {

    _st *= _zoom;

    //float evenx = mod(_st.y, 2.0);
    //float eveny = mod(_st.x, 2.0);
//
    //float movex = sign(evenx - 1.0) * SPEED;
    //float movey = sign(eveny - 1.0) * SPEED;

    vec2 even = mod(_st, 2.0);
    vec2 move = sign(even - 1.0) * SPEED;

    _st.y += move.x * step(1.0,  mod(SPEED, 2.0));
    _st.x += move.y * step(-1.0, -mod(SPEED, 2.0));

    return fract(_st) - 0.5;

}

float gridp(float x, float t) {

    float k = 0.5;
    float f = fract(x);
    
    return smoothstep(k - t, k, f) * (1.0 - smoothstep(k, k + t, f));
}

void main() {

	vec3 tot = vec3(0);

#if AA > 1
	for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {

    vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
    vec2 uv = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y;

#else
	vec2 uv = FlutterFragCoord() / resolution.xy;
	uv.x *= ASPECT;

#endif

    //vec3(0.65, 1.0, 0.75)

	vec3 col = vec3(1.0, 0.851, 0.9569);
    //vec3 col = vec3(1.0, 0.9098, 0.7137);

	//vec2 uv = gl_FragCoord.xy / resolution;
	//uv.x *= ASPECT;

	//vec3 ro = vec3(0, 0, -2);
	//vec3 rd = normalize(vec3(uv, 1));

#if GRID

    vec2 uv2 = uv * 16.0;
    float thick = 0.03;

    col = mix(
        col, 
        vec3(1.0, 0.95, 0.98),
        gridp(uv2.x, thick) + gridp(uv2.y, thick)
    );
    
#endif

	float noi = smoothNoise(uv*8.0 + time*0.25) * 0.1;

	//uv *= 1.5;
	uv *= rot2D(-10.0 * D2R);
	uv = brickTile(uv, 2.5);

	//uv.y += time*0.05*sign(mod(floor(uv.x), 2.0) - 0.5);
	//uv = fract(uv) - 0.5;

	vec3 ro = vec3(uv, -2.0);
	vec3 rd = vec3(0, 0, 1);

	mat2 rTime = rot2D(time * 0.5);
	mat2 r30   = rot2D(30.0 * D2R);

	ro.yz *= r30;
	rd.yz *= r30;

	ro.xz  *= rTime;
	rd.xz  *= rTime;
	sun.xz *= rTime;

	float t = roundedboxIntersect(ro, rd, vec3(SIZE), RADIUS + noi);

	if (t > 0.0) {

		vec3 p = ro + rd*t;
		col = shade(p, ro);

	}

	tot += col;

#if AA > 1
	}

	tot /= float(AA*AA);
#endif

    //tot = pow(tot, 1.0/vec3(2.2));

	fragColor = vec4(tot, 1);

}