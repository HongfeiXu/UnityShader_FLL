Shader "Unity Shaders Book/Chapter13/Show Depth"
{
	SubShader
	{
		Pass{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

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

			fixed4 frag(v2f i) : SV_Target
			{
				// 采样 _CameraDepthTexture
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				// 查看线性空间下的深度纹理
				float linearDepth = Linear01Depth(depth);
				return fixed4(linearDepth, linearDepth, linearDepth, 1.0);

				// 采样 _CameraDepthNormalsTexture
				//float depth = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv).zw);
				//return fixed4(depth, depth, depth, 1.0);
			}

			ENDCG
		}
	}
	Fallback Off
}
