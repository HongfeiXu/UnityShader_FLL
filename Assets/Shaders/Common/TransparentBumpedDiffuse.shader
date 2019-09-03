// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	本书使用的标准 Unity Shader 之 Transparent Bumped Diffuse
	多光源 + 光照衰减 + 法线纹理（不支持阴影的投射和接收）
	基于 Phong 光照模型，且不包含 Specular 分量

	注：多光源不支持逐顶点和SH光源（即渲染模式被设置为Not Important的光源）
	若要支持逐顶点和SH光源，则需要参考 Chapter9-ForwardRendering_v2.shader 中 Base Pass 中的代码来修改这个 Bass Pass
*/
Shader "Unity Shaders Book/Common/Transparent Bumped Diffuse"
{
	Properties
	{
		_Color("Base (RGB) Trans(A)", Color) = (1, 1, 1, 1)	// 控制整体色调以及透明度
		_MainTex("Main Tex", 2D) = "white"{}				// 纹理
		_BumpMap("Normal Map", 2D) = "bump"{}				// 法线纹理
		_BumpScale("Bump Scale", Float) = 1.0
	}
	SubShader
	{
		Tags {"RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True"}

		// Base Pass
		// Pass for ambient light & first pixel light (directional light)
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			// Apparently need to add this declaration
			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"	// 为了接收阴影

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;		// 控制凹凸程度，0的时候表示法线纹理不对光照产生作用
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;	// 前三位：存储切线空间到世界空间的变换矩阵的一行；后一位：存储世界空间下顶点的位置
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				// 使用 o.uv 存储主纹理、法线纹理的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				float3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
				float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				// Compute the matrix that transform directions from tangent space to world Space
				// Put the world position in w component for optimization
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));

				// Get the normal in tangent space (mark the texture as "Normal map")
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				// Transform the normal from tangent space to world space
				tangentNormal = normalize(half3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal), dot(i.TtoW2.xyz, tangentNormal)));
				
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, lightDir));
				
				// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

				return fixed4(ambient + diffuse * atten, texColor.a * _Color.a);
			}
		
			ENDCG
		}

		// Additional Pass
		// Pass for other pixel lights
		// 平行光、点光源、聚光灯
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }

			ZWrite Off
			// 开启和设置了混合模式
			Blend One One

			CGPROGRAM

			// Apparently need to add this declaration
			#pragma multi_compile_fwdadd

			// Use the line below to add shadows for point and spot lights
			//#pragma multi_compile_fwdadd_fullshadows

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"	// 为了接收阴影

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;		// 控制凹凸程度，0的时候表示法线纹理不对光照产生作用
			
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;	// 前三位：存储切线空间到世界空间的变换矩阵的一行；后一位：存储世界空间下顶点的位置
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				// 使用 o.uv 存储主纹理、法线纹理的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				float3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
				float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				// Compute the matrix that transform directions from tangent space to world Space
				// Put the world position in w component for optimization
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));

				// Get the normal in tangent space (mark the texture as "Normal map")
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				// Transform the normal from tangent space to world space
				tangentNormal = normalize(half3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal), dot(i.TtoW2.xyz, tangentNormal)));
				
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, lightDir));
				
				// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

				return fixed4(diffuse * atten, texColor.a * _Color.a);
			}
		
			ENDCG
		}
	}

	Fallback "Legacy Shaders/Transparent/Diffuse"
}
