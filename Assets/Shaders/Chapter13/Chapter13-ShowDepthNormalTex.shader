Shader "Unity Shaders Book/Chapter13/Show Depth Or Normal"
{
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"	

		sampler2D _CameraDepthTexture;
		sampler2D _CameraDepthNormalsTexture;

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

		// 查看线性空间下的深度纹理
		fixed4 showDepthFrag(v2f i) : SV_Target
		{
			// 采样 _CameraDepthTexture
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
			float linearDepth = Linear01Depth(depth);
			return fixed4(linearDepth, linearDepth, linearDepth, 1.0);

			// 采样 _CameraDepthNormalsTexture
			//float depth = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv).zw);
			//return fixed4(depth, depth, depth, 1.0);
		}

		// 查看解码后并且被映射到[0, 1]范围内的视角空间下的法线纹理
		fixed4 showNormalFrag(v2f i) : SV_Target
		{
			fixed3 normal = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, i.uv));
			return fixed4(normal * 0.5 + 0.5, 1.0);
		}

		ENDCG

		Pass{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma multi_compile SHOW_DEPTH SHOW_NORMAL

			fixed4 frag(v2f i) : SV_Target
			{
#ifdef SHOW_DEPTH
				return showDepthFrag(i);
#else
				return showNormalFrag(i);
#endif
			}

			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}
	Fallback Off
}
