Shader "Custom/Hole" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,0)
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+2"}
        Cull Front
        ZTest Greater
        ColorMask RGB
        ZWrite off
        Stencil {
            Ref 1
            Comp equal
            Pass replace
        }

		Pass
        {
            Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				v2f o;
				// 渲染背面，需要反向一哈法线
				v.normal = -1 * v.normal;
				// Transform the vertex from object space to projection space
				o.pos = UnityObjectToClipPos(v.vertex);
				// Transform the normal from object space to world space
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// Get the normal in world space
				fixed3 worldNormal = normalize(i.worldNormal);
				// Get the light direction in world space
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

				// Compute diffuse term
				fixed halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Color * halfLambert;

				fixed3 color = ambient + diffuse;
				
				return fixed4(color, 1.0);
			}
			ENDCG
        }
    } 
}