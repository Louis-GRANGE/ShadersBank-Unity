Shader"Custom/Ex18"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("Ramp Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Ramp
        sampler _RampTex;
        half4 LightingRamp(SurfaceOutput s, half3 lightDir, half atten)
        {
            half NdotL = dot(s.Normal, lightDir);
            half diff = NdotL * 0.5 + 0.5;
            half3 ramp = tex2D(_RampTex, float2(diff, diff)).rgb;
            half4 c;
            c.rgb = s.Albedo * _LightColor0.rgb * ramp * atten;
            c.a = s.Alpha;
            return c;
        }
        
        struct Input
        {
            float2 uv_MainTex;
        };
        sampler2D _MainTex;
        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
        }
        ENDCG
    }
FallBack"Diffuse"
}
