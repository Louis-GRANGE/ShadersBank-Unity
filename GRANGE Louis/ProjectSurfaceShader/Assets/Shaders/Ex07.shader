Shader"Custom/Ex07"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cube ("Cubemap", CUBE) = "" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert

        struct Input
        {
            float2 uv_MainTex;
            float3 worldRefl;
        };
        sampler2D _MainTex;
        samplerCUBE _Cube;
        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
            o.Emission = texCUBE(_Cube, IN.worldRefl).rgb;
        }
        ENDCG
    }
FallBack"Diffuse"
}
