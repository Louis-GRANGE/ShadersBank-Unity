Shader "Custom/Essai13"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }
    
    SubShader
    {
        Pass
        {
            Material
            {
                Diffuse (1,1,1,1)
                Ambient (1,1,1,1)
            }
            Lighting On
            
            SetTexture [_MainTex]
            {
                constantColor(1,1,1,1)
                combine constant lerp (texture) previous
            }
            SetTexture [_MainTex] {
                combine previous*texture}
        }
    }
}