using UnityEngine;
using System.Collections;

public class EdgeDetection : PostEffectsBase {

	// 声明此效果需要的 Shader，并据此创建相应的材质
	public Shader edgeDetectShader;
	private Material edgeDetectionMaterial = null;
	public Material material
	{
		get
		{
			edgeDetectionMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectionMaterial);
			return edgeDetectionMaterial;
		}
	}

	[Range(0.0f, 1.0f)]
	public float edgesOnly = 0.0f;

	public Color edgeColor = Color.black;

	public Color backgroundColor = Color.white;

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if(material != null)
		{
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);

			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
