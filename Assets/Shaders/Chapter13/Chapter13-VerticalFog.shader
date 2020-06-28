Shader "Unity Shaders Book/Chapter13/Fog With Depth Texture"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_FogDensity("Fog Density", Float) = 1.0
		_FogColor("Fog Color", Color) = (1,1,1,1)
		_FogStart("Fog Start", Float) = 0.0
		_FogEnd("Fog End", Float) = 1.0
	}
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"

		float4x4 _FrustumCornersRay;

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;	// 用来进行平台差异化处理
		sampler2D _CameraDepthTexture;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;	// 专门用于对深度纹理进行采样的纹理坐标
			float4 interpolatedRay : TEXCOORD2;
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

			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
			{
				index = 0;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5)
			{
				index = 1;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5)
			{
				index = 2;
			}
			else
			{
				index = 3;
			}

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif

			o.interpolatedRay = _FrustumCornersRay[index];

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			// 采样 _CameraDepthTexture
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

			float linearDepth = LinearEyeDepth(depth);
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
			fogDensity = saturate(fogDensity * _FogDensity);

			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			return finalColor;
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
