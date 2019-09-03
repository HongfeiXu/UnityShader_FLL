Shader "OutlineBlur/Composite" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}							// Blit 传入的轮廓图片
		_SrcTex ("Src Tex", 2D) = "white" {}							// 原始场景图片
		_OutlineStrength("Outline Strength", Float) = 1.0
	}

	Subshader {
		Pass {
			ZTest Always Cull Off ZWrite Off Fog { Mode Off }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _SrcTex;
			half _OutlineStrength;

			struct v2f {
				float4 pos : POSITION;
				half2 uv : TEXCOORD0;
			};

			v2f vert (appdata_img v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv = v.texcoord.xy;
				return o;
			}


			fixed4 frag( v2f i ) : SV_Target
			{
				fixed4 c0 = tex2D( _MainTex, i.uv );
				fixed4 c1 = tex2D( _SrcTex, i.uv );
				return c0 * _OutlineStrength + c1;
			}
			ENDCG
		}
	}
	Fallback off
}
