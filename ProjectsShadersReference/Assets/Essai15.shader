Shader"Custom/Essai15"
{
    Properties
    {
        _Illumination("Illumination", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,0)
        _SpecColor("Spec Color", Color) = (1,1,1,1)
        _Emission("Emmisive", Color) = (0,0,0,0)
        _Shininess("Shininess", Range(0.01,1)) = 0.7
    }
    
    SubShader
    {
       Pass{
           Material {
                Diffuse[_Color]
                Ambient[_Color]
                Shininess[_Shininess]
                Specular[_SpecColor]
                Emission[_Emission]
            }
            Lighting On


            SetTexture[_MainTex] {
                constantColor[_Illumination]
                combine constant lerp(texture) previous
            }

            SetTexture[_MainTex]{
                combine previous* texture
            }
       }
    }
}