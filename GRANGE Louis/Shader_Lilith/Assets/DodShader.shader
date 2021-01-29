Shader "Unlit/DodShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ResolutionX("Resolution X", Range(0.0, 2000)) = 0.0
        _ResolutionY("Resolution Y", Range(0.0, 2000)) = 0.0
        _Size("Size", Range(0.0, 10)) = 0.0
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

            float opSmoothUnion(float d1, float d2, float k)
            {
                float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
                return lerp(d2, d1, h) - k * h * (1.0 - h);
            }

            float sdSphere(float3 p, float s)
            {
                return length(p) - s;
            }

            float map(float3 p)
            {
                float d = 2.0;
                for (int i = 0; i < 16; i++) {
                    float fi = float(i);
                    float time = _Time * 30.0 * (frac(fi * 412.531 + 0.513) - 0.5) * 2.0;
                    d = opSmoothUnion(
                        sdSphere(p + sin(time + fi * float3(52.5126, 64.62744, 632.25)) * float3(2.0, 2.0, 0.8), lerp(0.5, 1.0, frac(fi * 412.531 + 0.5124))),
                        d,
                        0.4
                    );
                }
                return d;
            }

            float3 calcNormal(in float3 p)
            {
                const float h = 1e-5; // or some other value
                const float2 k = float2(1, -1);
                return normalize(k.xyy * map(p + k.xyy * h) +
                    k.yyx * map(p + k.yyx * h) +
                    k.yxy * map(p + k.yxy * h) +
                    k.xxx * map(p + k.xxx * h));
            }

            float4 mainImage(float4 vertex:POSITION, float2 uv : TEXCOORD0) : SV_Target
            {
                float2 fragCoord = uv * float2(1024, 1024);
                float2 fuv = fragCoord / float2(_ResolutionX, _ResolutionY) / _Size;

                // screen size is 6m x 6m
                float3 rayOri = float3((fuv - 0.5) * float2(_ResolutionX / _ResolutionY, 1.0) * 6.0, 3.0);
                float3 rayDir = float3(0.0, 0.0, -1.0);

                float depth = 0.0;
                float3 p;

                for (int i = 0; i < 64; i++) {
                    p = rayOri + rayDir * depth;
                    float dist = map(p);
                    depth += dist;
                    if (dist < 1e-6) {
                        break;
                    }
                }

                depth = min(6.0, depth);
                float3 n = calcNormal(p);
                float b = max(0.0, dot(n, float3(0.577, 0.577, 0.577)));
                float3 col = (0.5 + 0.5 * cos((b + _Time * 3.0) + uv.xyx * 2.0 + float3(0, 2, 4))) * (0.85 + b * 0.35);
                col *= exp(-depth * 0.15);

                // maximum thickness is 2m in alpha channel
                return float4(col, 1.0 - (depth - 0.5) / 2.0);
            }
            ENDCG
        }
    }
}
