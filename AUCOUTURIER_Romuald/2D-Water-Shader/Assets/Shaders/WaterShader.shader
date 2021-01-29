// Made By Stefan Jovanović

Shader "Custom/WaterShader" {
	Properties {
		_MainTex("Texture", 2D) = "white" {}
		_DisplacementTex("Displacement Texture", 2D) = "white" {}
		_DisplacementSpeedDivider("Displacement Speed", Float) = 30
		_DisplacementDetailTex("Displacement Detail Texture", 2D) = "white" {}
		_DisplacementDetailSpeedDivider("Displacement Detail Speed", Float) = 60
		_DisplacementAmountDivider("Displacement Amount Divider", Float) = 40
		_Tint("Tint", Color) = (1,1,1,1)
		_FoamThreshold("Foam Threshold", Float) = 0.022
		_EdgeFoamThreshold("Egde Foam Threshold", Float) = 0.005
		_FoamAlpha("Foam Alpha", Range(0,1)) = 1
		_ParallaxDivider("Parallax Divider", Float) = 20
		[Toggle(PERSPECTIVE_CORRECTION)]
		_PerspectiveCorrection("Perspective Correction", Float) = 0
		[Toggle(VERTEX_DISPLACEMENT)]
		_VertexDisplacement("Vertex Displacement", Float) = 0
		_VertexDisplacementTex("Vertex Displacement Texture", 2D) = "white" {}
		_VertexDisplacementAmountDivider("Vertex Displacement Amount Divider", Float) = 60
		_VertexDisplacementSpeedDivider("Vertex Displacement Speed Divider", Float) = 40
	}
	SubShader {
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma shader_feature PERSPECTIVE_CORRECTION
			#pragma shader_feature VERTEX_DISPLACEMENT

			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _DisplacementTex;
			sampler2D _DisplacementDetailTex;
			sampler2D _VertexDisplacementTex;
			float4 _MainTex_ST;
			float4 _Tint;
			float _DisplacementSpeedDivider;
			float _DisplacementDetailSpeedDivider;
			float _DisplacementAmountDivider;
			float _FoamThreshold;
			float _FoamAlpha;
			float _EdgeFoamThreshold;
			float _VertexDisplacementAmountDivider;
			float _VertexDisplacementSpeedDivider;
			float _ParallaxDivider;

			v2f vert(appdata v) {
				v2f o;
				// Récuperation des vertex
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//vertex displacement
#ifdef VERTEX_DISPLACEMENT
				o.vertex.xy += (2 * tex2Dlod(_VertexDisplacementTex,
					float4(o.uv.xy+_Time[1]/_VertexDisplacementSpeedDivider, 0, 0)).rg - 1) / _VertexDisplacementAmountDivider;
#endif
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			//desaturation
			half3 AdjustContrastCurve(half3 color, half contrast) {
				// Permet d'ajuster la valeur de la couleur par rappport à un constrast
				return pow(abs(color * 2 - 1), 1 / max(contrast, 0.0001)) * sign(color - 0.5) + 0.5;
			}

			//rgb to grayscale
			float Grayscale(float3 inputColor) {
				// Permet de retourner la couleur transformer dans les gris
				return dot(inputColor.rgb, float3(0.2126, 0.7152, 0.0722));
			}

			fixed4 frag(v2f i) : SV_Target {
				// sample the texture
				// flipping the uv plane
				i.uv.y = 1.0 - i.uv.y;

				// Variable pour le flou
				half2 offset;

				// Position de l'uv en x par rapport au temps
				float iuvxt = i.uv.x + _Time[1];
				float wp = _WorldSpaceCameraPos.x / _ParallaxDivider;

				// récupére les informations de la texture par rapport à la position de l'uv en x
				// diviser par DisplacementDetailSpeedDivider plus la position de la caméra diviser par le parallax
#ifdef PERSPECTIVE_CORRECTION
				// Correction de la perspective en fonction de la valeur des UV's
				half2 perspectiveCorrection = half2(2 * (0.5 - i.uv.x) * i.uv.y, 0);

				// On ajoute la correction de perspective au UV
				offset = tex2D(_DisplacementTex, float2(iuvxt / _DisplacementSpeedDivider + wp, i.uv.y) + perspectiveCorrection).rg
					+ tex2D(_DisplacementDetailTex, float2(iuvxt / _DisplacementDetailSpeedDivider + wp, i.uv.y) + perspectiveCorrection).rg;
#else
				offset = tex2D(_DisplacementTex, float2(iuvxt / _DisplacementSpeedDivider + wp, i.uv.y)).rg
					+ tex2D(_DisplacementDetailTex, float2(iuvxt / _DisplacementDetailSpeedDivider + wp, i.uv.y)).rg;
#endif

				// Ajuste l'UV pour qu'il soit entre 0 et 1
				float2 adjusted = i.uv.xy + (offset - 0.5) / _DisplacementAmountDivider;

				// Get color of main texture to ajusted uv position
				fixed4 col = tex2D(_MainTex, adjusted);
				// Ajuste la couleur 
				fixed4 colAdj = col * float4(AdjustContrastCurve(_Tint, 1 - Grayscale(col)).rgb, 1);

				//foam thresholding
				if ((abs((offset.x - 0.5) / _DisplacementAmountDivider) > _FoamThreshold && abs((offset.y - 0.5) / _DisplacementAmountDivider)
					> _FoamThreshold) || i.uv.y < _EdgeFoamThreshold * (offset.x - 0.5) / _DisplacementAmountDivider)
					return (1, 1, 1, _FoamAlpha) + (1 - _FoamAlpha) * colAdj;

				return colAdj;
			}

			ENDCG
		}
	}
}
