Shader"Unlit/Ex14"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
        _NbIteration("Nombre d'iterations", Range(0, 100)) = 0.0
        
        _MoveX("MoveX", Range(-10, 10)) = 0.0
        _MoveY("MoveY", Range(-10, 10)) = 0.0
        
        _ConstX("ConstanteX", Range(-10, 10)) = 0.0
        _ConstY("ConstanteY", Range(-10, 10)) = 0.0
        
        _Size("Size", Range(-10, 10)) = 0.0
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
            uniform float _ConstX;
            uniform float _ConstY;
            
            uniform float _MoveX;
            uniform float _MoveY;
            
            uniform float _NbIteration;
            uniform sampler2D _MainTex;
            uniform float _Size;
            
            float4 frag(v2f_img i) : COLOR
            {
	            float2 c = float2(_ConstX, _ConstY);                
                
	            float2 z = float2(0, 0);
	            z.x = i.uv.x * _Size + _MoveX;
	            z.y = i.uv.y * _Size + _MoveY;
                
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
