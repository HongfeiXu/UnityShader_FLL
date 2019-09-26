using System.Collections;
using UnityEngine;

/// <summary>
/// 模拟运动模糊效果，通过保存之前的渲染结果，并不断把当前的渲染图像叠加到之前的渲染图像中，
/// 产生一种运动轨迹的视觉效果，比原始的利用“累积缓存”的方法性能更好，但效果可能会略有影响
/// </summary>
public class MotionBlur : PostEffectsBase
{
	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;
	public Material material
	{
		get
		{
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}
	}

	[Range(0.0f, 0.9f)]
	public float blurAmount = 0.5f; // 拖尾效果

	private RenderTexture accumulationTexture;	// 之前图像的叠加结果

	/// <summary>
	/// 脚本不运行时，立即销毁accumulationTexture
	/// </summary>
	private void OnDisable()
	{
		DestroyImmediate(accumulationTexture);
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if(material != null)
		{
			// Create teh accumulationTexture
			if(accumulationTexture == null || 
				accumulationTexture.width != source.width || 
				accumulationTexture.height != source.height)
			{
				DestroyImmediate(accumulationTexture);
				accumulationTexture = new RenderTexture(source.width, source.height, 0);
				accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
				Graphics.Blit(source, accumulationTexture);
			}

			// We are accumulating motion over frames without clear/discard
			// by design, so silence any performance warnings from Unity
			accumulationTexture.MarkRestoreExpected();

			material.SetFloat("_BlurAmount", 1.0f - blurAmount);

			Graphics.Blit(source, accumulationTexture, material);
			Graphics.Blit(accumulationTexture, destination);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
