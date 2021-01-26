Shader "Unlit/Ex06"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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

            float4 frag (fragmentInput i) : COLOR
            {
                return float4(i.texcoord0.xy, 0.0, 1.0);
            }
            ENDCG
        }
    }
}
