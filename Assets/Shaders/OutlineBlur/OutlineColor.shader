Shader "OutlineBlur/Outline Color"
{
	Properties{
		_Color("Outline Color", Color) = (1, 1, 1, 1)
	}

	SubShader {

		ZTest Always Cull Off ZWrite Off

		Pass { 
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			fixed4 _Color;
			
			struct v2f {
				float4 pos : SV_POSITION;
			};

			
			v2f vert(float4 v : POSITION)
			{
				v2f o;
				// Transform the vertex from object space to projection space
				o.pos = UnityObjectToClipPos(v);
				return o;
			}
			
			fixed4 frag() : SV_Target {
				// outline color
				return fixed4(_Color.rgb, 1);
			}
			
			ENDCG
		}
	} 
	Fallback off
}