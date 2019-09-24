// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unity Shaders Book/Chapter11/Billboard"
{
	Properties
	{
		_MainTex ("Main Tex", 2D) = "white" {}
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding("Vertical Restraints", Range(0, 1)) = 1	// 用于调整是固定法线还是固定指向上的方向，及约束垂直方向的程度
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True" }

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		//Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
		};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _VerticalBillboarding;
			
			v2f vert (a2v v)
			{
				v2f o;

				// 在模型空间计算，以模型空间原点作为广告牌锚点
				float3 center = float3(0, 0, 0);
				// 模型空间下的视角位置
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				// 计算目标法线方向
				float3 normalDir = viewer - center;
				// If _VerticalBillboarding == 1, we use the desired view dir as the normal dir
				// Or if _VerticalBillboarding == 0, the y of normal is 0
				normalDir.y = normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);
				// Get the approximate up dir
				float3 upDir = abs(normalDir.y > 0.999) ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(normalDir, upDir));
				upDir = normalize(cross(rightDir, normalDir));
				// 原始的位置相对于锚点的偏移量
				float3 centerOffs = v.vertex.xyz - center;
				// 计算新顶点的位置
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y - normalDir * centerOffs.z;

				o.pos = UnityObjectToClipPos(float4(localPos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 c = tex2D(_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				return c;
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
