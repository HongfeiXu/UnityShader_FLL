using System.Collections;
using UnityEngine;

/// <summary>
/// 模拟运动模糊效果，通过保存之前的渲染结果，并不断把当前的渲染图像叠加到之前的渲染图像中，
/// 产生一种运动轨迹的视觉效果，比原始的利用“累积缓存”的方法性能更好，但效果可能会略有影响
/// </summary>
public class MotionBlurWithDepthTexture : PostEffectsBase
{
	private Camera aCamera;
	public Camera ACamera
	{
		get
		{
			if(aCamera == null)
			{
				aCamera = GetComponent<Camera>();
			}
			return aCamera;
		}
	}

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

	[Range(0.0f, 1.0f)]
	public float blurSize = 0.5f; // 定义运动模糊时模糊图像使用的大小

	// 存储上一帧摄像机视角*投影矩阵
	private Matrix4x4 previousViewProjectionMatrix;
	// 存储当前帧摄像机视角*投影矩阵
	private Matrix4x4 currentViewProjectionMatrix;
	// 存储当前帧摄像机视角*投影矩阵的逆矩阵
	private Matrix4x4 currentViewProjectionInverseMatrix;

	private void OnEnable()
	{
		// 想要获取深度纹理
		ACamera.depthTextureMode |= DepthTextureMode.Depth;

		previousViewProjectionMatrix = ACamera.projectionMatrix * ACamera.worldToCameraMatrix;
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if(material != null)
		{
			material.SetFloat("_BlurSize", blurSize);

			material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
			currentViewProjectionMatrix = ACamera.projectionMatrix * ACamera.worldToCameraMatrix;
			currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
			material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
			previousViewProjectionMatrix = currentViewProjectionMatrix;

			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
