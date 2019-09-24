// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	只渲染阴影，不渲染物体
*/

Shader "ShadowOnly"
{
	Properties
	{
		_AlphaScale("Alpha Scale", Range(0, 1)) = 0		// 控制整体的透明度
	}

		SubShader
		{
			Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

			Pass
			{
				Tags{ "LightMode" = "ForwardBase" }

				ZWrite Off
				Blend SrcAlpha OneMinusSrcAlpha

				CGPROGRAM

				#pragma multi_compile_fwdbase

				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"
				#include "AutoLight.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				fixed4 _MainTex_ST;
				fixed _AlphaScale;

				struct a2v {
					float4 vertex : POSITION;
					float4 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					SHADOW_COORDS(1)
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

					// Pass shadow coordinates to pixel shader
					TRANSFER_SHADOW(o);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 texColor = tex2D(_MainTex, i.uv);

					fixed shadow = SHADOW_ATTENUATION(1);
					return fixed4(0, 0, 0, texColor.a * _AlphaScale);
				}

				ENDCG
			}
		}
		Fallback "VertexLit"		// dirty trick，强制为半透明物体生成阴影
}