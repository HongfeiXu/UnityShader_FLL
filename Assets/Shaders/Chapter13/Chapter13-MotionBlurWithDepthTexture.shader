Shader "Unity Shaders Book/Chapter13/Motion Blur With Depth Texture"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_BlurSize("Blur Size", Float) = 1.0
	}
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;	// 用来进行平台差异化处理
		sampler2D _CameraDepthTexture;
		float4x4 _CurrentViewProjectionInverseMatrix;
		float4x4 _PreviousViewProjectionMatrix;
		fixed _BlurSize;

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;	// 专门用于对深度纹理进行采样的纹理坐标
		};

		// appdata_img 为 Unity 内置的结构体，在 UnityCG.cginc 中定义
		v2f vert(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			// 采样 _CameraDepthTexture
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// 判断深度是否已被反转
			#if defined(UNITY_REVERSED_Z)
			depth = 1.0 - depth;
			#endif
			// NDC下的坐标
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 - 1, 1);
			// Transform by the view-projection inverse
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			// Divide by w to get the world position
			// http://feepingcreature.github.io/math.html
			float4 worldPos = D / D.w;

			// Current NDC position
			float4 currentPos = H;
			// Previous NDC position
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			previousPos /= previousPos.w;

			// Compute the pixel velocity
			float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;

			// 使用速度值对邻域像素进行采样，然后去平均值得到一个模糊效果，用_BlurSize控制距离
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize;
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize)
			{
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			return fixed4(c.rgb, 1.0);
		}

		ENDCG

		Pass
		{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			ENDCG
		}
		
	}
	Fallback Off
}
