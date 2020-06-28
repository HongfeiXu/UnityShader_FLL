Shader "Custom/ForceField"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_IntersectPower("IntersectPower", Range(0, 3)) = 2
		_RimStrength("RimStrength",Range(0, 10)) = 2
		_NoiseTex("NoiseTexture", 2D) = "white" {}
		_DistortStrength("DistortStrength", Range(0,1)) = 0.2
		_DistortTimeFactor("DistortTimeFactor", Range(0,1)) = 0.2
		_DistortVisible("DistortVisible", Range(0,1)) = 1
	}
	SubShader
	{
		ZWrite Off	// 透明物体
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off	// 关闭背面剔除

		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

		// This pass grabs the screen behind the object into a texture.
		// We can access the result in the next pass as _GrabTempTex
		GrabPass {"_GrabTempTex"}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float4 _Color;
			float _IntersectPower;
			float _RimStrength;
			float _DistortStrength;
			float _DistortTimeFactor;
			float _DistortVisible;

			sampler2D _GrabTempTex;
			float4 _GrabTempTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			sampler2D _CameraDepthTexture;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float4 grabPos : TEXCOORD3;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);			// 屏幕坐标值（带w分量，详细见CompteScreenPos函数）

				// _CameraDepthTexture中只保存了场景中不透明物体的深度信息，
				// 因此这个时候无法从CameraDepthTexture中获取能量场的深度信息，所以要在vert中计算顶点的深度

				o.screenPos.z = -UnityObjectToViewPos(v.vertex).z;	// 计算当前物体的深度值（观察空间下，顶点到摄像机的距离）
				//COMPUTE_EYEDEPTH(o.screenPos.z);					// 与上式等效

				o.normal = UnityObjectToWorldNormal(v.normal);		// 世界空间下的法线
				
				o.viewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));	// 世界空间下的观察向量

				o.grabPos = ComputeGrabScreenPos(o.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(i.viewDir);

				// 相交效果
				// 由于此时不是Post Process，因此需要利用投影纹理采样来访问深度图
				float screenZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));	// 与下面两个语句效果相同

				//float2 wcoord = i.screenPos.xy / i.screenPos.w;	 // 屏幕坐标访问深度纹理
				//float screenZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, wcoord));	// 此前绘制的深度值

				float diff = abs(screenZ - i.screenPos.z);			// 当前物体与之前绘制结果的深度差异，1-diff就得到相交程度
				float intersect = (1 - diff) * _IntersectPower;

				// 边缘效果
				float rim = 1 - abs(dot(normal, viewDir)) * _RimStrength;

				float glow = max(intersect, rim);

				// 扭曲效果
				float4 offset = tex2D(_NoiseTex, i.uv - _Time.xy * _DistortTimeFactor);
				i.grabPos.xy -= offset.xy * _DistortStrength;
				fixed4 grabColor = tex2D(_GrabTempTex, i.grabPos.xy / i.grabPos.w) * _DistortVisible;

				fixed4 col = _Color * glow + grabColor;
				return col;
			}
			ENDCG
		}
	}
}
