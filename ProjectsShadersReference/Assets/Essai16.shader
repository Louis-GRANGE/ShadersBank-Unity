Shader"Custom/Essai16"
{
    Properties
    {
        _MainTex ("Base (RGB) Transparancy (A)", 2D) = "white" {}
        _Range ("Transparancy", Range(0.01, 0.99)) = 0.5
    }
    
    SubShader
    {
        Pass
        {
            AlphaTest Greater [_Range]
            SetTexture [_MainTex] {
                combine texture
            }
        }
    }
}