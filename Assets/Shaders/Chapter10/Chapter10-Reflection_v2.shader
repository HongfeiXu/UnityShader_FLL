// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*

基于 Chapter10-Reflection.shader，不同之处在于把 worldViewDir 和 worldRefl 的计算放在了片元着色器中，使得效果更佳细腻。
但考虑到性能的消耗换区这种很小的提升，一般还是在顶点着色器中进行计算。

*/

Shader "Unity Shaders Book/Chapter10/Reflection_v2" {
	Properties {
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_ReflectColor("Reflection Color", Color) = (1, 1, 1, 1)
		_ReflectAmount("Reflection Amount", Range(0, 1)) = 1
		_Cubemap("Reflection Cubemap", Cube) = "_Skybox" {}
	}
	SubShader{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }

		Pass{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			float4 _Color;
			float4 _ReflectColor;
			fixed _ReflectAmount;
			samplerCUBE _Cubemap;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				SHADOW_COORDS(4)
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				TRANSFER_SHADOW(o);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				fixed3 worldRefl = reflect(-worldViewDir, worldNormal);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormal, worldLightDir));

				// Use the reflect dir in world space to access the cubemap
				fixed3 reflection = texCUBE(_Cubemap, worldRefl).rgb * _ReflectColor.rgb;

				// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;

				return fixed4(color, 1.0);
			}

			ENDCG
			
		}
	}
	FallBack "Reflective/VertexLit"
}
