Shader "Unlit/RemsShader"
{
    Properties
    {
        _ResolutionX("Resolution X", Range(0.0, 2000)) = 0.0
        _ResolutionY("Resolution Y", Range(0.0, 2000)) = 0.0
        _Size("Size", Range(0.0, 10)) = 0.0
        _TimeMultiplicator("Time Multiplicator", Range(0.0, 100)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment mainImage
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define S(x, y, z) smoothstep(x, y, z)
            #define B(a, b, edge, t) S(a-edge, a+edge, t)*S(b+edge, b-edge, t)
            #define sat(x) clamp(x,0.,1.)

            #define streetLightCol float3(1., .7, .3)
            #define headLightCol float3(.8, .8, 1.)
            #define tailLightCol float3(1., .1, .1)

            #define HIGH_QUALITY
            #define CAM_SHAKE 1.
            #define LANE_BIAS .5
            #define RAIN
            //#define DROP_DEBUG

            uniform float _ResolutionX;
            uniform float _ResolutionY;
            uniform float _Size;
            uniform float _TimeMultiplicator;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct vertexInput
            {
                float4 vertex : POSITION;
                float4 texcoord0 : TEXCOORD0;
            };
            struct fragmentInput
            {
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

            float3 ro, rd;

            float N(float t) {
                return frac(sin(t * 10234.324) * 123423.23512);
            }
            float3 N31(float p) {
                //  3 out, 1 in... DAVE HOSKINS
               float3 p3 = frac(float3(p, p, p) * float3(.1031,.11369,.13787));
               p3 += dot(p3, p3.yzx + 19.19);
               return frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
            }
            float N2(float2 p)
            {	// Dave Hoskins - https://www.shadertoy.com/view/4djSRW
                float3 p3 = frac(float3(p.xyx) * float3(443.897, 441.423, 437.195));
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.x + p3.y) * p3.z);
            }


            float DistLine(float3 ro, float3 rd, float3 p) {
                return length(cross(p - ro, rd));
            }

            float3 ClosestPoint(float3 ro, float3 rd, float3 p) {
                // returns the closest point on ray r to point p
                return ro + max(0., dot(p - ro, rd)) * rd;
            }

            float Remap(float a, float b, float c, float d, float t) {
                return ((t - a) / (b - a)) * (d - c) + c;
            }

            float BokehMask(float3 ro, float3 rd, float3 p, float size, float blur) {
                float d = DistLine(ro, rd, p);
                float m = S(size, size * (1. - blur), d);

                #ifdef HIGH_QUALITY
                m *= lerp(.7, 1., S(.8 * size, size, d));
                #endif

                return m;
            }



            float SawTooth(float t) {
                return cos(t + cos(t)) + sin(2. * t) * .2 + sin(4. * t) * .02;
            }

            float DeltaSawTooth(float t) {
                return 0.4 * cos(2. * t) + 0.08 * cos(4. * t) - (1. - sin(t)) * sin(t + cos(t));
            }

            float2 GetDrops(float2 uv, float seed, float m)
            {

                float t = _Time * _TimeMultiplicator + m * 30.;
                float2 o = float2(0.0, 0.0);

                #ifndef DROP_DEBUG
                uv.y += t * .05;
                #endif

                uv *= float2(10., 2.5) * 2.;
                float2 id = floor(uv);
                float3 n = N31(id.x + (id.y + seed) * 546.3524);
                float2 bd = frac(uv);

                float2 uv2 = bd;

                bd -= .5;

                bd.y *= 4.;

                bd.x += (n.x - .5) * .6;

                t += n.z * 6.28;
                float slide = SawTooth(t);

                float ts = 1.5;
                float2 trailPos = float2(bd.x * ts, (frac(bd.y * ts * 2. - t * 2.) - .5) * .5);

                bd.y += slide * 2.;								// make drops slide down

                #ifdef HIGH_QUALITY
                float dropShape = bd.x * bd.x;
                dropShape *= DeltaSawTooth(t);
                bd.y += dropShape;								// change shape of drop when it is falling
                #endif

                float d = length(bd);							// distance to main drop

                float trailMask = S(-.2, .2, bd.y);				// mask out drops that are below the main
                trailMask *= bd.y;								// fade dropsize
                float td = length(trailPos * max(.5, trailMask));	// distance to trail drops

                float mainDrop = S(.2, .1, d);
                float dropTrail = S(.1, .02, td);

                dropTrail *= trailMask;
                o = lerp(bd * mainDrop, trailPos, dropTrail);		// lerp main drop and drop trail

                #ifdef DROP_DEBUG
                if (uv2.x < .02 || uv2.y < .01) o = float2(1.);
                #endif

                return o;
            }

            void CameraSetup(float2 uv, float3 pos, float3 lookat, float zoom, float m) {
                ro = pos;
                float3 f = normalize(lookat - ro);
                float3 r = cross(float3(0., 1., 0.), f);
                float3 u = cross(f, r);
                float t = _Time * _TimeMultiplicator;

                float2 offs = float2(0.0, 0.0);
                #ifdef RAIN
                float2 dropUv = uv;

                #ifdef HIGH_QUALITY
                float x = (sin(t * .1) * .5 + .5) * .5;
                x = -x * x;
                float s = sin(x);
                float c = cos(x);

                float2x2 rot = float2x2(c, -s, s, c);

                #ifndef DROP_DEBUG
                dropUv = mul(uv, rot);
                dropUv.x += -sin(t * .1) * .5;
                #endif
                #endif

                offs = GetDrops(dropUv, 1., m);

                #ifndef DROP_DEBUG
                offs += GetDrops(dropUv * 1.4, 10., m);
                #ifdef HIGH_QUALITY
                offs += GetDrops(dropUv * 2.4, 25., m);
                //offs += GetDrops(dropUv*3.4, 11.);
                //offs += GetDrops(dropUv*3., 2.);
                #endif

                float ripple = sin(t + uv.y * 3.1415 * 30. + uv.x * 124.) * .5 + .5;
                ripple *= .005;
                offs += float2(ripple * ripple, ripple);
                #endif
                #endif
                float3 center = ro + f * zoom;
                float3 i = center + (uv.x - offs.x) * r + (uv.y - offs.y) * u;

                rd = normalize(i - ro);
            }

            float3 HeadLights(float i, float t) {
                float z = frac(-t * 2. + i);
                float3 p = float3(-.3, .1, z * 40.);
                float d = length(p - ro);

                float size = lerp(.03, .05, S(.02, .07, z)) * d;
                float m = 0.;
                float blur = .1;
                m += BokehMask(ro, rd, p - float3(.08, 0., 0.), size, blur);
                m += BokehMask(ro, rd, p + float3(.08, 0., 0.), size, blur);

                #ifdef HIGH_QUALITY
                m += BokehMask(ro, rd, p + float3(.1, 0., 0.), size, blur);
                m += BokehMask(ro, rd, p - float3(.1, 0., 0.), size, blur);
                #endif

                float distFade = max(.01, pow(1. - z, 9.));

                blur = .8;
                size *= 2.5;
                float r = 0.;
                r += BokehMask(ro, rd, p + float3(-.09, -.2, 0.), size, blur);
                r += BokehMask(ro, rd, p + float3(.09, -.2, 0.), size, blur);
                r *= distFade * distFade;

                return headLightCol * (m + r) * distFade;
            }


            float3 TailLights(float i, float t) {
                t = t * 1.5 + i;

                float id = floor(t) + i;
                float3 n = N31(id);

                float laneId = S(LANE_BIAS, LANE_BIAS + .01, n.y);

                float ft = frac(t);

                float z = 3. - ft * 3.;						// distance ahead

                laneId *= S(.2, 1.5, z);				// get out of the way!
                float lane = lerp(.6, .3, laneId);
                float3 p = float3(lane, .1, z);
                float d = length(p - ro);

                float size = .05 * d;
                float blur = .1;
                float m = BokehMask(ro, rd, p - float3(.08, 0., 0.), size, blur) +
                            BokehMask(ro, rd, p + float3(.08, 0., 0.), size, blur);

                #ifdef HIGH_QUALITY
                float bs = n.z * 3.;						// start braking at random distance		
                float brake = S(bs, bs + .01, z);
                brake *= S(bs + .01, bs, z - .5 * n.y);		// n.y = random brake duration

                m += (BokehMask(ro, rd, p + float3(.1, 0., 0.), size, blur) +
                    BokehMask(ro, rd, p - float3(.1, 0., 0.), size, blur)) * brake;
                #endif

                float refSize = size * 2.5;
                m += BokehMask(ro, rd, p + float3(-.09, -.2, 0.), refSize, .8);
                m += BokehMask(ro, rd, p + float3(.09, -.2, 0.), refSize, .8);
                float3 col = tailLightCol * m * ft;

                float b = BokehMask(ro, rd, p + float3(.12, 0., 0.), size, blur);
                b += BokehMask(ro, rd, p + float3(.12, -.2, 0.), refSize, .8) * .2;

                float3 blinker = float3(1., .7, .2);
                blinker *= S(1.5, 1.4, z) * S(.2, .3, z);
                blinker *= sat(sin(t * 200.) * 100.);
                blinker *= laneId;
                col += blinker * b;

                return col;
            }
            float3 StreetLights(float i, float t) {
                float side = sign(rd.x);
                float offset = max(side, 0.) * (1. / 16.);
                float z = frac(i - t + offset);
                float3 p = float3(2. * side, 2., z * 60.);
                float d = length(p - ro);
                float blur = .1;
                float3 rp = ClosestPoint(ro, rd, p);
                float distFade = Remap(1., .7, .1, 1.5, 1. - pow(1. - z, 6.));
                distFade *= (1. - z);
                float m = BokehMask(ro, rd, p, .05 * d, blur) * distFade;

                return m * streetLightCol;
            }

            float3 EnvironmentLights(float i, float t) {
                float n = N(i + floor(t));

                float side = sign(rd.x);
                float offset = max(side, 0.) * (1. / 16.);
                float z = frac(i - t + offset + frac(n * 234.));
                float n2 = frac(n * 100.);
                float3 p = float3((3. + n) * side, n2 * n2 * n2 * 1., z * 60.);
                float d = length(p - ro);
                float blur = .1;
                float3 rp = ClosestPoint(ro, rd, p);
                float distFade = Remap(1., .7, .1, 1.5, 1. - pow(1. - z, 6.));
                float m = BokehMask(ro, rd, p, .05 * d, blur);
                m *= distFade * distFade * .5;

                m *= 1. - pow(sin(z * 6.28 * 20. * n) * .5 + .5, 20.);
                float3 randomCol = float3(frac(n * -34.5), frac(n * 4572.), frac(n * 1264.));
                float3 col = lerp(tailLightCol, streetLightCol, frac(n * -65.42));
                col = lerp(col, randomCol, n);
                return m * col * .2;
            }

            float4 mainImage(float4 vertex:POSITION, float2 uv : TEXCOORD0) : SV_Target
            {
                float2 fragCoord = uv * float2(1024, 1024);
                float2 fuv = fragCoord / float2(_ResolutionX, _ResolutionY) / _Size;

                float t = _Time * _TimeMultiplicator;
                float3 col = float3(0.0, 0.0, 0.0);
                //float2 uv = fragCoord.xy / _ScreenParams.xy; // 0 <> 1

                fuv -= .5;
                fuv.x *= _ScreenParams.x / _ScreenParams.y;

                float2 mouse = /*iMouse.xy*/float2(0.0, 0.0) / _ScreenParams.xy;

                float3 pos = float3(.3, .15, 0.);

                float bt = t * 5.;
                float h1 = N(floor(bt));
                float h2 = N(floor(bt + 1.));
                float bumps = lerp(h1, h2, frac(bt)) * .1;
                bumps = bumps * bumps * bumps * CAM_SHAKE;

                pos.y += bumps;
                float lookatY = 0.0;//pos.y+bumps;
                float3 lookat = float3(0.3, lookatY, 1.);
                float3 lookat2 = float3(0., lookatY, .7);
                lookat = lerp(lookat, lookat2, 0.0);

                fuv.y += bumps * 4.;
                CameraSetup(fuv, pos, lookat, 2., mouse.x);

                t *= .03;
                t += mouse.x;

                // fix for GLES devices by MacroMachines
                #ifdef GL_ES
                    const float stp = 1. / 8.;
                #else
                    float stp = 1. / 8.;
                #endif
                float i = 0.0;
                for (i = 0.0; i < 1.0; i += stp)
                {
                    col += StreetLights(i, t);
                }

                for (i = 0.0; i < 1.0; i += stp)
                {
                    float n = N(i + floor(t));
                    col += HeadLights(i + n * stp * .7, t);
                }

                #ifndef GL_ES
                    #ifdef HIGH_QUALITY
                        stp = 1. / 32.;
                    #else
                        stp = 1. / 16.;
                    #endif
                #endif

                for (i = 0.0; i < 1.0; i += stp) {
                    col += EnvironmentLights(i, t);
                }

                col += TailLights(0., t);
                col += TailLights(.5, t);

                col += sat(rd.y) * float3(.6, .5, .9);

                //fragColor = 
                return float4(col, 0.);
            }
            ENDCG
        }
    }
}
