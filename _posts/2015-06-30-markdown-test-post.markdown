---
layout: post
title:  "测试markdown语法和元素表现风格"
date:   2015-06-30 12:00:00
author: fadeer
categories: 工作
tags: jekyll markdown todo
---

这是一个测试帖，用来调试常见帖子元素的风格。

段落，文字效果
----
从WIM的诞生就可以看出，这主要是简化Windows的部署。我们回顾一下XP时代的Windows安装源，核心目录是光盘下的`i386`目录，里面一>堆`XX_`结尾的文件，本质上是也是个压缩文件（要不光盘空间怎么够），安装过程主要就是把`XX_`文件解压成`XXX`文件（比如`SY_`解压为`SYS`）放置到Windows目标路径下，这也太直白了。关键是文件太散碎了，坏一个不坑了。利用WIM文件，**安装过程就相当于解压>一个压缩文件**，速度能快很多，然后做下引导，完成了；后面的硬件兼容性由Windows运行起来自己搞定。

另外，前面提到了WIM支持单一文件存储，同时支持多索引，就是你可以**把多个Windows版本保存到一个安装介质里**（典型就是DVD光>盘，受4.7G容量限制），因为不同版本（比如标准版、企业版、数据中心版什么的，在加上多语言）的源文件绝大多数是相同的，所以整合到一起可以极大的节省空间，方便多版本测试，在安装过程中多一步来选择某一个要安装的版本。微软的MSDN下载往往提供这种源，开发者也可以利用后面的WIM工具自己制作多合一安装源。其实这事儿在XP时代也有，利用光盘格式的特性，把相同的文件只储存一份。当>初虽然没自己手动做过，但是体验过这好处啊。

前面提到的这个Windows安装源是光盘`Source\install.wim`，你会发现这目录下还有个`boot.img`，就用到了WIM另一个特性，**支持启动**。或者说，是**Windows Loader支持从WIM这个压缩文件上启动系统**（咦，这事儿在Linux下很熟悉），光盘启动电脑，进入的图形安装环境的系统（WinPE，预安装环境）就是从`boot.img`启动来的。这个环境下用`diskpart`可以看到一个X盘，就是`boot.img`的内容（Windows、Program Files都有啊，就是一精简的Windows），一般定制WinPE环境也就是修改`boot.img`的内容。

常见的语法高亮
----
**Linux Bash**：

~~~ bash
#只读方式挂载squashfs文件，只读是强制的，不加-r会多个警告而已
mkdir ubuntu-core
sudo mount -t squashfs -r -o loop ubuntu-core.squashfs /tmp/fadeer/ubuntu-core/

#创建可写文件系统目录，递归方式链接所有文件，根据文件数量需要些时间
mkdir system-rw
cp -rs /tmp/fadeer/ubuntu-core/* system-rw

#看看效果，system-rw下所有目录都是实体，所有文件都是指向ubuntu-core的连接
/tmp/fadeer$ ls ubuntu-core
bin  etc  home  lib  lib64  opt  sbin  sys  usr  var
/tmp/fadeer$ ls system-rw/
bin  etc  home  lib  lib64  opt  sbin  sys  usr  var
/tmp/fadeer$ ll system-rw/bin/ | tail -3
lrwxrwxrwx  1 ys ys   33 Aug  6 17:04 zless -> /tmp/fadeer/ubuntu-core/bin/zless*
lrwxrwxrwx  1 ys ys   33 Aug  6 17:04 zmore -> /tmp/fadeer/ubuntu-core/bin/zmore*
lrwxrwxrwx  1 ys ys   32 Aug  6 17:04 znew -> /tmp/fadeer/ubuntu-core/bin/znew*
~~~

**Windows 批处理**，包含滚动:

~~~ powershell
Dism /Export-Image /SourceImageFile:c:\customImages\win8pro.wim /SourceIndex:1 /DestinationImageFile:c:\customImages\allinone.wim /DestinationName:"Windows 8 Professional"
Dism /Export-Image /SourceImageFile:c:\customImages\win8ent.wim /SourceIndex:1 /DestinationImageFile:c:\customImages\allinone.wim /DestinationName:"Windows 8 Enterprise"
Dism /Export-Image /SourceImageFile:c:\customImages\win81.wim /SourceIndex:1 /DestinationImageFile:c:\customImages\allinone.wim /DestinationName:"Windows 8.1"

::然后看看最终的效果吧：
Dism /Get-ImageInfo /imagefile:C:\customImages\allinone.wim
~~~

<!--preview-end-->
**Javascript**，不包含行号：

~~~ javascript
function start(){
	num1++;
	document.title = num1;
}
document.addEventListener("mousedown",function(){
	this.addEventListener("mousemove",start,false);
},false);
document.addEventListener("mouseup",function(){
	this.removeEventListener("mousemove",start,false);
});
~~~

也可以在文字间加代码，比如`/etc/network/interfaces`这样。

列表、引用
----
一个标准Linux的部署，系统部分通常分为三块儿：

* 内核文件，一般在启动分区下`vmlinuz-{kernel.version}`；对比Windows的内核是`C:\Windows\System32\ntoskrnl.exe`。
* 内存盘（Ramdisk）被引导文件加载起来的精简系统，通常也是压缩格式的，这文件一般叫`initrd.gz-{kernel.version}`，意思就是init（初始化时用的）、rd（内存盘）、gz（压缩的）。
* 系统分区，一般是一个完整的分区，EXT4之类格式的，放置完整的Linux系统组件。

这种把正文内容和引用的原始链接分开的方式不错，[参考1][链接1]和[参考2][链接2]，这样编辑markdown正文时，就不会被过长的[链接3]打断了。

> Add option `keep_fargs`.
>
> By default it's `false`.  Pass `true` if you need to keep unused function arguments.
>
> Close #188.
>
> master (#1)  v2.4.24 … v2.4.13
>
> mishoo authored on 8 Feb 2014

注意引文的换行也得单独引用。

> I added a compressor option for it. To keep unused function arguments, pass keep_fargs: true to the compressor, for example:
>
> `uglifyjs file.js -m -c keep-fargs=true`
>
> I still believe that relying on this “feature” is silly, so it's disabled by default.


富媒体内容
----
引用一张图片，是这样的：

![][pic1]

图片来源: https://iso.500px.com/
{: .source}

原始很大的图片，在高分辨率屏下效果应该不错；如果图片宽度不够，也要填满宽度，虽然会显得模糊：

![](http://7xkxri.com1.z0.glb.clouddn.com/fix_bug.png)

图片来源: [Sina App Engine官方微博](http://www.weibo.com/saet)
{: .source}

参考链接
----
* [Jekyll](http://jekyllrb.com/)
* [Github Pages](https://pages.github.com/)
* [Using Jekyll with Pages](https://help.github.com/articles/using-jekyll-with-pages/)
* [Material Design Iconic Font by Sergey Kupletsky](http://zavoloklom.github.io/material-design-iconic-font/index.html)
* [Pygments syntax highlighter](http://pygments.org/)
* [Rouge a pure-ruby syntax highlighter](https://github.com/jneen/rouge)
* [Kramdown Syntax](http://kramdown.gettalong.org/syntax.html)

<!-- 文内引用链接，不会直接出现在正文里 -->
[链接1]:	http://www.google.com
[链接2]:	http://www.google.com
[链接3]:	http://www.google.com

[pic1]: http://7xkxri.com1.z0.glb.clouddn.com/test-1.jpg
[pic2]: http://7xkxri.com1.z0.glb.clouddn.com/test-2.jpg


