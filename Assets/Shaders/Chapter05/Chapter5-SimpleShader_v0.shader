// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter5/Simple Shader v0" {
	SubShader {
		Pass{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// POSITION 语义告诉 Unity，把模型的顶点坐标填充到输入参数 v 中
			// SV_POSITION 语义告诉 Unity，顶点着色器的输出是裁剪空间中的顶点坐标
			float4 vert(float4 v : POSITION) : SV_POSITION {
				return UnityObjectToClipPos(v);
			}

			// SV_Target 语义告诉 Unity，把用户的输出颜色存储到一个渲染目标中，这里将输出到默认的帧缓存中
			fixed4 frag() : SV_Target {
				return fixed4(1.0, 1.0, 1.0, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}
