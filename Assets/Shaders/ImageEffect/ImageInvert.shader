Shader "ImageEffect/ImageInvert"
{
	Properties
	{
		_MainTex ("-", 2D) = "" {}
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	struct appdata_t
	{
		float4 vertex : POSITION;
		float4 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		float4 texcoord : TEXCOORD0;
	};
	ENDCG

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = i.texcoord.xy;

				fixed4 resultColor = tex2D(_MainTex, i.texcoord.xy);
				resultColor.rgb = 1- resultColor.rgb;

				
				return resultColor;
			}
			ENDCG
		}
	}
}