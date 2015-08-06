---
layout: post
title:  "Windows的WIM文件格式"
date:   2015-08-05 12:00:00
author: fadeer
categories: 工作
tags: Windows WIM
---

WIM文件格式
----
WIM，全称是Windows Imaging File Format、Windows镜像文件格式，是微软创造出来用于Vista系统部署的文件格式，当然，其后的Windows也都是使用这个来存放Windows安装源的。WIM是一个以文件为基础的格式，作为对比，之前讨论的VHD、我们常见的ISO等都是以扇区块为基础的。同时WIM还支持压缩和单一文件存储，大致上，你可以把WIM文件当作一个文件目录压缩包。WIM内部文件结构是这样：

![](https://i-technet.sec.s-msft.com/dynimg/IC292021.gif)

更详细的见[WIM格式SPEC][wimspec]，这格式从2007年就没变过呢？

WIM的特点和用途
----
从WIM的诞生就可以看出，这主要是简化Windows的部署。我们回顾一下XP时代的Windows安装源，核心目录是光盘下的i386目录，里面一堆`XX_`结尾的文件，本质上是也是个压缩文件（要不光盘空间怎么够），安装过程主要就是把`XX_`文件解压成`XXX`文件（比如`SY_`解压为`SYS`）放置到Windows目标路径下，这也太直白了。关键是文件太散碎了，坏一个不坑了。利用WIM文件，**安装过程就相当于解压一个压缩文件**，速度能快很多，然后做下引导，完成了；后面的硬件兼容性由Windows运行起来自己搞定。

另外，前面提到了WIM支持单一文件存储，同时支持多索引，就是你可以**把多个Windows版本保存到一个安装介质里**（典型就是DVD光盘，受4.7G容量限制），因为不同版本（比如标准版、企业版、数据中心版什么的，在加上多语言）的源文件绝大多数是相同的，所以整合到一起可以极大的节省空间，方便多版本测试，在安装过程中多一步来选择某一个要安装的版本。微软的MSDN下载往往提供这种源，开发者也可以利用后面的WIM工具自己制作多合一安装源。其实这事儿在XP时代也有，利用光盘格式的特性，把相同的文件只储存一份。当初虽然没自己手动做过，但是体验过这好处啊。

前面提到的这个Windows安装源是光盘Source\install.wim，你会发现这目录下还有个boot.img，就用到了WIM另一个特性，**支持启动**。或者说，是Windows Loader支持从WIM这个压缩文件上启动系统（咦，这事儿在Linux下很熟悉），光盘启动电脑，进入的图形安装环境的系统（WinPE，预安装环境）就是从boot.img启动来的。这个环境下用diskpart可以看到一个X盘，就是boot.img的内容（Windows、Program Files都有啊，就是一精简的Windows），一般定制WinPE环境也就是修改boot.img的内容。

WIM相关工具和日常操作
----
<!--preview-end-->
操作和使用WIM文件，通常会遇到两个工具：

* **ImageX**，出现在Vista时代，主要功能是抓取和释放WIM镜像，WinPE里装系统就靠这个了。ImageX工具包含在WAIK（Windows Automated Installation Kit）里，用户完成一个Windows自定义版本之后，就可以用imageX抓取出一个自定义wim安装镜像，再由安装盘或者自动部署工具批量安装就好了。
* **DIMS**（Deployment Image Servicing and Management），出现在Windows 7时代，主要完成WIM文件的离线维护工作，比如增删Windows更新、附加语言包等。显然WIM光靠抓取不能改实在不方便。这时期，WIM的部署工作还是得由ImageX来完成。但是到了Windows 8，DISM也包含了WIM的抓取与释放功能，并且随着Windows更新，不断附加新的特性。因此后续**我们对WIM文件的操作也都通过DISM**来进行。而前面的WAIK也升级为了WADK（Windows Assessment and Deployment Kit），DISM工具也是包含在这个套件里。

接下来我们看看WIM的日常操作和使用场景

**WIM文件的挂载与修改保存**，这一般是放进去里面几个绿色软件什么的。
{% highlight bat %}
::挂载WIM文件，这一步需要点儿时间，似乎在建立索引，别着急。
Dism /Mount-Image /ImageFile:C:\images\install.wim /index:1 /MountDir:C:\imageMount ::如果你光想看看，也可以加上只读参数/ReadOnly

::看看镜像内容，跟Windows系统分区一样一样的。
C:\>dir c:\imageMount
 Volume in drive C has no label.
 Volume Serial Number is BE5F-31B8

 Directory of c:\imageMount

03/18/2014  03:38 AM    <DIR>          .
03/18/2014  03:38 AM    <DIR>          ..
08/22/2013  08:22 AM    <DIR>          PerfLogs
03/18/2014  02:43 AM    <DIR>          Program Files
08/22/2013  08:36 AM    <DIR>          Program Files (x86)
03/18/2014  03:26 AM    <DIR>          Users
03/18/2014  03:26 AM    <DIR>          Windows
               0 File(s)              0 bytes
               7 Dir(s)  39,253,848,064 bytes free

::往里拷点儿软件
xcopy C:/greenSoftware C:\imageMount /s /i

::这时新增的文件还都在暂存区，你需要提交到WIM文件里
Dism /Commit-Image /MountDir:C:\imageMount

::把更新保存到WIM文件里并且卸载WIM文件
Dism /Unmount-Image /MountDir:C:\imageMount /commit
::如果你不想保存，把/commit换成/discard 
{% endhighlight %}

对于Windows镜像的修改，另外一个正经用途是**离线打补丁**。比如把Windows 8.1更新为Windows 8.1 Update，或者是把远程管理工具RSAT补充进去。

Windows升级文件一般是一个`.msu`文件，不能直接往WIM里打，需要先把里面的`.cab`文件解压出来。
{% highlight bat %}
windows8.1-kb2919442-x64.msu /extract ::获得一个同名的cab文件windows8.1-kb2919442-x64.cab
{% endhighlight %}

然后再往WIM的Windows释放：
{% highlight bat %}
Dism /mount-image /imagefile:c:\images\install.wim /index:1 /mountdir:c:\imageMount

::添加补丁包
Dism /add-package /packagepath:c:\msu\windows8.1-kb2919442-x64.cab /image:c:\imageMount /logpath:dism.log

::优化镜像内容
Dism /image:c:\imageMount /cleanup-image /startcomponentcleanup /resetbase

Dism /unmount-image /mountdir:c:\imageMount /commit
{% endhighlight %}

接下来，最主要的，制作好的WIM文件要释放到系统分区，来完成**Windows的安装过程**。这个一般要在WinPE下进行：
{% highlight bat %}
Dism /apply-image /imagefile:X:\sources\install.wim /index:1 /ApplyDir:C:\
{% endhighlight %}
真省事儿，就这么一步。当然在WinPE环境下，WIM文件的来源不止是安装光盘或者U盘，也可以是网络上的路径，基于WADK的自动部署就是这样。

对应的，**抓取一个定制好的Windows系统分区**是这样，记得先Sysprep一般化：
{% highlight bat %}
Dism /Capture-Image /ImageFile:N:\custom-windows8.wim /CaptureDir:C:\ /Name:"Customized Windows 8"
{% endhighlight %}

最后，之前提到的**WIM文件支持多合一**安装源，我们之前的操作也都是指定了使用WIM中的第一个内容`/index:1`。现在看看如何把多个自定义的Windows合并到一个WIM文件里，为了管理方便，多个Windows镜像会加上易识别的命名：
{% highlight bat %}
Dism /Export-Image /SourceImageFile:c:\customImages\win8pro.wim /SourceIndex:1 /DestinationImageFile:c:\customImages\allinone.wim /DestinationName:"Windows 8 Professional"
Dism /Export-Image /SourceImageFile:c:\customImages\win8ent.wim /SourceIndex:1 /DestinationImageFile:c:\customImages\allinone.wim /DestinationName:"Windows 8 Enterprise"
Dism /Export-Image /SourceImageFile:c:\customImages\win81.wim /SourceIndex:1 /DestinationImageFile:c:\customImages\allinone.wim /DestinationName:"Windows 8.1"

::然后看看最终的效果吧：
Dism /Get-ImageInfo /imagefile:C:\customImages\allinone.wim
{% endhighlight %}

进一步折腾
----
之前我们离线往WIM里添加了RSAT管理包；但是这只是往Windows里附加了功能并没有开启，那离线开启Windows功能是这样的：
{% highlight bat %}
Dism /mount-image /imagefile:c:\images\install.wim /index:1 /mountdir:c:\imageMount

::先看看支持哪些Feature
Dism /Image:C:\imageMount /Get-Features

::开启功能，以Failover-Cluster管理工具为例，/ALL是开启依赖的父功能
Dism /Image:C:\imageMount /Enable-Feature /FeatureName:RSAT-Clustering-Mgmt /All

Dism /unmount-image /mountdir:c:\imageMount /commit
{% endhighlight %}

更多的比如Windows所含驱动的管理，离线预安装应用程序等，看看后面的参考文章吧。

**值得注意**的是，前面用到的DISM离线Windows管理操作，同时有`/online`参数，可以通过同样的方法，对当前运行的Windows进行配置管理，很是方便。

参考文章
----
* [Windows Imaging Format](https://en.wikipedia.org/wiki/Windows_Imaging_Format)
* [Windows Imaging File Format (WIM)](https://technet.microsoft.com/en-us/library/dd799284(v=ws.10).aspx)
* [压缩与反压缩之 COMPRESS 与 EXPAND](http://blogs.itecn.net/blogs/alexis/archive/2008/10/15/COMPRESS-and-EXPAND.aspx)
* [ImageX and WIM Image Format](https://technet.microsoft.com/en-us/library/cc507842.aspx)
* [DISM Image Management Command-Line Options](https://technet.microsoft.com/en-us/library/hh825258.aspx)
* [DISM 概述（部署映像服务和管理）](https://technet.microsoft.com/zh-cn/library/hh825236.aspx)
* [Windows Automated Installation Kit (Windows AIK)](https://technet.microsoft.com/en-us/library/cc748933(v=ws.10).aspx)
* [Windows Deployment with the Windows ADK](https://technet.microsoft.com/en-us/library/hh824947.aspx)
* [使用 DISM 捕获硬盘分区的映像](https://technet.microsoft.com/zh-cn/library/hh825072.aspx)
* [使用 DISM 装载和修改映像](https://technet.microsoft.com/zh-cn/library/hh824814.aspx)
* [使用 DISM 应用映像](https://technet.microsoft.com/zh-cn/library/hh824910.aspx)
* [使用 DISM 获取映像或组件的清单](https://technet.microsoft.com/zh-cn/library/hh825042.aspx)
* [使用 DISM 启用或禁用 Windows 功能](https://technet.microsoft.com/zh-cn/library/hh824822.aspx)
* [使用 DISM 预安装应用](https://technet.microsoft.com/zh-cn/library/dn387084.aspx)

[wimspec]: http://www.microsoft.com/en-us/download/details.aspx?id=13096


