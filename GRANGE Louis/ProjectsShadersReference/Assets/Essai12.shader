Shader"Custom/Essai12"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlendTex ("Alpha Blended (RGBA)", 2D) = "white" {}
    }
    
    SubShader
    {
        Pass
        {
            SetTexture [_MainTex] {combine texture}
            SetTexture [_BlendTex] {combine texture lerp (texture) previous}
        }
    }
}