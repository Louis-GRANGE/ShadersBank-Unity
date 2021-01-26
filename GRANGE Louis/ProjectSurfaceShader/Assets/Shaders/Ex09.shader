Shader"Custom/Ex09"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Bumpmap", 2D) = "bump" {}
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
            float2 uv_BumpMap;
            float3 worldRefl;
                    INTERNAL_DATA
        };
        sampler2D _MainTex;
        sampler2D _BumpMap;
        samplerCUBE _Cube;
        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
            o.Emission = texCUBE(_Cube, WorldReflectionVector(IN, o.Normal)).rgb; //Faire Attention à l'inversion entre ces 2 lignes.
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); //Variable utilisé avant
        }
        ENDCG
    }
    FallBack"Diffuse"
}
