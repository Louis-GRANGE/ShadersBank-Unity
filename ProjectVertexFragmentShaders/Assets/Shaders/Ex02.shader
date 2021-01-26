// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"Unlit/Ex02"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            #include "UnityCG.cginc"

            float4 vert(appdata_base v) : POSITION
            {
	            return UnityObjectToClipPos(v.vertex);
            }

            fixed4 frag(float4 sp:WPOS) : COLOR
            {
	            return fixed4(sp.xy/_ScreenParams.xy, 0.0, 1.0);
            }
            ENDCG
        }
    }
}
