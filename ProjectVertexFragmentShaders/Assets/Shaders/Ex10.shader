Shader"Unlit/Ex10"
{
    Properties
    {
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
            uniform float _Size;
            float4 frag(v2f_img i) : COLOR
            {
	            float2 c = float2(0, 0);
	            c.x = i.uv.x * _Size + _ConstX;
	            c.y = i.uv.y * _Size + _ConstY;
                
                float2 z = float2(0, 0);
                z.x = c.x;
                z.y = c.y;
                
                float iteration = 0.0;
                const float _MaxIter = 10.0;
                float x, y;
                
                for(iteration = 0.0; iteration < _MaxIter; iteration += 1.0)
	            {
                    x = z.x * z.x - z.y * z.y + c.x;
                    y = 2 * z.x * z.y + c.y;
                    
                    if(z.x * z.x + z.y * z.y > 4) break;
                    
                    z.x = x;
                    z.y = y;
	            }
                
                float4 color = float4(0.0, 0.0, 0.0, 1.0);
                
                if(iteration < _MaxIter)
                    color.rgb = 0.0;
                else
                    color.rgb = 1.0;
                    
                return color;      
            }
            ENDCG
        }
    }
}
