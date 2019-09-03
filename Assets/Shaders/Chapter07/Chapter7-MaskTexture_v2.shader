// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	遮罩纹理之
	高光反射遮罩纹理
	（在切线空间下计算光照）
*/
Shader "Unity Shaders Book/Chapter7/Mask Texture v2"
{
	Properties
	{
		_Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)	// 控制整体色调
		_MainTex("Main Tex", 2D) = "white"{}				// 纹理
		_BumpMap("Normal Map", 2D) = "bump"{}				// 法线纹理
		_BumpScale("Bump Scale", Float) = 1.0
		_SpecularMask("Specular Mask", 2D) = "white"{}		// 高光反射遮罩纹理
		_SpecularScale("Specular Scale", Float) = 1.0		// 控制遮罩影响度
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", Range(8.0, 256.0)) = 20
	}
	SubShader
	{
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float _BumpScale;		// 控制凹凸程度，0的时候表示法线纹理不对光照产生作用
			sampler2D _SpecularMask;
			float _SpecularScale;
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
				float2 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				// 使用 o.uv 存储主纹理、法线纹理、遮罩纹理的纹理坐标
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 lightDir = normalize(i.lightDir);
				fixed3 viewDir = normalize(i.viewDir);

				// Get the normal in tangent space (mark the texture as "Normal map")
				 fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv.xy));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				// Use the texture to sample the diffuse color
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, lightDir));

				fixed3 halfDir = normalize(viewDir + lightDir);
				// Get the mask value
				fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
				// Compute specular term with the specular mask
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss) * specularMask;
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
		
			ENDCG
		}
	}

	Fallback "Specular"
}
