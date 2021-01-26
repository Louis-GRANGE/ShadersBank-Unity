Shader "Custom/Essai03"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
    }

    SubShader
    {
        Pass
        {
            Lighting Off
            SetTexture[_MainTex]
        }
    }
}
