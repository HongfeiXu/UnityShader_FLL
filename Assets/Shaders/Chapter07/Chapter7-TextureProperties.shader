// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	测试纹理图片的属性
	Wrap Mode
	Filter Mode
	MipMapping
	...
*/
Shader "Unity Shaders Book/Chapter7/Texture Properties"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white"{}				// 纹理
	}
	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			struct a2v{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				// Transforms 2D UV by scale/bias property
				//o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 c = tex2D(_MainTex, i.uv).rgb;

				return fixed4(c, 1.0);
			}
		
			ENDCG
		}
	}

	Fallback "Diffuse"
}
