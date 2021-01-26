Shader"Custom/Ex10"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Bumpmap", 2D) = "bump" {}
        
        _SliceMultiplicator ("Slice Multiplicator", Range(-10, 10)) = 0.1
        _SliceSize ("Slice Size", Range(0, 100)) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        cull Off
        
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float3 worldPos;
        };
        sampler2D _MainTex;
        sampler2D _BumpMap;
        float _SliceMultiplicator;
        float _SliceSize;
        void surf(Input IN, inout SurfaceOutput o)
        {
            clip(frac((IN.worldPos.y + IN.worldPos.z * _SliceMultiplicator) * _SliceSize) - 0.5);
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }
        ENDCG
    }
    FallBack"Diffuse"
}
