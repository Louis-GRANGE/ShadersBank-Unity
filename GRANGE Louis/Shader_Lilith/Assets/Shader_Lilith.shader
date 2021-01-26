// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Shader_Lilith"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ResolutionX ("Resolution X", Float) = 0.0
        _ResolutionY ("Resolution Y", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            int mat_id = 0;
			
			uniform sampler2D _MainTex;
			uniform float _ResolutionX;
			uniform float _ResolutionY;
			
            struct obj
            {
	            float d;
	            int mat_id;
            };
			float4 rot(float a)
            {
				return float4(cos(a), -sin(a), sin(a), cos(a));
			}

            float random(float2 p)
            {
	            return (frac(sin(p.x * 431. + p.y * 707.) * 7443.));
            }

			float noise2d(float2 uv)
			{
				float2 id = floor(uv * 10.);
				float2 lc = smoothstep(0., 1., frac(uv * 10.));
    
	            float a = random(id);
	            float b = random(id + float2(1., 0.));
	            float c = random(id + float2(0., 1.));
	            float d = random(id + float2(1., 1.));
    
	            float ud = lerp(a, b, lc.x);
	            float lr = lerp(c, d, lc.x);
	            float fin = lerp(ud, lr, lc.y);
	            return fin;
            }
			float noise3d(float3 x)
			{
				float3 f = frac(x);
				float3 p = x - f;
				f = smoothstep(0., 1., f);
				float2 uv = (p.xy + float2(37.0, 17.0) * p.z) + f.xy;
				float2 rg = tex2D(_MainTex, (uv + 0.5) / 256.0).rg; //dernier paramètre ",-100)"
				return lerp(rg.y, rg.x, f.z);
			}

			float octaves(float2 uv)
			{
				float amp = 0.5;
				float f = 0.;
				for (int i = 1; i < 5; i++)
				{
					f += noise2d(uv) * amp;
					uv *= 2.;
					amp *= 0.5;
				}
				return f;
			}

			float octaves3(float3 p)
			{
				float amp = 0.5;
				float f = 0.;
				for (int i = 1; i < 4; i++)
				{
					f += noise3d(p) * amp;
					p *= 2.5;
					amp *= 0.75;
				}
				return f;
			}

			obj minobj(obj a, obj b)
			{
				if (a.d < b.d)
					return a;
				return b;
			}

			obj plane(float3 p)
			{
				obj myobj;
				myobj.d = p.y;
				myobj.mat_id = 4;
				return myobj;
			}

			obj sphere(float3 p, float r)
			{
				obj myobj;
				myobj.d = length(p) - r;
				myobj.mat_id = 2;
				return myobj;
			}

			obj flame(float3 p)
			{
				p.y *= .9;
				p.xz *= rot(p.y * 5.0).xz;
				float res = sphere(p, .35).d;
				res -= .3 * octaves3((p + float3(0., - _Time.x * .4, 0.)) * 3.4) * (p.y) * 1.8;
				obj myobj;
				myobj.d = res;
				myobj.mat_id = 3;
				return myobj;
			}

			obj map(float3 p)
			{
				obj fire = flame(p + float3(0, 1.7, 0));
				obj water = plane(p + ((sin(length(p.zx + _Time)) - 2.) * .05) + float3(0, 2.6 - octaves(p.xz * .05 + _Time * .05) * 0.3, 0));
				obj close = minobj(water, fire);
				mat_id = close.mat_id;
				return close;
			}

			float march(float3 ro, float3 rd)
			{
				float totalDistance = 0.;
				float dist = 0.;
				int o = 0;
				for (int i = 0; i < 70; i++)
				{
					o = i;
					dist = map(ro + rd * totalDistance).d;
					totalDistance += dist;
					if (dist < .1 || totalDistance > 70.)
						break;
				}
				if (dist > .1)
				{
					mat_id = 1;
				}
				if (mat_id == 3)
				{
					return float(o) / 70.;
				}
				return totalDistance;
			}

			float3 addLight(float3 lightCol, float3 lightdir, float3 rd)
			{
				float3 light = float3(0.0, 0.0, 0.0);
				float li = max(dot(lightdir, rd), 0.);
				light += pow(lightCol, float3(200.1, 0.0, 0.0)) * pow(li, 200.); //Mettre float3(200.1, 0.0, 0.0)
				light += lightCol * pow(li, 1.);
				return light;

			}

			float3 skyColor(float3 rd)
			{
				float3 outLight = float3(0.125, 0.0, 0.0); //Mettre float3(0.125, 0.0, 0.0)
				rd.zy *= rot(2.5);
				rd.xz *= rot(_Time / 25.);
				outLight += addLight(float3(0.7, 0.2, 0.0), normalize(float3(-0.4, -1.0, 0.9)), rd);
				outLight += addLight(float3(0.5, 0.1, 0.01), normalize(float3(-0.4, 1.0, -0.9)), rd);
				return outLight;
			}

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
			
			float4 frag(fragmentInput i) : COLOR
            {
				float2 uv = (i.texcoord0 - 0.5 * _ScreenParams.xy) / _ScreenParams.x;
				float3 ro = float3(0.0, -1.5, -3.5), rd = normalize(float3(uv, 1.0));
				ro.zy *= rot(0.1).zy;
				rd.zy *= rot(0.1).zy;
				ro.xz *= rot(_Time / 7.0).xz;
				rd.xz *= rot(_Time / 7.0).xz;
				float m = march(ro, rd);
				float3 col = ro + rd * m;
				if (mat_id == 1)
				{
					col = skyColor(rd);
				}
				/*if (mat_id == 3)
				{
					col = 5.0 * float3(m, m, m) + float3(0.9, 0, 0);
					col = (col) - 0.4;
				}
				if (mat_id == 4)
				{
					ro = col + 0.2;
					rd = reflect(rd, normalize(float3(0.0, 1, 0.0)));
					float m2 = march(ro, rd);
					col = ro + rd * m2;
					if (mat_id == 1)
					{
						col = skyColor(rd) / 2.5;
					}
					if (mat_id == 3)
					{
						col = col = 5. * float3(m2, m2, m2) + float3(0.9, 0, 0);
						col = (col) - 0.4;
					}
				}*/
				return float4((col), 1.0);
			}
            ENDCG
        }
    }
}
