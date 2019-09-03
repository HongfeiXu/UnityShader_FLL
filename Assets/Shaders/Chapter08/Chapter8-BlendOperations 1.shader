// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	透明度混合之常见的混合类型
	逐片元着色
	纹理（为了更清楚的看到混合效果，这里去掉了光照模型）
*/

Shader "Unity Shaders Book/Chapter8/Blend Operations 1"
{
	Properties
	{
		_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white"{}
		_AlphaScale("Alpha Scale", Range(0, 1)) = 1		// 控制整体的透明度
	}

	SubShader
	{
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

		Pass
		{
			Tags {"LightMode" = "ForwardBase"}

			// 关闭深度写入
			ZWrite Off

			// 开启并设置此Pass的混合模式，
			// Normal
			BlendOp Add
			Blend SrcAlpha OneMinusSrcAlpha

			// Soft Additive
			BlendOp Add
			Blend OneMinusDstColor One

			// Multiply
			BlendOp Add
			Blend DstColor Zero

			// 2x Multiply
			BlendOp Add
			Blend DstColor SrcColor

			// Darken
			BlendOp Min
			Blend One One

			// Lighten
			BlendOp Max
			Blend One One

			// Screen
			BlendOp Add
			Blend OneMinusDstColor One

			// Linear Dodge
			BlendOp Add
			Blend One One

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			fixed _AlphaScale;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv);

				return fixed4(texColor.rgb * _Color.rgb, texColor.a * _AlphaScale);	// 设置透明通道（只有在开启混合模式后才有效）
			}

			ENDCG
		}
	}
	Fallback "Transparent/VertexLit"
}