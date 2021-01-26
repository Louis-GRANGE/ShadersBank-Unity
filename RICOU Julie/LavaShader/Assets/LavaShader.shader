Shader "Custom/LavaShader"
{

    Properties
    {
        _Scale("Scale", float) = 0.44
        _MHeight("MHeight", float) = 5.0
        _SHeight("SHeight", float) = 1.0
        _MaxDist("Max Distance", Range(75.,750.)) = 200
    }
        SubShader
    {
        Pass
    {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        float _Scale;
        float _MHeight;
        float _SHeight;
        float _MaxDist;

        #define PI  		3.1415926
        #define R 			_ScreenParams
        #define M 			iMouse
        #define T 			_Time.y

        float3 hitPoint;

        float fract(float var) {
            return var - floor(var);
        }

        float mod(float x, float y)
        {
            return x - y * floor(x / y);
        }

        // second hash
        float hash(float2 p) {
            p.x = 50.0 * fract(p.x * 0.3183099 + 0.71);
            p.y = 50.0 * fract(p.y * 0.3183099 + 0.113);
            return -1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y));
        }

        float hash2(float a, float b) {
            return fract(sin(a * 1.2764745 + b * .9560333 + 3.) * 14958.5453);
        }

        float2x2 r2(float a) {
            return float2x2(cos(a), sin(a), -sin(a), cos(a));
        }

        float noise(in float2 p) {
            float2 i = float2(floor(p.x), floor(p.y));
            float2 f = float2(fract(p.x), fract(p.y));
            float2 u = f * f * (3.0 - 2.0 * f);
            return lerp(lerp(hash(float2(i.x + 0.0, i.y + 0.0)),
                hash(float2(i.x + 1.0, i.y + 0.0)), u.x),
                lerp(hash(float2(i.x + 0.0, i.y + 1.0)),
                    hash(float2(i.x + 1.0, i.y + 1.0)), u.x), u.y);
        }

        // iMouse pos function
        /*float3 get_mouse(float3 ro) {
            float x = M.xy == float2(0) ? 0. : -(M.y / R.y * 1. - .5) * PI;
            float y = M.xy == float2(0) ? 0. : (M.x / R.x * 2. - 1.) * PI;
            ro.zy *= r2(x);
            ro.zx *= r2(y);
            return ro;
        }*/

        // cheap hight map
        float height_map(float2 p) {
            float height = noise(p * _Scale)* _MHeight;
            height = floor(height / _SHeight) * _SHeight;
            return height;
        }

        //@iq smooth union
        float su(float d1, float d2, float k) {
            float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
            return lerp(d2, d1, h) - k * h * (1.0 - h);
        }
        float glow = 0.;
        float2 map(in float3 pos) {
            float3 q = pos;
            float3 p = pos + float3(0.,1.,_Time.y * 6.85);
            float2 res = float2(100.,-1.);
            float sz = 12.;
            float hlf = sz / 2.;

            float3 qid = floor((q + hlf) / sz);
            q = float3(
                mod(q.x + hlf, sz) - hlf,
                q.y,
                mod(q.z + hlf, sz) - hlf
                );

            // ground
            float height = height_map(p.xz) * _Scale;
            float d = (p.y - height);
            d = 1. + p.y - height;
            hitPoint = p;

            // rnd bouncy phases based on hash
            float hsx = hash2(qid.x, qid.z);
            hsx = hsx * 6.37;
            float sw = -7. + pow(hsx + hsx * sin(hsx * 25. + T * .75),1.);
            float zw = .2 * sin(hsx - T * 2.10);
            // balls
            float bs = length(q - float3(sw * .1,sw,zw)) - 2.75;
            glow += .1 / (.01 + bs * bs);
            // merge balls and land
            bs = su(bs,d,2.25);
            if (bs < res.x) res = float2(bs / 1.65,height + q.y);

            return res;
        }

        float3 get_normal(in float3 p, float t) {
            float e = 0.001 * t;

            float2 h = float2(1.0,-1.0) * 0.5773;
            return normalize(h.xyy * map(p + h.xyy * e).x +
                              h.yyx * map(p + h.yyx * e).x +
                              h.yxy * map(p + h.yxy * e).x +
                              h.xxx * map(p + h.xxx * e).x);
        }

        float2 ray_march(in float3 ro, in float3 rd, int maxstep) {
            float t = .0;
            float m = 0.;
            for (int i = 0; i < maxstep; i++) {
                float2 d = map(ro + rd * t);
                m = d.y;
                if (d.x<.0001 * t || t>_MaxDist) break;
                t += d.x * .5;
            }
            return float2(t,m);
        }

        float3 get_hue(float rnd) {
            return lerp(float3(.25,.3,.1),float3(.5,.4,.1),rnd * 2.);
        }

        // ACES tone mapping from HDR to LDR
        float3 ACESFilm(float3 x) {
            float a = 2.51,
                  b = 0.03,
                  c = 2.43,
                  d = 0.59,
                  e = 0.14;
            return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
        }
        
        struct vertexInput {
            float4 vertex : POSITION;
            float4 texcoord0 : TEXCOORD0;
        };

        struct fragmentInput {
            float4 position : SV_POSITION;
            float4 texcoord0 : TEXCOORD0;
        };

        fragmentInput vert(vertexInput i)
        {
            fragmentInput o;
            o.position = UnityObjectToClipPos(i.vertex);
            o.texcoord0 = i.texcoord0;
            return o;
        }

        float4 frag(fragmentInput F):SV_Target {
            float2 U = (2. * F.position.xy - R.xy) / max(R.x,R.y);
            float mt = mod(T * 0.03, 2.0);
            float zoom = mt < 1. ? -10.75 : 9.75;
            float3 ro = float3(5.65 * sin(T * .25), 9. - 4. + 4. * sin(T * .18), zoom);
            float3 lp = float3(0.,.4,.0);

            // sligth heat distortion at the bottom of the screen
            U = lerp(U, U + (sin(U * 45.) * .0045),1. - U.y * 1.15);

            // uncomment to look around
            //ro = get_mouse(ro);
            float3 cf = normalize(lp - ro),
                 cp = float3(0.,1.,0.),
                 cr = normalize(cross(cp, cf)),
                 cu = normalize(cross(cf, cr)),
                 c = ro + cf * .75,
                 i = c + U.x * cr + -U.y * cu,
                 rd = i - ro;

            float3 C = float3(0.,0.,0.);
            float3 fC = float3(.25,.3,.1);

            // sky clouds using same height map
            float clouds = .0 - max(rd.y,0.0) * 0.5; //@iq trick
            float2 sv = 1.5 * rd.xz / rd.y;
            clouds += 0.1 * (-1.0 + 2.0 * smoothstep(-0.1,0.1,height_map(sv * 2.)));
            float3 sky = lerp(float3(clouds, clouds, clouds), fC, exp(-10.0 * max(rd.y,0.0))) * fC;

            // trace 
            float2 ray = ray_march(ro,rd,256);
            float t = ray.x;
            float m = ray.y;

            if (t < _MaxDist) {
                float3 p = ro + t * rd,
                     n = get_normal(p, t),
                     h = get_hue(m);

                C += h * (ray.x * .025);
                C = lerp(C, fC, 1. - exp(-.000025 * t * t * t));
            }
            else {
                C = lerp(C, fC, 1. - exp(-.000025 * t * t * t));
                C += sky;
            }

            //Effet de glow et couleur HDR to LDR
            C = ACESFilm(C);
            C += min(glow * .1 * float3(.9,.4,.0),1.);
            return float4(pow(C.x, 0.4545), pow(C.y, 0.4545), pow(C.z, 0.4545),1.0);
        }

        ENDCG
        }
    }
    FallBack "Diffuse"
}
