/*
	Blinn-Phong 光照模型，使用Unity内置函数
*/
Shader "Unity Shaders Book/Chapter6/Blinn-Phong Use Build-in Function"
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

			#include "UnityCG.cginc"
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
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o;
				// Transform the vertex from object space to projection space
				o.pos = UnityObjectToClipPos(v.vertex);

				// Use the build-in function to compute the normal in world space
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				// Transform teh normal from object space to world space
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 worldNormal = normalize(i.worldNormal);
				// Use the build-in function to compute the light direction in world space
				// Remember to normalize the result
				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));

				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * _Diffuse * saturate(dot(worldNormal, worldLight));
				
				// Use the build-in function to compute the view direction in world space
				// Remember to normalize the result
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				// Get the half direction in world space
				fixed3 halfDir = normalize(worldLight + viewDir);
			
				// Compute specular term
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, worldNormal)), _Gloss);

				return fixed4(ambient + diffuse + specular, 1.0);
			}
		
			ENDCG
		}
	}

	Fallback "Specular"
}
