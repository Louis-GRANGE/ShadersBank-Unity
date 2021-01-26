Shader"Custom/Essai14"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _IlluminCol ("Self-Illumination color (RGB)", Color) = (1,1,1,1)
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
                constantColor[_IlluminCol]
                combine constant lerp (texture) previous
            }
            SetTexture [_MainTex] {
                combine previous*texture}
        }
    }
}