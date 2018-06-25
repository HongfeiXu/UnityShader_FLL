using UnityEngine;
using System.Collections;

public class GaussianBlur : PostEffectsBase
{

	// 声明此效果需要的 Shader，并据此创建相应的材质
	public Shader gaussianBlurShader;
	private Material gaussianBlurMaterial = null;
	public Material material
	{
		get
		{
			gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
			return gaussianBlurMaterial;
		}
	}

	// Blur iterations - larger number means more blur
	[Range(0, 4)]
	public int iterations = 3;

	// Blur spread of each iteration - larger value means more blur
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;

	[Range(1, 8)]
	public int downSample = 2;

	/// 1st edition: just apply blur
	//	void OnRenderImage(RenderTexture src, RenderTexture dest) {
	//		if (material != null) {
	//			int rtW = src.width;
	//			int rtH = src.height;
	//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
	//
	//			// Render the vertical pass
	//			Graphics.Blit(src, buffer, material, 0);
	//			// Render the horizontal pass
	//			Graphics.Blit(buffer, dest, material, 1);
	//
	//			RenderTexture.ReleaseTemporary(buffer);
	//		} else {
	//			Graphics.Blit(src, dest);
	//		}
	//	} 

	/// 2nd edition: scale the render texture
	//	void OnRenderImage (RenderTexture src, RenderTexture dest) {
	//		if (material != null) {
	//			int rtW = src.width/downSample;
	//			int rtH = src.height/downSample;
	//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
	//			buffer.filterMode = FilterMode.Bilinear;
	//
	//			// Render the vertical pass
	//			Graphics.Blit(src, buffer, material, 0);
	//			// Render the horizontal pass
	//			Graphics.Blit(buffer, dest, material, 1);
	//
	//			RenderTexture.ReleaseTemporary(buffer);
	//		} else {
	//			Graphics.Blit(src, dest);
	//		}
	//	}

	/// 3rd edition: use iterations for larger blur
	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if(material != null)
		{
			int rtW = source.width / downSample;
			int rtH = source.height / downSample;
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;

			Graphics.Blit(source, buffer0);

			for(int i = 0; i < iterations; i++)
			{
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 0);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 1);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			// Render to screen
			Graphics.Blit(buffer0, destination);
			RenderTexture.ReleaseTemporary(buffer0);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
