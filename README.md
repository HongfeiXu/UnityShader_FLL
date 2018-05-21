# UnityShaderBeginner
读《Unity Shader 入门精要》

## 基础篇

### 第 1 章 欢迎来到 Shader 的世界

### 第 2 章 渲染流水线

### 第 3 章 Unity Shader 基础

### 第 4 章 学习 Shader 所需的数学基础

## 初级篇

### 第 5 章 开始 Unity Shader 学习之旅

**用假颜色对Unity Shader进行调试，并且使用颜色拾取器来查看调试信息**

![](Images/FalseColor+ColorPicker.png)

> Chapter5-FalseColor.shader <br>
> ColorPicker.cs

### 第 6 章 Unity 中的基础光照

**逐顶点漫反射光照、逐像素漫反射光照、半兰伯特光照的对比效果**

![](Images/Diffuse.png)

> Chapter6-DiffuseVertexLevel.shader <br>
> Chapter6-DiffusePixelLevel.shader <br>
> Chapter6-HalfLambert.shader


**逐顶点的高光反射光照、逐像素的高光反射光照（Phong光照模型）和Blinn-Phong高光反射光照的对比结果**

![](Images/Diffuse+Specular.png)

> Chapter6-SpecularVertexLevel.shader <br>
> Chapter6-SpecularPixelLevel.shader <br>
> Chapter6-BlinnPhong.shader <br>
> Chapter6-BlinnPhongUseBuildInFunction.shader（与上面的相同效果）

### 第 7 章 基础纹理

#### 7.1 单张纹理

**用一张纹理来替代物体的漫反射颜色，使用 Blinn-Phong光照模型计算光照。**



![](Images/SingleTexture.png)

> Chapter7-SingleTexture.shader <br>
> Scene_7_1.unity



**纹理的属性：Tilling & Offset，Wrap Mode，Mipmap，Filter Mode，等。**

![](Images/WrapMode.png)

<center>Wrap Mode决定了当纹理坐标超过[0, 1]范围后将会如何被平铺  </center>



![](Images/WrapMode_2.png)

<center>偏移属性决定了纹理坐标的偏移量</center>



![](Images/FilterMode.png)

<center>在放大纹理是，分别使用3种Filter Mode得到的结果</center>



![](Images/FilterMode_2.png)

<center>FilterMode+mipmapping</center>



> Chapter7-TextureProperties.shader <br>
> Scene_7_1_2_a.unity <br>
> Scene_7_1_2_b.unity <br>
> Scene_7_1_2_c.unity

#### 7.2 凹凸映射

凹凸映射主要可以通过两种方式来实现：高度纹理，法线纹理。

法线纹理中存储的法线方向在哪个坐标空间中？可以是：模型空间的法线纹理，切线空间的法线纹理。

需要在计算光照模型中统一各个方向矢量所在的坐标空间。可以是：切线空间下的光照计算，世界空间下的光照计算。

**使用 Bump Scale 属性来调整模型的凹凸程度**

![](Images/NormalMap.png)

>Chapter7-NormalMapTangentSpace.shader

#### 7.3 渐变纹理 

**使用渐变纹理控制物体的漫反射光照**

![](Images/RampTexture.png)

```c++
// 漫反射颜色的计算（使用半兰伯特模型计算的值构建纹理坐标对渐变纹理进行采样）
fixed halfLambert = dot(worldNormal, lightDir) * 0.5 + 0.5;
fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;
fixed3 diffuse = _LightColor0.rgb * diffuseColor;
```

> Chapter7-RampTexture.shader

有个疑问，计算 ambient 时，需不需要乘上 diffuseColor。因为 **7.1 单张纹理** 中有 `fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; `。很疑惑。。。（已经在I[ssue224](https://github.com/candycat1992/Unity_Shaders_Book/issues/224)中提问并解答。）

这两种都不是物理精确的，我个人感觉完全按自己喜好选择就好。哈哈。

![](Images/RampTextureIssue.png)

#### 7.4 遮罩纹理

使用高光遮罩纹理，逐像素地控制模型表面的高光反射强度。

![](Images/MaskTexture.png)

![](Images/MaskTextureSettings.png)



**小Tips**：主纹理、法线纹理和遮罩纹理共同使用一个纹理属性变量 `_Main_Tex_ST`，这样，在材质面板中修改主纹理的平铺和偏移系数会同时影响3个纹理的采样（起到同步的作用），并且可以节省存储的纹理目标数。

> Chapter7-MaskTexture.shader <br>
> Chapter7-MaskTexture_v2.shader

注：可以在这个[链接](http://www.dota2.com/workshop/requirements/)找到《DOTA2》的制作资料。可以看到遮罩纹理的使用。

### 第 8 章 透明效果

#### 8.1 为什么渲染顺序很重要

透明混合技术中，需要关闭深度写入。这会破坏深度缓冲的工作机制。**那么为什么要这样做呢？**

> Ref: https://github.com/candycat1992/Unity_Shaders_Book/issues/22

![](Images/ZWrite.png)

如果你打开了zwrite，透明和透明物体之间就会出现问题。试想两个透明物体A和B，A在前B在后，那么必须是B先渲染A后渲染才会得到正确的结果。但问题是，你无法保证所有的透明物体之间都由完全正确的排序关系，**如果A和B互相遮挡**，那么无论谁先绘制都会发现有一部分是只有一个物体的颜色，而没有发生混合。

当前的半透明解决方法是保证在不透明物体后面、并按从前往后顺序、关闭zwrite，这种方法当然也不是万能的，例如上面说到的A和B互相遮挡下也会出现问题，但出现的错误是“混合错误”，而不是“完全没有进行混合”。**而且关闭了zwrite可以保证一定不会妨碍不透明物体的渲染**，这是非常重要的，即便游戏引擎没有保证先绘制不透明物体，半透明也不会影响游戏里不透明物体的渲染。我认为这是优先级最高的需求。

#### 8.2 Unity Shader 的渲染顺序

#### 8.3 透明度测试

![](Images/AlphaTest.png)

> Chapter8-AlphaTest.shader

#### 8.4 透明度混合

![](Images/AlphaBlend.png)

> Chapter8-AlphaBlend.shader

#### 8.5 开启深度写入的半透明效果

![](Images/AlphaBlendZWrite.png)

> Chapter8-ALphaBlendZWrite.shader

#### 8.6 ShaderLab 的混合命令

> 图片出处：http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_images.html

![](Images/blend.png)

> Chapter8-BlendOperations 0.shader<br>
> Chapter8-BlendOperations 1.shader

#### 8.7 双面渲染的透明效果

**透明度测试的双面渲染**

![](Images/AlphaTestBothSided.png)

> Chapter8-AlphaTestBothSided.shader

**透明度混合的双面渲染**

![](Images/AlphaBlendBothSided.png)

> Chapter8-AlphaBlendBothSided.shader

#### 疑问

如何对复杂模型（非凸网格等）进行双面透明渲染？

在书的第8.7节给出了一个透明度混合的双面渲染的实现，方法是在关闭深度写入的前提下，用两个Pass来分别渲染模型的背面和正面。
上面这种方法可以很好地解决那些模型本身没有遮挡关系的情况。可是一旦模型出现了遮挡，比如书中的Knot模型，依然是会出现混合错误的问题，而且这里显然不能通过进行提前深度测试的方式来解决，因为那样的话，一定是渲染不出背面的（实验结果如下图）。不知道有没有好的解决方法？

![](Images/KnotBothSided.png)





