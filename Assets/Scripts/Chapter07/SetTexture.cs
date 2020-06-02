using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetTexture : MonoBehaviour {

	public Renderer m_Renderer;
	public Texture m_MainTexture;

	// Use this for initialization
	void Start () {
		StartCoroutine(SetTextureFunc());
	}

	IEnumerator SetTextureFunc()
	{
		// wait for 1 second
		yield return new WaitForSeconds(1.0f);
		m_Renderer.material.SetTexture("_MainTex", m_MainTexture);
	}

	// Update is called once per frame
	void Update () {
		
	}
}
