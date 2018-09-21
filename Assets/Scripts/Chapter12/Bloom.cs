using UnityEngine;
using System.Collections;

public class Bloom : PostEffectsBase
{
	public Shader bloomShader;
	private Material bloomMaterial = null;
	public Material material
	{
		get
		{
			bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
			return bloomMaterial;
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

	[Range(0.0f, 4.0f)]
	public float luminanceThreshold = 0.6f;

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if(material != null)
		{
			material.SetFloat("_LuminanceThreshold", luminanceThreshold);

			int rtW = source.width / downSample;
			int rtH = source.height / downSample;

			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;

			// 获取亮部
			Graphics.Blit(source, buffer0, material, 0);

			// 对亮部进行 Gaussian Blur
			for (int i = 0; i < iterations; i++)
			{
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 1);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 2);

				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 2);

				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			// 合并亮部图到原图
			material.SetTexture("_Bloom", buffer0);
			Graphics.Blit(source, destination, material, 3);

			RenderTexture.ReleaseTemporary(buffer0);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
