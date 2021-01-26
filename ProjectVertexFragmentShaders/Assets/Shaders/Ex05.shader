Shader"Unlit/Ex05"
{
    Properties
    {
        _CircTexX ("Circle in X", Float) = 20
        _CircTexY ("Circle in Y", Float) = 20
        _Fade ("Fade", Range(0.1, 1.0)) = 0.5
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            #include "UnityCG.cginc"

            uniform float _CircTexX;
            uniform float _CircTexY;
            uniform float _Fade;
            float4 vert(appdata_base v) : POSITION
            {
	            return UnityObjectToClipPos(v.vertex);
            }

            fixed4 frag(float4 sp : VPOS) : COLOR
            {
	            float2 wcoord = sp.xy / _ScreenParams.xy;
                float4 color;
                
                if(length(fmod(float2(_CircTexX*wcoord.x, _CircTexY*wcoord.y), 2.0)-1.0) < _Fade)
	            {
                    color = float4(sp.xy/_ScreenParams.xy, 0.0, 1.0);
	            }
                else
	            {
                    color = float4(0.3, 0.3, 0.3, 1.0);
	            }
	            return color;
            }
            ENDCG
        }
    }
}
