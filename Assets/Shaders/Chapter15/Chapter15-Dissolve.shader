Shader "Unity Shaders Book/Chapter15/Dissolve"
{
	Properties
	{
		_BurnAmount("Burn Amount", Range(0.0, 1.0)) = 0.0
		_LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)
		_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)
		_BurnMap("Burn Map", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}

		Pass
		{
			Tags {"LightMode"="ForwardBase"}

			Cull Off

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _BurnMap;
			float _BurnAmount;
			float _LineWidth;
			fixed4 _BurnFirstColor;
			fixed4 _BurnSecondColor;

			float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvBurnMap : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)			// 声明阴影坐标
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				TRANSFER_SHADOW(o);		// 计算并向片元着色器传递阴影坐标
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

				clip(burn.r - _BurnAmount);	// 噪声图r分量小于_BurnAmount时会被clip

				float3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));

				fixed3 albedo = tex2D(_MainTex, i.uvMainTex).xyz;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse =  _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));

				// t==0表示像素为正常的模型颜色，0到1之间表示需要模拟烧焦效果
				fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
				fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);	// 混合两种火焰颜色
				burnColor =pow(burnColor, 5);	// 让效果更接近烧焦痕迹

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);	// 计算光照衰减和阴影

				// 混合正常的光照颜色和烧焦颜色
				fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));
				return fixed4(finalColor, 1);

			}

			ENDCG
		}
		// Pass to render object as a shadow caster
		Pass
		{
			Tags {"LightMode"="ShadowCaster"}

			Cull Off

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			
			#include "UnityCG.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				V2F_SHADOW_CASTER;	// 定义阴影投射所需的变量，详见UnityCG.cginc
				float2 uvBurnMap : TEXCOORD1;
			};

			sampler2D _BurnMap;
			float4 _BurnMap_ST;
			float _BurnAmount;
			
			v2f vert (a2v v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);	// 填充V2F_SHADOW_CASTER中声明的变量，详见UnityCG.cginc
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
				clip(burn.r - _BurnAmount);
 				SHADOW_CASTER_FRAGMENT(i)	// 完成阴影投射的部分，把结果输出到深度图和阴影映射纹理中，详见UnityCG.cginc
			}

			ENDCG
		}
	}
	Fallback "Diffuse"
}
