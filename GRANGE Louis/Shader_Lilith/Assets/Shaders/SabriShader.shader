Shader "Unlit/SabriShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_ResolutionX ("Resolution X", Range(0.0, 2000)) = 0.0
        _ResolutionY ("Resolution Y", Range(0.0, 2000)) = 0.0
        _Size ("Size", Range(0.0, 3000)) = 0.0
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
			uniform float _ResolutionX;
			uniform float _ResolutionY;
			uniform float _Size;
			uniform float _TimeMultiplicator;

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
			
			float sun(float2 uv, float battery)
			{
				float val = smoothstep(0.3, 0.29, length(uv));
				float bloom = smoothstep(0.7, 0.0, length(uv));
				float cut = 3.0 * sin((uv.y + _Time * _TimeMultiplicator * 0.2 * (battery + 0.02)) * 100.0)
							+ clamp(uv.y * 14.0 + 1.0, -6.0, 6.0);
				cut = clamp(cut, 0.0, 1.0);
				return clamp(val * cut, 0.0, 1.0) + bloom * 0.6;
			}

			float grid(float2 uv, float battery)
			{
				float2 size = float2(uv.y, uv.y * uv.y * 0.2) * 0.01;
				uv += float2(0.0, _Time.x * _TimeMultiplicator * 4.0 * (battery + 0.05));
				uv = abs(frac(uv) - 0.5);
				float2 lines = smoothstep(size, float2(0.0, 0.0), uv);
				lines += smoothstep(size * 5.0, float2(0.0, 0.0), uv) * 0.4 * battery;
				return clamp(lines.x + lines.y, 0.0, 3.0);
			}

			float dot2(in float2 v)
			{
				return dot(v, v);
			}

			float sdTrapezoid(in float2 p, in float r1, float r2, float he)
			{
				float2 k1 = float2(r2, he);
				float2 k2 = float2(r2 - r1, 2.0 * he);
				p.x = abs(p.x);
				float2 ca = float2(p.x - min(p.x, (p.y < 0.0) ? r1 : r2), abs(p.y) - he);
				float2 cb = p - k1 + k2 * clamp(dot(k1 - p, k2) / dot2(k2), 0.0, 1.0);
				float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
				return s * sqrt(min(dot2(ca), dot2(cb)));
			}

			float sdLine(in float2 p, in float2 a, in float2 b)
			{
				float2 pa = p - a, ba = b - a;
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
				return length(pa - ba * h);
			}

			float sdBox(in float2 p, in float2 b)
			{
				float2 d = abs(p) - b;
				return length(max(d, float2(0.0, 0.0))) + min(max(d.x, d.y), 0.0);
			}

			float opSmoothUnion(float d1, float d2, float k)
			{
				float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
				return lerp(d2, d1, h) - k * h * (1.0 - h);
			}

			float sdCloud(in float2 p, in float2 a1, in float2 b1, in float2 a2, in float2 b2, float w)
			{
				//float lineVal1 = smoothstep(w - 0.0001, w, sdLine(p, a1, b1));
				float lineVal1 = sdLine(p, a1, b1);
				float lineVal2 = sdLine(p, a2, b2);
				float2 ww = float2(w * 1.5, 0.0);
				float2 left = max(a1 + ww, a2 + ww);
				float2 right = min(b1 - ww, b2 - ww);
				float2 boxCenter = (left + right) * 0.5;
				//float boxW = right.x - left.x;
				float boxH = abs(a2.y - a1.y) * 0.5;
				//float boxVal = sdBox(p - boxCenter, float2(boxW, boxH)) + w;
				float boxVal = sdBox(p - boxCenter, float2(0.04, boxH)) + w;
    
				float uniVal1 = opSmoothUnion(lineVal1, boxVal, 0.05);
				float uniVal2 = opSmoothUnion(lineVal2, boxVal, 0.05);
    
				return min(uniVal1, uniVal2);
			}

			float4 mainImage(float4 vertex : POSITION, float2 uv : TEXCOORD0) : SV_Target
			{
				float3 color;
				float2 fragCoord = uv * float2(1024, 1024);
				float2 fuv = (fragCoord - 0.5 * float2(_ResolutionX, _ResolutionY)) / _Size;
				//float2 uv = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
				float battery = 1.0;
				//if (iMouse.x > 1.0 && iMouse.y > 1.0) battery = iMouse.y / iResolution.y;
				//else battery = 0.8;
    
				//if (abs(uv.x) < (9.0 / 16.0))
				{
					// Grid
					float fog = smoothstep(0.1, -0.02, abs(fuv.y + 0.2));
					float3 col = float3(0.0, 0.1, 0.2);
					if (fuv.y < -0.2)
					{
						fuv.y = 3.0 / (abs(fuv.y + 0.2) + 0.05);
						fuv.x *= fuv.y * 1.0;
						float gridVal = grid(fuv, battery);
						col = lerp(col, float3(1.0, 0.5, 1.0), gridVal);
					}
					else
					{
						float fujiD = min(fuv.y * 4.5 - 0.5, 1.0);
						fuv.y -= battery * 1.1 - 0.51;
            
						float2 sunUV = fuv;
						float2 fujiUV = fuv;
            
						// Sun
						sunUV += float2(0.75, 0.2);
						//uv.y -= 1.1 - 0.51;
						col = float3(1.0, 0.2, 1.0);
						float sunVal = sun(sunUV, battery);
            
						col = lerp(col, float3(1.0, 0.4, 0.1), sunUV.y * 2.0 + 0.2);
						col = lerp(float3(0.0, 0.0, 0.0), col, sunVal);
            
						// fuji
						float fujiVal = sdTrapezoid(fuv + float2(-0.75 + sunUV.y * 0.0, 0.5), 1.75 + pow(fuv.y * fuv.y, 2.1), 0.2, 0.5);
						float waveVal = fuv.y + sin(fuv.x * 20.0 + _Time * _TimeMultiplicator * 2.0) * 0.05 + 0.2;
						float wave_width = smoothstep(0.0, 0.01, (waveVal));
            
						// fuji color
						col = lerp(col, lerp(float3(0.0, 0.0, 0.25), float3(1.0, 0.0, 0.5), fujiD), step(fujiVal, 0.0));
						// fuji top snow
						col = lerp(col, float3(1.0, 0.5, 1.0), wave_width * step(fujiVal, 0.0));
						// fuji outline
						col = lerp(col, float3(1.0, 0.5, 1.0), 1.0 - smoothstep(0.0, 0.01, abs(fujiVal)));
						//col = lerp( col, float3(1.0, 1.0, 1.0), 1.0-smoothstep(0.03,0.04,abs(fujiVal)) );
						//col = float3(1.0, 1.0, 1.0) *(1.0-smoothstep(0.03,0.04,abs(fujiVal)));
            
						// horizon color
						col += lerp(col, lerp(float3(1.0, 0.12, 0.8), float3(0.0, 0.0, 0.2), clamp(fuv.y * 3.5 + 3.0, 0.0, 1.0)), step(0.0, fujiVal));
            
						// cloud
						float2 cloudUV = fuv;
						cloudUV.x = fmod(cloudUV.x + _Time * _TimeMultiplicator * 0.1, 4.0) - 2.0;
						float cloudTime = _Time * _TimeMultiplicator * 0.5;
						float cloudY = -0.5;
						float cloudVal1 = sdCloud(cloudUV,
												 float2(0.1 + sin(cloudTime + 140.5) * 0.1, cloudY),
												 float2(1.05 + cos(cloudTime * 0.9 - 36.56) * 0.1, cloudY),
												 float2(0.2 + cos(cloudTime * 0.867 + 387.165) * 0.1, 0.25 + cloudY),
												 float2(0.5 + cos(cloudTime * 0.9675 - 15.162) * 0.09, 0.25 + cloudY), 0.075);
						cloudY = -0.6;
						float cloudVal2 = sdCloud(cloudUV,
												 float2(-0.9 + cos(cloudTime * 1.02 + 541.75) * 0.1, cloudY),
												 float2(-0.5 + sin(cloudTime * 0.9 - 316.56) * 0.1, cloudY),
												 float2(-1.5 + cos(cloudTime * 0.867 + 37.165) * 0.1, 0.25 + cloudY),
												 float2(-0.6 + sin(cloudTime * 0.9675 + 665.162) * 0.09, 0.25 + cloudY), 0.075);
            
						float cloudVal = min(cloudVal1, cloudVal2);
            
						//col = lerp(col, float3(1.0,1.0,0.0), smoothstep(0.0751, 0.075, cloudVal));
						col = lerp(col, float3(0.0, 0.0, 0.2), 1.0 - smoothstep(0.075 - 0.0001, 0.075, cloudVal));
						col += float3(1.0, 1.0, 1.0) * (1.0 - smoothstep(0.0, 0.01, abs(cloudVal - 0.075)));
					}

					col += fog * fog * fog;
					col = lerp(float3(col.r, col.r, col.r) * 0.5, col, battery * 0.7);

					return float4(col, 1.0);
				}    
			}
            ENDCG
        }
    }
}
