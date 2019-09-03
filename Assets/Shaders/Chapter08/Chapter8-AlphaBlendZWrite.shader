// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	开启深度写入的透明度混合
	逐片元着色
	漫反射+纹理

	使用两个 Pass 来渲染模型：
	第一个 Pass 开启深度写入，但不输出颜色，它的目的是为了把该模型的深度值写入深度缓冲中
	第二个 Pass 进行正常的透明度混合，由于上一个 Pass 中
*/

Shader "Unity Shaders Book/Chapter8/Alpha Blend ZWrite"
{
	Properties
	{
		_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white"{}
		_AlphaScale("Alpha Scale", Range(0, 1)) = 1		// 控制整体的透明度
	}

	SubShader
	{
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

		// Extra pass that renders to depth buffer only
		Pass
		{
			// 开启深度写入
			ZWrite On
			// 设置颜色通道的写掩码（write mask）
			ColorMask 0
		}

		Pass
		{
			Tags {"LightMode" = "ForwardBase"}

			// 关闭深度写入
			ZWrite Off
			// 开启并设置此Pass的混合模式

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			fixed _AlphaScale;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos :TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.pos));

				fixed4 texColor = tex2D(_MainTex, i.uv);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

				fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldNormal, worldLight)) * albedo;

				return fixed4(ambient + diffuse, texColor.a * _AlphaScale);	// 设置透明通道（只有在开启混合模式后才有效）
			}

			ENDCG
		}
	}
	Fallback "Transparent/VertexLit"
}