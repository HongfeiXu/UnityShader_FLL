using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 查看线性空间下的深度纹理、解码后并且被映射到[0, 1]范围内的视角空间下的法线纹理
/// </summary>
public class ShowDepthNormalTex : PostEffectsBase
{
	public Shader showDepthNormalShader;
	private Material showDepthNormalMat = null;
	public Material material
	{
		get
		{
			showDepthNormalMat = CheckShaderAndCreateMaterial(showDepthNormalShader, showDepthNormalMat);
			return showDepthNormalMat;
		}
	}

	private void OnEnable()
	{
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}
	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material != null)
		{
			material.EnableKeyword("SHOW_NORMAL");
			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
