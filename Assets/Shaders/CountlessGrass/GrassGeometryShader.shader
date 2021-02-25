Shader "Custom/Grass" {
	Properties{
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_AlphaTex("Alpha (A)", 2D) = "white" {}
		_Height("Grass Height", float) = 3
		_Width("Grass Width", range(0, 0.1)) = 0.05
		_LodDistanceNear("LOD Distance Near",float) = 5		// 设置的比较小为了能方便看到效果哈
		_LodDistanceFar("LOD Distance Far ",float) = 10
		[HDR]_ExtraColor("Color",Color) = (1, 1, 1, 1)
	}
	SubShader{
		Cull off
		
		Tags{ "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True" }

		Pass
		{
			Cull OFF
			Tags{ "LightMode" = "ForwardBase" }
			AlphaToMask On

			CGPROGRAM

			#include "UnityCG.cginc" 
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#include "UnityLightingCommon.cginc" // 用来处理光照的一些效果

			#pragma target 4.0

			sampler2D _MainTex;
			sampler2D _AlphaTex;

			float _Height;	//草的高度
			float _Width;	//草的宽度（的一半）
			float _LodDistanceNear;
			float _LodDistanceFar;
			float4 _ExtraColor;

			struct v2g
			{
				float4 pos : SV_POSITION;
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
			};

			v2g vert(appdata_full v)
			{
				v2g o;
				o.pos = v.vertex;
				o.norm = v.normal;
				o.uv = v.texcoord;
				return o;
			}

			g2f createGSOut() {
				g2f output;
				output.pos = float4(0, 0, 0, 0);
				output.norm = float3(0, 0, 0);
				output.uv= float2(0, 0);

				return output;
			}

			// 通过一个根节点来创建顶点模拟叶子，30个顶点，10个三角形
			[maxvertexcount(30)]
			void geom(point v2g points[1], inout TriangleStream<g2f> triStream)	// 顶点输入，三角面片输出
			{
				float4 root = points[0].pos;

				// 计算草根到相机的距离
				//float distToCamera = length(_WorldSpaceCameraPos.xyz - mul(_Object2World, root.xyz));

				float3 viewPos = UnityObjectToViewPos(root.xyz);
				float distToCamera = abs(viewPos.z);

				// 构造旋转矩阵，让草不要都朝着一个方向
				float randomAngle = frac(sin(root.x)*10000.0) * UNITY_HALF_PI;
				float4x4 T1 = float4x4(
					1.0, 0.0, 0.0, -root.x,
					0.0, 1.0, 0.0, -root.y,
					0.0, 0.0, 1.0, -root.z,
					0.0, 0.0, 0.0, 1.0
				);
                float4x4 R = float4x4(
					cos(randomAngle), 0, sin(randomAngle),0,
					0, 1, 0, 0,
					-sin(randomAngle), 0, cos(randomAngle),0,
					0, 0, 0, 1
				);
                float4x4 T2 = float4x4(
					1.0, 0.0, 0.0, root.x,
					0.0, 1.0, 0.0, root.y,
					0.0, 0.0, 1.0, root.z,
					0.0, 0.0, 0.0, 1.0
				);
				float4x4 transform = mul(T2, mul(R, T1));

				// 坐标决定这个random的数值
				float random = sin(UNITY_HALF_PI * frac(root.x) + UNITY_HALF_PI * frac(root.z));	

				// 草宽度、高度
				float width = _Width + (random / 50);
				float height = _Height + (random / 5);

				// 顶点数据初始化，最多用到12个顶点
				g2f v[12] = {
					createGSOut(), createGSOut(), createGSOut(), createGSOut(),
					createGSOut(), createGSOut(), createGSOut(), createGSOut(),
					createGSOut(), createGSOut(), createGSOut(), createGSOut()
				};
				int vertexCount;	// LOD确定实际用到多少个顶点
				if(distToCamera > _LodDistanceFar)
					vertexCount = 4;
				else if(distToCamera > _LodDistanceNear)
					vertexCount = 8;
				else
					vertexCount = 12;

				//处理纹理坐标
				float currentV = 0;
				float offsetV = 1.f /(((uint)vertexCount / 2) - 1);

				//处理当前的高度
				float currentHeightOffset = 0;
				float currentVertexHeight = 0;

				//风的影响系数
				float windCoEff = 0;

				for (int i = 0; i < vertexCount; i++)
				{
					v[i].norm = float3(0, 0, 1);

					// 计算顶点的坐标、纹理坐标
					if (fmod(i , 2) == 0)
					{ 
						v[i].pos = float4(root.x - width , root.y + currentVertexHeight, root.z, 1);
						v[i].uv = float2(0, currentV);
					}
					else
					{ 
						v[i].pos = float4(root.x + width , root.y + currentVertexHeight, root.z, 1);
						v[i].uv = float2(1, currentV);

						currentV += offsetV;
						currentVertexHeight = currentV * height;
					}

					// 让草旋转一哈
					v[i].pos = mul(transform, v[i].pos);

					// 让草不要全部竖直冲着天
					float bendingStrength = 1.0f;
					float2 randomDir = float2(sin(random * 15), sin(random * 10));
					v[i].pos.xz += bendingStrength * randomDir * windCoEff * windCoEff;

					// 起风了
					float2 wind = float2(sin(_Time.x * UNITY_PI * 5), sin(_Time.x * UNITY_PI * 5));
					wind.x += (sin(_Time.x + root.x / 25) + sin((_Time.x + root.x / 15) + 50)) * 0.5;
					wind.y += cos(_Time.x + root.z / 80);
					wind *= lerp(0.7, 1.0, 1.0 - random);

					const float oscillateDelta = 0.05;
					const float oscillationStrength = 2.5f;	// 摆动强度
					float sinSkewCoeff = random;			// 歪斜系数
					float lerpCoeff = (sin(oscillationStrength * _Time.x + sinSkewCoeff) + 1.0) / 2;
					float2 leftWindBound = wind * (1.0 - oscillateDelta);
					float2 rightWindBound = wind * (1.0 + oscillateDelta);
					wind = lerp(leftWindBound, rightWindBound, lerpCoeff);

					float randomAngle = lerp(-UNITY_PI, UNITY_PI, random);
					float randomMagnitude = lerp(0, 1., random);
					float2 randomWindDir = float2(sin(randomAngle), cos(randomAngle));
					wind += randomWindDir * randomMagnitude;	// 风向加点随机变化

					float windForce = length(wind);
					v[i].pos.xz += wind.xy * windCoEff;			// 计算顶点被风吹后的坐标（草的长度不严格保持哈。。。）
					v[i].pos.y -= windForce * windCoEff * 0.8;

					v[i].pos = UnityObjectToClipPos(v[i].pos);

					// 距离叶子顶端越近，风的影响就越大
					if (fmod(i, 2) == 1) {
						windCoEff += offsetV;
					}
				}

				// 用 vertexCount 个顶点构 vertexCount-2 个三角形
				for (int p = 0; p < (vertexCount - 2); p++) {
					triStream.Append(v[p]);
					triStream.Append(v[p + 2]);
					triStream.Append(v[p + 1]);
				}
			}

			half4 frag(g2f IN) : COLOR
			{
				fixed4 color = tex2D(_MainTex, IN.uv);		// 颜色
				fixed4 alpha = tex2D(_AlphaTex, IN.uv);		// 轮廓

				half3 worldNormal = UnityObjectToWorldNormal(IN.norm);

				//ads
				fixed3 light;

				//ambient
				fixed3 ambient = ShadeSH9(half4(worldNormal, 1));

				//diffuse
				fixed3 diffuseLight = saturate(dot(worldNormal, UnityWorldSpaceLightDir(IN.pos))) * _LightColor0;

				//specular Blinn-Phong 
				fixed3 halfVector = normalize(UnityWorldSpaceLightDir(IN.pos) + WorldSpaceViewDir(IN.pos));
				fixed3 specularLight = pow(saturate(dot(worldNormal, halfVector)), 15) * _LightColor0;

				light = ambient + diffuseLight + specularLight;

				return half4(color.rgb * light * _ExtraColor, alpha.g);
			}
			ENDCG
		}
	}
}