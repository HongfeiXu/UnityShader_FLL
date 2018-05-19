/*
	在Unity Shader中实现漫反射光照模型之
	逐顶点光照
*/
Shader "Unity Shaders Book/Chapter6/Diffuse Vertex-Level" {
	Properties{
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
	}
	SubShader{
		Pass{
			Tags{ "LightMode" = "ForwardBase" }
		
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 color : COLOR0;
			};

			v2f vert(a2v v)
			{
				v2f o;
				// Transform the vertex from object space to projection space
				//o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);

				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
			//	fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Diffuse.rgb;	// 也可以这样计算 ambient, 与书中不同，可以参考 issue129

				// Transform the normal from object space to world space
				//fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				// Get the light direction in world space
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

				o.color = ambient + diffuse;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return fixed4(i.color, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}
