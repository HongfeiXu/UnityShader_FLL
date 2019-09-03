// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
	假彩色图像的方式可视化模型的法线
*/
Shader "Unity Shaders Book/Chapter5/Simple Shader v1" {
	Properties{
		// 声明一个 Color 类型的属性
		_Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader{
		Pass{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			// 在 Cg 代码中，为了使用Properties中声明的_Color属性，我们需要定义一个与_Color名称和类型都匹配的变量
			fixed4 _Color;

			// 用一个结构体来定义顶点着色器的输入
			// a2v: application to vertex shader
			struct a2v {
				// POSITION 语义告诉 Unity，用模型空间的顶点坐标填充 vertex 变量
				float4 vertex : POSITION;
				// NORMAL 语义告诉 Unity，用模型空间的法线方向填充 normal 变量
				float3 normal : NORMAL;
				// TEXCOORD0 语义告诉 Unity，用模型的第一套纹理坐标填充 texcoord 变量
				float4 texcoord : TEXCOORD0;
			};

			// 用一个结构体来定义顶点着色器的输出
			// v2f: vertex shader to fragment shader
			struct v2f{
				// SV_POSITION 语义告诉 Unity，pos 里面包含了顶点在裁剪空间中的位置信息
				float4 pos : SV_POSITION;
				// COLOR0 语义可以用来存储颜色信息
				fixed3 color : COLOR0;
			};
			
			v2f vert(a2v v){
				// 声明输出结构
				v2f o;
				
				// 模型空间->裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);

				// v.normal 包含了顶点的法线方向，其分量范围在[-1.0, 1.0]
				// 下面的代码把分量范围映射到了[0.0, 1.0]
				// 存储到 o.color 中传递给片元着色器
				o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed3 c = i.color;
				// 使用 _Color 属性来控制输出颜色
				c *= _Color.rgb;
				return fixed4(c, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}
