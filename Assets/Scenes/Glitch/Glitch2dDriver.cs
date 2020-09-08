using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Glitch2dDriver : MonoBehaviour {

	// Scan line jitter
	[SerializeField, Range(0, 1)]
	float _scanLineJitter = 0;
	public float scanLineJitter
	{
		get { return _scanLineJitter; }
		set { _scanLineJitter = value; }
	}

	// Vertical jump
	[SerializeField, Range(0, 1)]
	float _verticalJump = 0;
	public float verticalJump
	{
		get { return _verticalJump; }
		set { _verticalJump = value; }
	}

	// Horizontal shake
	[SerializeField, Range(0, 1)]
	float _horizontalShake = 0;
	public float horizontalShake
	{
		get { return _horizontalShake; }
		set { _horizontalShake = value; }
	}

	// Color drift
	[SerializeField, Range(0, 1)]
	float _colorDrift = 0;
	public float colorDrift
	{
		get { return _colorDrift; }
		set { _colorDrift = value; }
	}

	Material _material;
	float _verticalJumpTime;


	// Use this for initialization
	void Start () {
		_material = GetComponent<MeshRenderer>().material;
	}
	
	// Update is called once per frame
	void Update () {
		if (!_material)
			return;

		_verticalJumpTime += Time.deltaTime * _verticalJump * 11.3f;

		var sl_thresh = Mathf.Clamp01(1.0f - _scanLineJitter * 1.2f);
		var sl_disp = 0.002f + Mathf.Pow(_scanLineJitter, 3) * 0.05f;
		_material.SetVector("_ScanLineJitter", new Vector2(sl_disp, sl_thresh));

		var vj = new Vector2(_verticalJump, _verticalJumpTime);
		_material.SetVector("_VerticalJump", vj);

		_material.SetFloat("_HorizontalShake", _horizontalShake * 0.2f);

		var cd = new Vector2(_colorDrift * 0.04f, Time.time * 606.11f);
		_material.SetVector("_ColorDrift", cd);
	}
}
