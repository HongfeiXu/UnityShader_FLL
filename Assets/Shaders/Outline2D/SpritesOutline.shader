// 获取2D图片的描边

Shader "Sprites/SpritesOutline"
{
    Properties
    {
        _MainTex ("-", 2D) = "" {}
        _EdgeColor("Edge Color", Color) = (1,1,0,1)
        _Thickness("Thickness", float) = 1
    }
    SubShader
    {
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}

        Pass
        {
            Cull Off
            Lighting Off
            ZWrite Off
            Fog{ Mode Off }
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half4 _MainTex_TexelSize;	
            fixed4 _EdgeColor;
            float _Thickness;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv[9] : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                half2 uv = v.uv;
				o.uv[0] = uv + _Thickness * _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _Thickness * _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _Thickness * _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _Thickness * _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _Thickness * _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _Thickness * _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _Thickness * _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _Thickness * _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _Thickness * _MainTex_TexelSize.xy * half2(1, 1);

                return o;
            }

            half Sobel(v2f i)
			{
				const half Gx[9] = { -1, 0, 1,
					-2, 0, 2,
					-1, 0, 1 };
				const half Gy[9] = { -1, -2, -1,
					0, 0, 0,
					1, 2, 1 };

				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++)
				{
					texColor = tex2D(_MainTex, i.uv[it]).a;
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}

				half edge = abs(edgeX) + abs(edgeY);
				return edge;
			}

            fixed4 frag (v2f i) : SV_Target
            {
                half edge = Sobel(i);
                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), 1 - edge);
                return withEdgeColor;
            }
            ENDCG
        }
    }
}
