// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*

	渲染纹理之玻璃效果，
	
	1. 使用 GrabPass 来获取玻璃后面的屏幕图像，并使用切线空间下的法线对屏幕纹理坐标进行偏移，最后对屏幕图像采样来模拟近似的光照效果
	2. 使用 Cubemap 来模拟玻璃的反射
	3. 混合反射与折射

*/

Shader "Unity Shaders Book/Chapter10/GlassRefraction" {
	Properties
	{
		_MainTex("Main Tex", 2D) = "white"{}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_CubeMap("Environment Cubemap", Cube) = "_Skybox" {}
		_Distortion("Distortion", Range(0, 100)) = 10
		_RefractAmount("Refract Amount", Range(0.0, 1.0)) = 1.0
	}

	SubShader
	{
		// We must be transparent, so other objects are drawn before this one
		Tags {"Queue" = "Transparent" "RenderType" = "Qpaque"}

		// This pass grabs the screen behind the object into a texture.
		// We can access the result in the next pass as _RefractionTex
		GrabPass {"_RefractionTex"}
		
		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;	// 前三位：存储切线空间到世界空间的变换矩阵的一行；后一位：存储世界空间下顶点的位置
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.scrPos = ComputeGrabScreenPos(o.pos);

				// 使用 o.uv 存储两个纹理坐标
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

			float4 frag(v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

				// Compute the offset in tangent，其中对屏幕图像的采样坐标进行偏移略 Trick，详细见 issue 64

				// 方式一，偏移范围是在[offset/Far, offset/Near]
				//float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				//i.scrPos.xy = offset + i.scrPos.xy;				
				//fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

				// 方式二，偏移范围是在[-offset, offset]
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				// 
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;	
				// 对 scrPos 透视除法得到真正的视口坐标，再使用该坐标对抓取的屏幕图像 _RefractionTex 进行采样，得到模拟的折射颜色
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

				// 方式三
				// 这样offset就不会跟物体距离摄像机的远近有任何关系，永远都是offset的值，这也不能说这样做有什么问题。
				//float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				//fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w + offset).rgb;

				// Convert the normal to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed3 texColor = tex2D(_MainTex, i.uv.xy).rgb;
				// 用反射方向对 Cubemap 进行采样，并把结果与主纹理颜色相乘得到反射颜色
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor;

				// 混合折射颜色与反射颜色
				fixed3 finalCol = lerp(refrCol, reflCol, saturate(1 - _RefractAmount));

				return fixed4(finalCol, 1.0);
			}

			ENDCG
		}

	}
}
