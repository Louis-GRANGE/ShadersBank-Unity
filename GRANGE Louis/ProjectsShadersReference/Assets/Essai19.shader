Shader"Custom/Essai19"
{
    Properties
    {
        _MainTex ("Texture to Blend", 2D) = "black" {}
        _Range ("Transparancy", Range(0.01, 0.99)) = 0.5
    }
    
    SubShader
    {
        Tags{"Queue" = "Transparent"}
        Pass
        {
            Blend One One
            AlphaTest Greater[_Range]
            SetTexture [_MainTex] {
                combine texture
            }
        }
    }
}