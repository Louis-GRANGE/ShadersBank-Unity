Shader"Unlit/Ex12"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
        _NbIteration("Nombre d'iterations", Range(0, 100)) = 0.0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            
            uniform float _NbIteration;
            uniform sampler2D _MainTex;
            float4 frag(v2f_img i) : COLOR
            {
	            float2 c = float2(0, 0);
	            c.x = i.uv.x * 2.4 - 1.9;
	            c.y = i.uv.y * 2.4 - 1.2;
                
	            float2 z = float2(0, 0);
	            z.x = c.x;
	            z.y = c.y;
                
	            float iteration = 0.0;
	            const float _MaxIter = _NbIteration;
	            float x, y;
                
	            for (iteration = 0.0; iteration < _MaxIter; iteration += 1.0)
	            {
		            x = z.x * z.x - z.y * z.y + c.x;
		            y = 2 * z.x * z.y + c.y;
                    
		            if (z.x * z.x + z.y * z.y > 4)
			            break;
                    
		            z.x = x;
		            z.y = y;
	            }
                
	            float4 color = float4(0.0, 0.0, 0.0, 1.0);
	            if (iteration < _MaxIter)
		            color.rgb = tex2D(_MainTex, iteration / _MaxIter) * iteration / 10;
	            else
		            color.rgb = 0.0;
                    
	            return color;
            }
            ENDCG
        }
    }
}
