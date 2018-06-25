using UnityEngine;
using System.Collections;

public class BritnessSaturationAndContrast : PostEffectsBase {

	// 声明此效果需要的 Shader，并据此创建相应的材质
	public Shader briSatConShader;
	private Material briSatConMaterial;
	public Material material
	{
		get
		{
			briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
			return briSatConMaterial;
		}
	}

	[Range(0.0f, 3.0f)]
	public float brightness = 1.0f;

	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;

	[Range(0.0f, 3.0f)]
	public float contrast = 1.0f;

	private void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		if(material != null)
		{
			// 把参数传递给材质
			material.SetFloat("_Brightness", brightness);
			material.SetFloat("_Saturation", saturation);
			material.SetFloat("_Contrast", contrast);

			Graphics.Blit(src, dest, material);
		}
		else
		{
			Graphics.Blit(src, dest);
		}
	}
}
