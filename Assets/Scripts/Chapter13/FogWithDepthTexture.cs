using System.Collections;
using UnityEngine;

public class FogWithDepthTexture : PostEffectsBase
{
	private Camera aCamera;
	public Camera ACamera
	{
		get
		{
			if (aCamera == null)
			{
				aCamera = GetComponent<Camera>();
			}
			return aCamera;
		}
	}

	private Transform myCameraTransform;
	public Transform cameraTransform
	{
		get
		{
			if(myCameraTransform == null)
			{
				myCameraTransform = ACamera.transform;
			}
			return myCameraTransform;
		}
	}

	public Shader fogShader;
	private Material fogMaterial = null;
	public Material material
	{
		get
		{
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}
	}

	[Range(0.0f, 3.0f)]
	public float fogDensity = 1.0f;

	public Color fogColor = Color.white;

	public float fogStart = 0.0f;
	public float fogEnd = 2.0f;

	private void OnEnable()
	{
		// 想要获取深度纹理
		ACamera.depthTextureMode |= DepthTextureMode.Depth;
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if(material != null)
		{
			// 存储近裁剪平面的四个角对应的向量
			Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fov = ACamera.fieldOfView;
			float aspect = ACamera.aspect;
			float near = ACamera.nearClipPlane;

			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toTop = cameraTransform.up * halfHeight;
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;

			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			Vector3 topRight = cameraTransform.forward * near + toTop + toRight;
			Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
			Vector3 bottomRight = cameraTransform.forward * near - toTop + toRight;

			float scale = topLeft.magnitude / near;

			topLeft.Normalize();
			topRight.Normalize();
			bottomLeft.Normalize();
			bottomRight.Normalize();

			topLeft *= scale;
			topRight *= scale;
			bottomLeft *= scale;
			bottomRight *= scale;

			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

			material.SetMatrix("_FrustumCornersRay", frustumCorners);

			material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogStart", fogStart);
			material.SetFloat("_FogEnd", fogEnd);

			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
