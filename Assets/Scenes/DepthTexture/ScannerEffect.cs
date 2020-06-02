using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// refs: https://zhuanlan.zhihu.com/p/27547127
/// </summary>
public class ScannerEffect : PostEffectsBase 
{
	public Shader scannerEffectShader;
	private Material scannerEffectMat = null;
	public Material material
	{
		get
		{
			scannerEffectMat = CheckShaderAndCreateMaterial(scannerEffectShader, scannerEffectMat);
			return scannerEffectMat;
		}
	}

	private void OnEnable()
	{
		// 想要获取深度纹理
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
	}

	public float velocity = 5;
	private float scanDistance = 0.0f;
	private bool isScanning = false;
	public float scanWidth = 1.0f;
	public Color scanColor = Color.red;


	void Update()
	{
		if (isScanning)
		{
			this.scanDistance += Time.deltaTime * this.velocity;
		}

		//无人深空中按c开启扫描
		if (Input.GetKeyDown(KeyCode.Space))
		{
			this.isScanning = true;
			this.scanDistance = 0;
		}

	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material != null)
		{
			material.SetFloat("_ScanDistance", scanDistance);
			material.SetFloat("_ScanWidth", scanWidth);
			material.SetColor("_ScanColor", scanColor);
			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}

