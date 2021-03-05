// https://blog.csdn.net/liu_if_else/article/details/86316361
Shader "Custom/PolygonsBeta"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		CGINCLUDE
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
		};

		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			return o;
		}
		ENDCG

		Pass
		{
			Stencil
			{
				Ref 0
				ReadMask 255
				Comp always
				Pass IncrWrap
				Fail Keep
				ZFail IncrWrap
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(0,0,0,0);
			}
			ENDCG
		}

		Pass
		{
			Stencil
			{
				Ref 2
				ReadMask 255
				Comp equal
				Pass Keep
				Fail Keep
				ZFail Keep
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(0.2,0.2,0.2,1);
			}
			ENDCG
		}

		Pass
		{
			Stencil
			{
				Ref 3
				ReadMask 255
				Comp equal
				Pass Keep
				Fail Keep
				ZFail Keep
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(0.6,0.6,0.6,1);
			}
			ENDCG
		}
		
		Pass
		{
			Stencil
			{
				Ref 4
				ReadMask 255
				Comp equal
				Pass Keep
				Fail Keep
				ZFail Keep
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(1,1,1,1);
			}
			ENDCG
		}

		//UsePass "Custom/Wireframe/WIREFRAME"
	}
}
