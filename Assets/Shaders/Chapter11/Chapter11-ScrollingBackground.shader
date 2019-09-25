Shader "Unity Shaders Book/Chapter11/ScrollingBackground"
{
	Properties
	{
		_MainTex ("Base Layer (RGB)", 2D) = "white" {}
		_DetailTex("2nd Layer (RGB)", 2D) = "white" {}
		_ScrollX("Base layer Scroll Speed", Float) = 1.0
		_Scroll2X("2nd layer Scroll Speed", Float) = 1.0
		_Multiplier("Layer Multiplier", Float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _DetailTex;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Multiplier;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
				o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
				fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
				fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
				c.rgb *= _Multiplier;
				return c;
			}
			ENDCG
		}
	}
	Fallback "VertexLit"
}
