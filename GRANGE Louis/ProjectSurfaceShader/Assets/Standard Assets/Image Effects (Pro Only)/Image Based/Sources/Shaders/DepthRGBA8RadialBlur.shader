// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/DepthRGBA8RadialBlur" 
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "" {}
	}
	
	// Shader code pasted into all further CGPROGRAM blocks
	CGINCLUDE
		
	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
		float2 blurVector : TEXCOORD1;
	};
		
	sampler2D _MainTex;
	
	float4 blurRadius4;
	float4 sunPosition;

	float4 _MainTex_TexelSize;
		
	v2f vert( appdata_img v ) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy =  v.texcoord.xy;
		
		o.blurVector = (sunPosition.xy - v.texcoord.xy) * blurRadius4.xy;	
		
		return o; 
	}
	
	half4 frag(v2f i) : COLOR 
	{
		half4 color = half4(0,0,0,0);
		
		// we always step away from the sun
		// dist constantly increases by the length of o.blurVector
		half dist = sunPosition.w - length(sunPosition.xy-i.uv.xy);
		half blurVectorLen = length(i.blurVector);
		
		// we can achieve max 6 iterations for shader model 2.0
		for(int j = 0; j < 6; j++)   
		{	
			half4 tmpColor = tex2D(_MainTex, i.uv.xy);
			color += tmpColor * saturate(dist);
			
			i.uv.xy += i.blurVector;
			dist += blurVectorLen;
		}
		
		return color / 6.0;
	}

	ENDCG
	
Subshader 
{
 Blend One Zero
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest
      #pragma vertex vert
      #pragma fragment frag
      
      ENDCG
  } // Pass
} // Subshader

Fallback off

} // shader