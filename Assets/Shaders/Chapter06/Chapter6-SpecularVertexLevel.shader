/*
	高光反射光照模型之
	逐顶点光照
*/
Shader "Unity Shaders Book/Chapter6/Specular Vertex-Level"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", Range(8.0, 256.0)) = 20
	}
	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 color : COLOR0;
			};

			v2f vert(a2v v)
			{
				v2f o;
				// Transform the vertex from object space to projection space
				o.pos = UnityObjectToClipPos(v.vertex);

				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				// Transform the normal from object space to world space
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				// Get the light direction in world space
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * _Diffuse * saturate(dot(worldNormal, worldLight));
				
				// Get the reflect direction in world space
				fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));
				// Get the view direction in world space
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);

				// Compute specular term
				fixed3 specular = _LightColor0.rgb * _Specular * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

				o.color = ambient + diffuse + specular;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return fixed4(i.color, 1.0);
			}
		
			ENDCG
		}
	}

	Fallback "Specular"
}
