﻿Shader "Unlit/Seascape"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex getPixel
            #pragma fragment mainImage
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            /*
            * "Seascape" by Alexander Alekseev aka TDM - 2014
            * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
            * Contact: tdmaav@gmail.com
            */

            const int NUM_STEPS = 8;
            const float PI	 	= 3.141592;
            const float EPSILON	= 1e-3;
            #define EPSILON_NRM (0.1 / _ScreenParams.x)
            #define AA

            // sea
            const int ITER_GEOMETRY = 3;
            const int ITER_FRAGMENT = 5;
            const float SEA_HEIGHT = 0.6;
            const float SEA_CHOPPY = 4.0;
            const float SEA_SPEED = 0.8;
            const float SEA_FREQ = 0.16;
            const float3 SEA_BASE = float3(0.0,0.09,0.18);
            const float3 SEA_WATER_COLOR = float3(0.8,0.9,0.6)*0.6;
            #define SEA__Time (1.0 + _Time * SEA_SPEED)
            const float2x2 octave_m = float2x2(1.6,1.2,-1.2,1.6);

            // math
            float3x3 fromEuler(float3 ang) {
                float2 a1 = float2(sin(ang.x),cos(ang.x));
                float2 a2 = float2(sin(ang.y),cos(ang.y));
                float2 a3 = float2(sin(ang.z),cos(ang.z));
                float3x3 m;
                m[0] = float3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
                m[1] = float3(-a2.y*a1.x,a1.y*a2.y,a2.x);
                m[2] = float3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
                return m;
            }
            int fract(float2 var) {
                int multiplier = 1000;
                float double_value = var;
                return (int)((double_value - (int)double_value) * multiplier);
            }
            float hash( float2 p ) {
                float h = dot(p,float2(127.1,311.7));	
                return fract(sin(h) * 43758.5453123);
            }
            float noise( in float2 p ) {
                float2 i = floor( p );
                float2 f = fract( p );	
                float2 u = f*f*(3.0-2.0*f);
                return -1.0+2.0*lerp( lerp( hash( i + float2(0.0,0.0) ), 
                                hash( i + float2(1.0,0.0) ), u.x),
                            lerp( hash( i + float2(0.0,1.0) ), 
                                hash( i + float2(1.0,1.0) ), u.x), u.y);
            }

            // lighting
            float diffuse(float3 n,float3 l,float p) {
                return pow(dot(n,l) * 0.4 + 0.6,p);
            }
            float specular(float3 n,float3 l,float3 e,float s) {    
                float nrm = (s + 8.0) / (PI * 8.0);
                return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
            }

            // sky
            float3 getSkyColor(float3 e) {
                e.y = (max(e.y,0.0)*0.8+0.2)*0.8;
                return float3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4) * 1.1;
            }

            // sea
            float sea_octave(float2 uv, float choppy) {
                uv += noise(uv);        
                float2 wv = 1.0-abs(sin(uv));
                float2 swv = abs(cos(uv));    
                wv = lerp(wv,swv,wv);
                return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
            }

            float map(float3 p) {
                float freq = SEA_FREQ;
                float amp = SEA_HEIGHT;
                float choppy = SEA_CHOPPY;
                float2 uv = p.xz; uv.x *= 0.75;
                
                float d, h = 0.0;    
                for(int i = 0; i < ITER_GEOMETRY; i++) {        
                    d = sea_octave((uv+SEA__Time)*freq,choppy);
                    d += sea_octave((uv-SEA__Time)*freq,choppy);
                    h += d * amp;        
                    uv *= octave_m[0];
                    freq *= 1.9;
                    amp *= 0.22;
                    choppy = lerp(choppy,1.0,0.2);
                }
                return p.y - h;
            }

            float map_detailed(float3 p) {
                float freq = SEA_FREQ;
                float amp = SEA_HEIGHT;
                float choppy = SEA_CHOPPY;
                float2 uv = p.xz; uv.x *= 0.75;
                
                float d, h = 0.0;    
                for(int i = 0; i < ITER_FRAGMENT; i++) {        
                    d = sea_octave((uv+SEA__Time)*freq,choppy);
                    d += sea_octave((uv-SEA__Time)*freq,choppy);
                    h += d * amp;        
                    uv *= octave_m[1]; freq *= 1.9; amp *= 0.22;
                    choppy = lerp(choppy,1.0,0.2);
                }
                return p.y - h;
            }

            float3 getSeaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist) {  
                float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
                fresnel = pow(fresnel,3.0) * 0.5;
                    
                float3 reflected = getSkyColor(reflect(eye,n));    
                float3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12; 
                
                float3 color = lerp(refracted,reflected,fresnel);
                
                float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
                color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
                
                float val = specular(n, l, eye, 60.0);
                color += float3(val, val, val);
                
                return color;
            }

            // tracing
            float3 getNormal(float3 p, float eps) {
                float3 n;
                n.y = map_detailed(p);    
                n.x = map_detailed(float3(p.x+eps,p.y,p.z)) - n.y;
                n.z = map_detailed(float3(p.x,p.y,p.z+eps)) - n.y;
                n.y = eps;
                return normalize(n);
            }

            float heightMapTracing(float3 ori, float3 dir, out float3 p) {  
                float tm = 0.0;
                float tx = 1000.0;    
                float hx = map(ori + dir * tx);
                if(hx > 0.0) return tx;   
                float hm = map(ori + dir * tm);    
                float tmid = 0.0;
                for(int i = 0; i < NUM_STEPS; i++) {
                    tmid = lerp(tm,tx, hm/(hm-hx));                   
                    p = ori + dir * tmid;                   
                    float hmid = map(p);
                    if(hmid < 0.0) {
                        tx = tmid;
                        hx = hmid;
                    } else {
                        tm = tmid;
                        hm = hmid;
                    }
                }
                return tmid;
            }

            float3 getPixel(in float2 coord, float _Time) {    
                float2 uv = coord / _ScreenParams.xy;
                uv = uv * 2.0 - 1.0;
                uv.x *= _ScreenParams.x / _ScreenParams.y;    
                    
                // ray
                float3 ang = float3(sin(_Time*3.0)*0.1,sin(_Time)*0.2+0.3,_Time);    
                float3 ori = float3(0.0,3.5,_Time*5.0);
                float3 dir = normalize(float3(uv.xy,-2.0)); dir.z += length(uv) * 0.14;
                dir = normalize(dir) * fromEuler(ang)[0];
                
                // tracing
                float3 p;
                heightMapTracing(ori,dir,p);
                float3 dist = p - ori;
                float3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
                float3 light = normalize(float3(0.0,1.0,0.8)); 
                        
                // color
                return lerp(
                    getSkyColor(dir),
                    getSeaColor(p,n,light,dir,dist),
                    pow(smoothstep(0.0,-0.02,dir.y),0.2));
            }

            // main
            fixed4 mainImage(float3 fragCoord: SV_POSITION): SV_Target {                
            #ifdef AA
                float3 color = float3(0.0, 0.0, 0.0);
                for(int i = -1; i <= 1; i++) {
                    for(int j = -1; j <= 1; j++) {
                        float2 uv = fragCoord+float2(i,j) / 3.0;
                        color += getPixel(uv, _Time);
                    }
                }
                color /= 9.0;
            #else
                float3 color = getPixel(fragCoord, _Time);
            #endif
                
                // post
                return fixed4(pow(color, float3(0.65, 0.65, 0.65)), 1.0);
            }
            ENDCG
        }
    }
}
