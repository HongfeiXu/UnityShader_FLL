/*
 
 截屏，开始运行游戏的时候调用 Capture 函数，截取屏幕，存为 Game.png，保存在游戏项目文件夹下。

 改进：运行时，添加按钮在屏幕上，点击按钮时，进行 Capture 操作。
 
 */

using UnityEngine;
using System.Collections;

public class ScreenShot : MonoBehaviour {

	// Use this for initialization
	void Start () {
        Capture();
	}
	
	// Update is called once per frame
	void Update () {
	
	}

    void Capture()
    {
        Application.CaptureScreenshot("Game.png");
        Debug.Log("Capture Screen Shot, finished");
    }
}
