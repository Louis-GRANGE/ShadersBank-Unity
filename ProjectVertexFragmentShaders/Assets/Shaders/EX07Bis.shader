Shader"Unlit/Ex07Bis"
{
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

			float4 frag(v2f_img i) : COLOR
			{
				bool p = fmod(i.uv.x * 8.0, 2.0) < 1.0;
				bool q = fmod(i.uv.y * 8.0, 2.0) > 1.0;
				
	            bool rep = !((p && q) || !(p || q));
				return float4(float3(rep, rep, rep), 1.0);
			}
            ENDCG
        }
    }
}
