/*
    利用 Unity 提供的 Camera.RenderToCubemap 函数来实现，根据物体在场景中的位置不同，生成它们各自不同的立方体纹理。
    Camera.RenderToCubemap 函数可以把从任意位置观察到的场景图像存储到 6 张图像中，从而创建出该位置上对应的立方体纹理。

    由于此代码需要添加菜单栏条目，因此需要放在 Editor 文件夹下才能正确执行

    Ref: https://docs.unity3d.com/ScriptReference/Camera.RenderToCubemap.html

    Date: 2018.5.24
*/

using UnityEngine;
using UnityEditor;
using System.Collections;

public class RenderCubemapWizard : ScriptableWizard
{
    public Transform renderFromPosition;
    public Cubemap cubemap;

    void OnWizardUpdate()
    {
        //string helpString = "Select transform to render from and cubemap to render into";
        //bool isValid = (renderFromPosition != null) && (cubemap != null);
    }

    void OnWizardCreate()
    {
        // create temporary camera for rendering
        GameObject go = new GameObject("CubemapCamera");
        go.AddComponent<Camera>();
        // place it on the object
        go.transform.position = renderFromPosition.position;
        go.transform.rotation = Quaternion.identity;
        // render into cubemap
        go.GetComponent<Camera>().RenderToCubemap(cubemap);

        // destroy temporary camera
        DestroyImmediate(go);
    }

    [MenuItem("MyUtility/Render into Cubemap")]
    static void RenderCubemap()
    {
        ScriptableWizard.DisplayWizard<RenderCubemapWizard>(
            "Render cubemap", "Render!");
    }
}