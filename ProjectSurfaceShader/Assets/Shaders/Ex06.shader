Shader"Custom/Ex06"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("BumpMap", 2D) = "bump" {}
        _Detail ("Detail", 2D) = "gray" {}
        _Size ("Size texture", Vector) = (1,1,0,0)
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
            float4 screenPos;
        };
        sampler2D _MainTex;
        sampler2D _BumpMap;
        sampler2D _Detail;
        float2 _Size;
        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;    
            float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
            screenUV *= _Size;//float2(8,6);
            o.Albedo *= tex2D(_Detail, screenUV).rgb * 2;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }
        ENDCG
    }
FallBack"Diffuse"
}
