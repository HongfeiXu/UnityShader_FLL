Shader "ImageEffect/ImageGridShow"
{
	Properties
	{
		_MainTex ("-", 2D) = "" {}

		_ColorMask("Color Mask", Float) = 15
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	struct appdata_t
	{
		float4 vertex : POSITION;
		fixed4 color : COLOR;
		float4 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
		fixed4 color : COLOR;
		float4 texcoord : TEXCOORD0;
	};
	ENDCG

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;

			float _InitTime;
			float _FillTime;
			float _Tansition;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
			#if !defined(UNITY_COLORSPACE_GAMMA) && (UNITY_VERSION >= 550)
				o.color.rgb = GammaToLinearSpace(v.color.rgb);
				o.color.a = v.color.a;
			#else
				o.color = v.color;
			#endif

				return o;
			}

			fixed4 mix(fixed4 src, fixed4 dst, half process)
			{
				return (1 - process) * src + process * dst;
			}

			float random (float2 uv)
            {
                return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
            }

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = i.texcoord.xy;

				float progress = sin(_Time.y);
				int columnNum = 20;
				int rowNum = 20;
				int currRow = floor(uv.y * rowNum);	// 行号
				int currColumn = floor(uv.x * columnNum);	// 列号
				float columnPercent = currColumn * 1.0 / columnNum;

				float rand = random(float2(currRow, currColumn));	// 行号列号决定随机值

				// 显示概率由时间百分比、列号百分比控制
				float probability = rand * 0.5 + progress + (1 - columnPercent);
				// alpha变化服从如下变化
				float alphaTrans = 1;
				if(progress < 0.4)
				{
					alphaTrans = 1 - progress + 0.2;
				}
				else
				{
					alphaTrans = sqrt(progress);
				}
				
				fixed4 resultColor = tex2D(_MainTex, i.texcoord.xy);
				resultColor.a *= step(0.9, probability) * alphaTrans;

				
				return resultColor;
			}
			ENDCG
		}
	}
}