using System;
using UnityEngine;
using UnityEngine.Profiling;
using System.Collections.Generic;
using UnityEngine.Rendering;

/// <summary>
/// 轮廓线渲染（游戏中物体的高亮显示）
/// 单例
/// 添加轮廓线：OutlineBlur.Instance.AddTargetRenderer(renderer)
/// 删除轮廓线：OutlineBlur.Instance.RemoveTargetRenderer(renderer)
/// </summary>
[RequireComponent(typeof(Camera))]
public class OutlineBlur : MonoBehaviour
{
	public static OutlineBlur Instance
	{
		get
		{
			return m_Instance;
		}
	}
	private static OutlineBlur m_Instance;

	/// <summary>
	/// 添加要描边的物体（传入该物体的Renderer）
	/// </summary>
	public void AddTargetRenderer(Renderer renderer)
	{
		Debug.Log("AddTargetRenderer::instanceid = " + renderer.GetInstanceID());
		m_TargetsRendererDict[renderer.GetInstanceID()] = renderer;
		SetRenderSolidColorCmdBuf();
	}

	/// <summary>
	/// 移除不需要描边的物体（传入该物体的Renderer）
	/// </summary>
	public void RemoveTargetRenderer(Renderer renderer)
	{
		Debug.Log("RemoveTargetRenderer::instanceid = " + renderer.GetInstanceID());
		m_TargetsRendererDict.Remove(renderer.GetInstanceID());
		SetRenderSolidColorCmdBuf();
	}

	// Step 1. 用单色渲染目标物体到RT1上 
	CommandBuffer m_RenderSolidColorCmdBuf;
	public Shader m_SolidColorShader;
	public List<Renderer> m_TestRenderers;		// 测试
	private Dictionary<int, Renderer> m_TargetsRendererDict = new Dictionary<int, Renderer>();  // instance id -> Renderer
	public Color m_OutlineColor = Color.red;
	private Material m_SolidColorMaterial = null;
	protected Material SolidColorMaterial
	{
		get
		{
			m_SolidColorMaterial = CheckShaderAndCreateMaterial(m_SolidColorShader, m_SolidColorMaterial);
			m_SolidColorMaterial.hideFlags = HideFlags.DontSave;
			return m_SolidColorMaterial;
		}
	}

	// Step 2. 对该RT1进行模糊处理得到RT2 

	/// Blur iterations - larger number means more blur.
	[Range(1, 10)]
	public int m_Iterations = 1;

	/// Blur spread for each iteration. Lower values
	/// give better looking blur, but require more iterations to
	/// get large blurs. Value is usually between 0.5 and 1.0.
	[Range(0.0f, 1.0f)]
	public float m_BlurSpread = 0.4f;

	// 降采样
	[Range(1, 4)]
	public int m_DownSample = 2;

	// 轮廓线强度
	[Range(0, 4)]
	public float m_OutlineStrength = 1.0f;

	// --------------------------------------------------------
	// The blur iteration shader.
	// Basically it just takes 4 texture samples and averages them.
	// By applying it repeatedly and spreading out sample locations
	// we get a Gaussian blur approximation.

	public Shader m_BlurShader = null;
	private Material m_BlurMaterial = null;
	protected Material BlurMaterial
	{
		get
		{
			m_BlurMaterial = CheckShaderAndCreateMaterial(m_BlurShader, m_BlurMaterial);
			m_BlurMaterial.hideFlags = HideFlags.DontSave;
			return m_BlurMaterial;
		}
	}

	// Step 3. 将RT2中与RT1重合的像素抠掉，形成的外轮廓
	public Shader cutoffShader;
	private Material m_CutoffMaterial = null;
	protected Material CutoffMaterial
	{
		get
		{
			m_CutoffMaterial = CheckShaderAndCreateMaterial(cutoffShader, m_CutoffMaterial);
			m_CutoffMaterial.hideFlags = HideFlags.DontSave;
			return m_CutoffMaterial;
		}
	}

	// Step 4. 形成的外轮廓与原始图叠加，最终在原图上绘制出了目标物体的外轮廓（注：可以与 Step3 合并）
	public Shader m_CompositeShader;
	Material m_CompositeMaterial = null;
	protected Material CompositeMaterial
	{
		get
		{
			m_CompositeMaterial = CheckShaderAndCreateMaterial(m_CompositeShader, m_CompositeMaterial);
			m_CompositeMaterial.hideFlags = HideFlags.DontSave;
			return m_CompositeMaterial;
		}
	}

	// Debug, render alpha channel to r channel
	public Shader m_RenderAlphaShader;
	private Material m_RenderAlphaMaterial = null;
	protected Material RenderAlphaMaterial
	{
		get
		{
			m_RenderAlphaMaterial = CheckShaderAndCreateMaterial(m_RenderAlphaShader, m_RenderAlphaMaterial);
			m_RenderAlphaMaterial.hideFlags = HideFlags.DontSave;
			return m_RenderAlphaMaterial;
		}
	}

	// 设置在 Step 1 中渲染的 Renderer

	/// <summary>
	/// 此函数，不通用，因为涉及到自动设置 outlineTargetsRenderer
	/// </summary>
	private void Awake()
	{
		m_Instance = this;
		// 创建一个 CommandBuffer，用来渲染纯色目标物体
		m_RenderSolidColorCmdBuf = new CommandBuffer
		{
			name = "Render Solid Color Target"
		};

		foreach(var item in m_TestRenderers)
		{
			AddTargetRenderer(item);
		}
	}

	// 声明 3 个 RenderTexture，在第一次用到时 GetTemporary，在 Disable 时 ReleaseTemporary。导致 downSample 无法在运行时更改
	RenderTexture m_SolidColorRT = null;
	RenderTexture m_Buffer2 = null;
	RenderTexture m_Buffer3 = null;
	RenderTexture m_Buffer4 = null;
	// Called by the camera to apply the image effect
	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (m_RenderSolidColorCmdBuf != null && SolidColorMaterial && CutoffMaterial && CompositeMaterial)
		{
			int rtW = source.width / m_DownSample;
			int rtH = source.height / m_DownSample;

			// Step 1. Draw Solid Color Target Object(使用 Command Buffer 代替之前的那个附加相机)
			SolidColorMaterial.SetColor("_Color", m_OutlineColor);
			if (m_SolidColorRT == null)
			{
				m_SolidColorRT = RenderTexture.GetTemporary(rtW, rtH, 0);
				m_SolidColorRT.filterMode = FilterMode.Bilinear;
			}
			Graphics.SetRenderTarget(m_SolidColorRT);
			Graphics.ExecuteCommandBuffer(m_RenderSolidColorCmdBuf);

			// Step 2. Copy to buffer2
			if (m_Buffer2 == null)
			{
				m_Buffer2 = RenderTexture.GetTemporary(rtW, rtH, 0);
				m_Buffer2.filterMode = FilterMode.Bilinear;
			}
			Graphics.Blit(m_SolidColorRT, m_Buffer2);

			// Step 3. Blur
			if (m_Buffer3 == null)
			{
				m_Buffer3 = RenderTexture.GetTemporary(rtW, rtH, 0);
				m_Buffer3.filterMode = FilterMode.Bilinear;
			}
			bool oddEven = true;
			for (int i = 0; i < m_Iterations; i++)
			{
				if (oddEven)
					FourTapCone(m_Buffer2, m_Buffer3, i);
				else
					FourTapCone(m_Buffer3, m_Buffer2, i);
				oddEven = !oddEven;
			}
			RenderTexture blurBuffer = null;    // 引用，指向 blur 的结果 buffer
			if (!oddEven)
			{
				blurBuffer = m_Buffer3;
			}
			else
			{
				blurBuffer = m_Buffer2;
			}

			// Step 4. 用 cutoffMaterial 进行 blurBuffer - solidColorRT 操作，得到线框
			CutoffMaterial.SetTexture("_BlurredTex", blurBuffer);
			if (m_Buffer4 == null)
			{
				m_Buffer4 = RenderTexture.GetTemporary(rtW, rtH, 0);
				m_Buffer4.filterMode = FilterMode.Bilinear;
			}
			Graphics.Blit(m_SolidColorRT, m_Buffer4, CutoffMaterial);

			// Step 5.用 compositeMaterial 进行 原图 + 线框操作
			CompositeMaterial.SetTexture("_SrcTex", source);
			CompositeMaterial.SetFloat("_OutlineStrength", m_OutlineStrength);
			Graphics.Blit(m_Buffer4, destination, CompositeMaterial);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}

	private void OnEnable()
	{
		// Disable if we don't support image effects
		if (!SystemInfo.supportsImageEffects)
		{
			enabled = false;
			return;
		}
		// Disable if the shader can't run on the users graphics card
		if (!BlurMaterial)
		{
			enabled = false;
			return;
		}
		if (!CutoffMaterial)
		{
			enabled = false;
			return;
		}
		if (!CompositeMaterial)
		{
			enabled = false;
			return;
		}

		// 设置 Command Buffer
		SetRenderSolidColorCmdBuf();
	}

	private void SetRenderSolidColorCmdBuf()
	{
		if (m_RenderSolidColorCmdBuf == null)
			return;
		m_RenderSolidColorCmdBuf.Clear();
		// 顺序将渲染任务加入 renderCmdBuf 中
		Color clearColor = Color.black;
		m_RenderSolidColorCmdBuf.ClearRenderTarget(true, true, clearColor);

		foreach (KeyValuePair<int, Renderer> kvp in m_TargetsRendererDict)
		{
			m_RenderSolidColorCmdBuf.DrawRenderer(kvp.Value, SolidColorMaterial);
		}
	}

	private void OnDisable()
	{
		CleanMaterial();

		CleanRenderRenderTexture();

		if (m_RenderSolidColorCmdBuf != null)
			m_RenderSolidColorCmdBuf.Clear();
	}

	private void CleanMaterial()
	{
		if (m_BlurMaterial)
		{
			DestroyImmediate(m_BlurMaterial);
		}
		if (m_CutoffMaterial)
		{
			DestroyImmediate(m_CutoffMaterial);
		}
		if (m_CompositeMaterial)
		{
			DestroyImmediate(m_CompositeMaterial);
		}
		if (m_RenderAlphaMaterial)
		{
			DestroyImmediate(m_RenderAlphaMaterial);
		}
	}

	private void CleanRenderRenderTexture()
	{
		if (m_SolidColorRT)
		{
			RenderTexture.ReleaseTemporary(m_SolidColorRT);
		}
		if (m_Buffer2)
		{
			RenderTexture.ReleaseTemporary(m_Buffer2);
		}
		if (m_Buffer3)
		{
			RenderTexture.ReleaseTemporary(m_Buffer3);
		}
		if (m_Buffer4)
		{
			RenderTexture.ReleaseTemporary(m_Buffer4);
		}
	}

	// Call when need to create the material used by this effect
	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
	{
		if (shader == null)
			return null;
		if (shader.isSupported && material && material.shader == shader)
			return material;
		else
		{
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
			else
				return null;
		}
	}

	// Performs one blur iteration.
	private void FourTapCone(RenderTexture source, RenderTexture dest, int iteration)
	{
		float off = 0.5f + iteration * m_BlurSpread;
		Graphics.BlitMultiTap(source, dest, BlurMaterial,
							   new Vector2(-off, -off),
							   new Vector2(-off, off),
							   new Vector2(off, off),
							   new Vector2(off, -off)
			);
	}

	// Downsamples the texture to a quarter resolution.
	//private void DownSample4x(RenderTexture source, RenderTexture dest)
	//{
	//	float off = 1.0f;
	//	Graphics.BlitMultiTap(source, dest, blurMaterial,
	//						   new Vector2(-off, -off),
	//						   new Vector2(-off, off),
	//						   new Vector2(off, off),
	//						   new Vector2(off, -off)
	//		);
	//}
}