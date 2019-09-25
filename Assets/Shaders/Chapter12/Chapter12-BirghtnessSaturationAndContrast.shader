Shader "Unity Shaders Book/Chapter12/Birghtness Saturation And Contrast"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
//		_Brightness("Brightness", Float) = 1
//		_Saturation("Saturation", Float) = 1
//		_Contrast("Contrast", Float) = 1
	}
	SubShader
	{
		Pass
		{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half _Brightness;
			half _Saturation;
			half _Contrast;

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			// appdata_img 为 Unity 内置的结构体，在 UnityCG.cginc 中定义
			v2f vert (appdata_img v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture，这里是对原屏幕图像的采样结果
				fixed4 renderTex = tex2D(_MainTex, i.uv);
				
				// Apply brightness
				fixed3 finalColor = renderTex.rgb * _Brightness;

				// Apply saturation
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				finalColor = lerp(luminanceColor, finalColor, _Saturation);

				// Apply contrast
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);

				return fixed4(finalColor, renderTex.a);
			}
			ENDCG
		}
	}

	Fallback Off
}
