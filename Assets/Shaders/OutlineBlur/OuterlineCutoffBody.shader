Shader "OutlineBlur/CutoffBody" {
	Properties {
		_MainTex("Main Tex", 2D) = "white" {}
		_BlurredTex ("Blurred Tex", 2D) = "white" {}
	}	

	CGINCLUDE

	sampler2D _MainTex;
	sampler2D _BlurredTex;
	sampler2D _SrcTex;
	half _OutlineStrength;

	struct a2v
	{
		float4 vertex : POSITION;
		float4 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	v2f vert(a2v v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		fixed4 c0 = tex2D(_MainTex, i.uv);
		fixed4 c1 = tex2D(_BlurredTex, i.uv);
		return c1 - c0;
	}
	ENDCG
	
	Subshader {
		Pass {
			ZTest Always Cull Off ZWrite Off Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 
			ENDCG
		}
	}
	FallBack off
}