Shader "Custom/OverlapWithShell"
{
	// 相比Overlap加了一点描边的效果，利用到
	// 目标面向我们的面的法线和我们观察方向的夹角相对较小，而边缘部分的面的法线和我们的观察方向的夹角显然更大

	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_EdgeColor("Edge Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			ZTest Greater	// 深度大于当前深度值，通过测试，显示纯色

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float4 _EdgeColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;

				float3 normal : NORMAL;
				float3 viewDir : TEXCOORD1;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.normal = UnityObjectToWorldNormal(v.normal);
				//o.viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
				o.viewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));	// 与上式等价
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(i.viewDir);
				// 根据观察方向和目标多边形的法线方向的夹角来判断目标的边缘——毕竟目标面向我们的面的法线和我们观察方向的夹角相对较小，
				// 而边缘部分的面的法线和我们的观察方向的夹角显然更大——这里的边缘判断用到了观察方向，
				float rim = 1 - dot(normal, viewDir) * 1.5;
				fixed4 col = _EdgeColor * rim;
				return col;
			}
			ENDCG
		}

		Pass
		{
			ZTest Less		// 深度小于当前深度值，通过测试，显示贴图颜色

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
