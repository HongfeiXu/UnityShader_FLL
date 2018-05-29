/*
    截取屏幕，存为 Game.png，保存在游戏项目文件夹下。点击此按钮后，需要在选中Game视图，才会生成图片。

    由于此代码需要添加菜单栏条目，因此需要放在 Editor 文件夹下才能正确执行

    Ref: https://docs.unity3d.com/ScriptReference/Application.CaptureScreenshot.html

    Date: 2018.5.24
*/

using UnityEditor;
using UnityEngine;
using System.Collections;

public class ScreenShotMenu : MonoBehaviour
{

    [MenuItem("MyUtility/Capture Screen Shot")]
    static void Capture()
    {
        Application.CaptureScreenshot("Game.png");
        Debug.Log("Capture Screen Shot, finished");
    }
}
