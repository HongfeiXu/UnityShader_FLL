Shader "Custom/ScannerEffect"
{
	Properties{
		_MainTex("Texture", 2D) = "white" {}
	}

	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"	

		float _BlurSize;
		float _ScanWidth;
		float _ScanDistance;
		fixed4 _ScanColor;

		sampler2D _CameraDepthTexture;
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;	// 用来进行平台差异化处理

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			float4 col = tex2D(_MainTex, i.uv);

			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
			float linearDepth = Linear01Depth(depth);

			if (linearDepth < _ScanDistance && linearDepth > _ScanDistance - _ScanWidth && linearDepth < 1)
			{
				//float diff = (linearDepth - (_ScanDistance - _ScanWidth)) / _ScanWidth;
				float diff = 1 - (_ScanDistance - linearDepth) / (_ScanWidth);	// 与上式等价，越接近_ScanDistance距离的扫描线颜色越接近_ScanColor
				_ScanColor *= diff;
				return col + _ScanColor;
			}
			return col;
		}

		ENDCG

		Pass {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
		Fallback Off
}
