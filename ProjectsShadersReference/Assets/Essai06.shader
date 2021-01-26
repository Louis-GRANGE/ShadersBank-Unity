Shader"Custom/Essai06"
{
    Properties
    {
        _Color ("Main Color", COLOR) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            Material
            {
                Diffuse [_Color]
                Ambient [_Color]
            }
            Lighting On
        }
    }
}
