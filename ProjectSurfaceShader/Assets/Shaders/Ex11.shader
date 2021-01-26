Shader"Custom/Ex11"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}     
        _Amount ("Extrusion Amount", Range(-0.0005, 0.0005)) = 0.005
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert vertex:vert

        struct Input
        {
            float2 uv_MainTex;
        };
        float _Amount;
        void vert(inout appdata_full v)
        {
            v.vertex.xyz += v.normal*_Amount;
        }
        sampler2D _MainTex;
        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
        }
        ENDCG
    }
    FallBack"Diffuse"
}
