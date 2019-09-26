Shader "Unity Shaders Book/Chapter12/Motion Blur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlurSize("Blur Size", Float) = 1.0
	}
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		fixed _BlurAmount;

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		// appdata_img 为 Unity 内置的结构体，在 UnityCG.cginc 中定义
		v2f vert(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
			return o;
		}

		// 更新渲染纹理的RGB通道部分
		// 并将A通道设为_BlurAmount
		fixed4 fragRGB(v2f i) : SV_Target
		{
			return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
		}
		// 更新渲染纹理的A通道部分
		// 为了维护渲染纹理的A通道，不让其受到混合时使用的透明度值（即_BlurAmount）的影响
		half4 fragA(v2f i) : SV_Target
		{
			return tex2D(_MainTex, i.uv);
		}

		ENDCG

		ZTest Always Cull Off ZWrite Off
		// 基于 _BlurAmount 混合 source 与 accumulationTexture
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment fragRGB

			ENDCG
		}
		// 维护纹理的A不受到上述混合操作的影响
		Pass
		{
			Blend One Zero
			ColorMask A

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment fragA

			ENDCG
		}
	}
	Fallback Off
}
