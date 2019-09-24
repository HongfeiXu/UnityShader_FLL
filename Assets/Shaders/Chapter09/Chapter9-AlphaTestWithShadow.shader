// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	透明度物体的阴影之
	透明度测试
*/

Shader "Unity Shaders Book/Chapter9/Alpha Test With Shadow"
{
	Properties
	{
		_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white"{}
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
	}

	SubShader
	{
		Tags {"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}

		Pass
		{
			Tags {"LightMode" = "ForwardBase"}

			Cull Off

			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			fixed _Cutoff;

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
				SHADOW_COORDS(3)
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				TRANSFER_SHADOW(o);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.pos));

				fixed4 texColor = tex2D(_MainTex, i.uv);

				// Alpha Test
				clip(texColor.a - _Cutoff -0.1);
				// Equal to
				//if (texColor.a - _Cutoff < 0)
				//	discard;

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

				fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldNormal, worldLight)) * albedo;

				// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				return fixed4(ambient + diffuse * atten, 1.0);
			}

			ENDCG
		}
	}
	//Fallback "VertexLit"	// 不正常，因为其内部的 ShadowCaster Pass 中没有进行任何透明度测试
	Fallback "Transparent/Cutout/VertexLit"
}