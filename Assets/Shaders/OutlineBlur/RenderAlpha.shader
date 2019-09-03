Shader "OutlineBlur/RenderAlpha" {
	Properties {
		_MainTex("", 2D) = "white" {}
	}
	
	CGINCLUDE
	#include "UnityCG.cginc"
	struct v2f {
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
	};
	
	sampler2D _MainTex;
	half4 _MainTex_TexelSize;
	half4 _MainTex_ST;
	
	v2f vert( appdata_img v ) {
		v2f o; 
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy; // hack, see BlurEffect.cs for the reason for this. let's make a new blur effect soon
		return o;
	}
	
	half4 frag(v2f i) : SV_Target {
		half4 color = half4(tex2D(_MainTex, i.uv).a,0,0,0);
		return color;
	}
	ENDCG

	SubShader {
		 Pass {
			  ZTest Always Cull Off ZWrite Off

			  CGPROGRAM
			  #pragma vertex vert
			  #pragma fragment frag
			  #pragma fragmentoption ARB_precision_hint_fastest 
			  ENDCG
		  }
	}
	Fallback off
}
