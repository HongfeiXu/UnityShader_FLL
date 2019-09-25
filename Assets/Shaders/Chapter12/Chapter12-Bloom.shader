
Shader "Unity Shaders Book/Chapter12/Bloom"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlurSize("Blur Size", Float) = 1.0
		_Bloom("Bloom Texture", 2D) = "white" {}
	}
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;	// xxx_TexelSize 是 xxx 纹理对应的每个纹素的大小
		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;

		// 我们首先定义提取较亮区域需要使用的顶点着色器和片元着色器
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vertExtractBright(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
			return o;
		}

		fixed luminance(fixed4 color)
		{
			return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}

		fixed4 fragExtractBright(v2f i) : SV_Target
		{
			fixed4 c = tex2D(_MainTex, i.uv);
			fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);

			return c * val;
		}

		// 然后，我们定义混合亮部图像和原图像时使用的顶点着色器和片元着色器
		
		struct v2fBloom 
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
		};

		v2fBloom vertBloom(appdata_img v)
		{
			v2fBloom o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord;
			o.uv.zw = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			// 主纹理和亮部纹理在竖直方向上朝向不同，对亮部纹理的采样坐标进行翻转
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0f - o.uv.w;
			#endif
			return o;
		}

		fixed4 fragBloom(v2fBloom i) : SV_Target
		{
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
		}

		ENDCG

		ZTest Always Cull Off ZWrite Off

		// Pass 0
		Pass
		{
			CGPROGRAM
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright
			ENDCG
		}

		// 直接使用在 Gaussian Blur 中定义的 Pass

		// Pass 1
		UsePass "Unity Shaders Book/Chapter12/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"

		// Pass 2
		UsePass "Unity Shaders Book/Chapter12/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"

		// Pass 3
		Pass
		{
			CGPROGRAM
			#pragma vertex vertBloom
			#pragma fragment fragBloom
			ENDCG
		}
	}
	Fallback Off
}
