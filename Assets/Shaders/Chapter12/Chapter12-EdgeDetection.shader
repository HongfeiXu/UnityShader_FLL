Shader "Unity Shaders Book/Chapter12/Edge Detection"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_EdgeOnly("Edge Only", Float) = 1.0
		_EdgeColor("Edge Color", Color) = (0,0,0,1)
		_BackgroundColor("Background Color", Color) = (1,1,1,1)
	}

	SubShader
	{
		Pass
		{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragSobel
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;	// xxx_TexelSize 是 xxx 纹理对应的每个纹素的大小
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
			};
			// appdata_img 为 Unity 内置的结构体，在 UnityCG.cginc 中定义
			v2f vert (appdata_img v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				half2 uv = v.texcoord;
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);

				return o;
			}

			// 计算亮度值
			fixed luminance(fixed4 color)
			{
				return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
			}

			half Sobel(v2f i)
			{
				const half Gx[9] = { -1, 0, 1,
					-2, 0, 2,
					-1, 0, 1 };
				const half Gy[9] = { -1, -2, -1,
					0, 0, 0,
					1, 2, 1 };

				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++)
				{
					texColor = luminance(tex2D(_MainTex, i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}

				half edge = abs(edgeX) + abs(edgeY);
				return edge;
			}
			
			fixed4 fragSobel (v2f i) : SV_Target
			{
				half edge = Sobel(i);

				fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), 1 - edge);		// 背景为原图下的颜色值
				fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, 1- edge);					// 背景为纯色下的颜色值
				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
			}

			ENDCG
		}
	}

	Fallback Off
}
