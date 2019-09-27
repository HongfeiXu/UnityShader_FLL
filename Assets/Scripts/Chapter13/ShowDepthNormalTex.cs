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
		// 想要获取深度纹理
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
		// 想要获取深度+法线纹理
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}

	public bool showDepthOrNormal = true;

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material != null)
		{
			// Unset all keywords
			foreach (var key in material.shaderKeywords)
			{
				material.DisableKeyword(key);
			}
			// Set keywords
			if (showDepthOrNormal)
			{
				material.EnableKeyword("SHOW_DEPTH");
			}
			else
			{
				material.EnableKeyword("SHOW_NORMAL");
			}

			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
