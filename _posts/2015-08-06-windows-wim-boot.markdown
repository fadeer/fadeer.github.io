---
layout: post
title:  "Windows的WIM启动"
date:   2015-08-06 12:00:00
author: fadeer
categories: 工作
tags: Windows WIM
---

前面介绍了[WIM文件的概况和主要用途][wimfile]，里面提及了WIM可以作为系统分区来使用，WindowsPE那样。那么，有没有可能正常的Windows系统也从WIM来启动，顺便可以获得一些好处，比如快速恢复初始状态、节省空间什么的。嗯，这个可以有，这个就是Windows 8.1 更新版开始支持的WIMBoot。

WIMBoot
----
WIMBoot全称是Windows Image File Boot、Windows映像文件启动，就是Windows从压缩的WIM文件启动的方式，我们先从分区布局上看看WIMBoot跟一般Windows安装有什么区别。

默认的Windows 8.1分区布局是这样的：

![][pic1]

* 重点是蓝绿色是我们常见的Windows分区内容，一般肯定是实体文件了，一个Windows 8.1初装完成后要占据近9G空间。
* 而后面棕色的部分则是恢复分区使用的install.wim，一键恢复出厂设置就靠这个了。哇噻，原来品牌电脑是这么玩儿的。
* WinRE是恢复环境（Windows Restore Environment），跟WinPE类似；winre.wim所使用的精简Windows镜像，对应WinPE的boot.img。
* ESP和MSR是UEFI的启动分区。

而使用WIMBoot时，是这样的：

![][pic2]

* 最主要的区别是蓝绿色的系统分区内容**从实体文件变成了指针文件**，而且占用空间一下小了很多。这就是WIMBoot的核心逻辑，Windows启动、运行用到的文件都是链接指向初始的install.wim里的文件，而系统运行、用户操作所新增、改写的文件都像以前一样保存在系统分区里。
* custom.wim又是什么东西？这其实是PC生产商针对每个型号的PC，定制化的部分（包含更新的驱动和预安装的软件）。custom.wim可以当做是默认install.wim的增补，类似VHD的差分磁盘，但是记得WIM是基于文件的格式。于是典型的WIMBoot实际上是系统分区是**链接文件 -> custom.wim -> install.wim**。所以，如果Windows基础镜像install.wim是4个G，厂商定制部分custom.wim是3个G，那非WMIBoot时的install.wim也是得要7个G的，哇噻，原来品牌电脑是这么玩儿的，把我的32G的平板玩儿成8G的了。

WIMBoot的好处和限制
----
从上面的比较，我们也能大致理解WIMBoot所带来的好处：

* **安装快速**，减少了解压缩Windows文件并写入系统分区的过程，转换成了创建链接文件。同样的，系统还原、恢复出厂状态什么的也都快些了。
* **简化PC生产商的部署自定义过程**，最明显的，每个机型的自定义镜像从改动过install.wim的7G，减少到了custom.wim的3个G嘛。
* **节省空间、提高用户可支配空间**，特别是Windows平板这种SSD很有限的设备。好吧，其实也就是这个对最终用户比较有用，否则往常的方式，那就是迫使“聪明”的用户自己把后面的恢复分区删掉，一般也能省出个7、8个G呢。

WIMBoot是Windows比较新的功能，**从2014年4月的Windows 8.1 更新版**才开始支持的，除此之外还有一些别的限制：

* 只支持从UEFI模式启动，近些年新机器应该都支持了。这也是个建议了，基于BIOS+MBR磁盘的WIMBoot也是能跑的。
* 建议使用SSD，不支持传统机械磁盘，这应该是从性能上考虑给出的建议，实际上机械磁盘也是可以跑WIMBoot的，速度下降也不明显。
* 可能不兼容一些备份、杀毒、加密等工具。说反了，估计有问题工具以后的新版本会支持的，呵呵。

动手部署一个WIMBoot的Windows
----
<!--preview-end-->
我们使用**Windows 8.1 With Update安装盘ISO**来进行操作，ISO里自带的install.wim是不支持WIM启动的，所以我们首先要改造一下:

{% highlight bat %}
dism /export-image /wimboot /sourceimagefile:c:\wincd\sources\install.wim /sourceindex:1 /destinationimagefile:c:\wincd\sources\wimboot.wim
makewinpemedia /iso c:\wincd c:\windows8.1update_wimboot.iso
{% endhighlight %}

这里c:\wincd是ISO解开的内容，新生成wimboot.wim有3.9G，原来的install.wim是3.2G，嫌大可以把原来的install.wim删除。然后我们修改过的内容再打成ISO就行，用到的makewinpemedia来自于[Windows ADK][wadk81u]。

然后用这个修改过的ISO来启动测试机器，如果使用物理机，记得选择UEFI模式，也要可以制作支持UEFI启动的安装U盘；如果你使用Hyper-V虚拟机，记得创建二代虚拟机。

还是在安装界面时按`Shift-F10`，打开命令行窗口：

{% highlight bat %}
diskpart

::当然是GPT磁盘
select disk 0
clean
convert gpt

::EFI启动分区
create partition efi size=100
format quick fs=fat32 label=system
create partition msr size=128

::系统分区，剩8个G给镜像分区，这部分预留容量自己控制，够用就好。
create partition primary
shrink minimum=8192
format quick fs=ntfs label=windows
assign letter=c

::镜像分区
create partition primary
format quick fs=ntfs label=images
assign letter=m
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac" ::这个是恢复分区类型的GUID，PARTITION_MSFT_RECOVERY_GUID
gpt attributes=0x8000000000000001 ::设定GPT分区属性，GPT_BASIC_DATA_ATTRIBUTE_NO_DRIVE_LETTER & GPT_ATTRIBUTE_PLATFORM_REQUIRED

exit
{% endhighlight %}

然后是安装WIMBoot，不能靠Windows自己的安装程序了，用DISM自己来：

{% highlight bat %}
::拷贝WIM文件
md m:\winImages
copy d:\sources\wimboot.wim m:\winImages\wimboot.wim

::以WIMBoot方式释放文件，就是创建系统分区上的指针文件
md C:\Recycler\Scratch
DISM /Apply-Image /ImageFile:m:\winImages\wimboot.wim /ApplyDir:C: /Index:1 /WIMBoot /ScratchDir:C:\Recycler\Scratch

::安装启动
c:\windows\system32\bcdboot c:\windows /l "Windows 8.1 Update (WIMBoot)"
{% endhighlight %}

重启，等完成Windows的初始化工作，就可以正常使用了，没感觉出什么区别嘛。这时的系统分区占用才1.5G（不算内存文件），可以啊。这时，你可以从磁盘管理器里看系统分区有个“WIMBoot”的标识符，另外也可以通过下面的命令查看系统分区指向的WIM文件位置：

{% highlight bat %}
C:\windows\system32>fsutil wim enumwims c:
   0 {A197A691-2023-44D3-8F2F-FC8BC7EEE6DE} 00000001 \\?\Volume{a5759ad6-b03e-4bb3-b6e7-28f0786d66e0}\winImages\wimboot.wim:1

Objects enumerated: 1
{% endhighlight %}

正式生产时的考虑
----
前面我们以Windows 8.1 Update做了一个最快速但是粗糙的WIMBoot例子，在正式生产中，还是要考虑wim内容能干净优化一些，通常有这些操作：

{% highlight bat %}
copy c:\wincd\install.wim c:\wmiboot.wim
::移除没必要的winre.wim
dism /mount-image /imagefile:c:\wmiboot.wim /index:1 /mountdir:c:\mount
move c:\mount\windows\system32\recovery\winre.wim c:\wincd\winre.wim
::优化镜像，增加WIMBoot支持
dism /optimize-image /image:c:\mount /wimboot
dism /unmount-image /mountdir:c:\mount /commit
{% endhighlight %}

如果你想在基础镜像里补充一些驱动、更新一些补丁，让这个镜像更适合生产的PC，那还得有一个正常部署、更新、Sysprep一般化、再抓取（加`/wimboot`参数）的过程，详细见[参考文章][create]。

哎，前面提到的**custom.wim定制化部分**怎么来的？这是利用DISM的增量抓取功能。

* 首先向前面一样，使用通用install.wim，部署一个WIMBoot的Windows。
* 然后进审核模式完成最终定制化，驱动、补丁、预安装软件什么的，Sysprep一般化。
* 重启以WinPE来启动，抓取定制化部分

{% highlight bat %}
DISM /Capture-CustomImage /CaptureDir:C: /ScratchDir:C:\Recycler\Scratch
{% endhighlight %}

DISM把指针文件之外的用户文件作为新增部分，抓取为custom.wim，显然这个差分部分是要配合对应install.wim同时使用的。在部署时DISM `/Apply-Image`时使用custom.wim就可以了。

值得注意的是，放置install.wim和custom.wim文件的这个**镜像分区是不能动态扩大的**，难道是修改分区会造成WIM文件的位置变化，因而造成指针文件失效？因此要保持镜像分区够用即可。可是定制化部分弹性很大，不确定怎么办？见参考文章，这里主要的逻辑是借着系统分区倒腾一下，等custom.wim确定下来，再完成最后的部署工作，过程如下图：

![][pic3]

进一步折腾
----
前面展示默认安装的分区布局时看到一个恢复分区和winre.wim，在WIMBoot的情况下，把winre.wim跟其他wim都放在镜像分区比较合适。

在WIMBoot安装完成后，把恢复镜像也拷贝过去，注册一下就可以了：

{% highlight bat %}
md m:\recoveryImages
copy d:\sources\winre.wim m:\recoveryImages\winre.wim 
c:\windows\system32\reagentc /setreimage /path m:\recoveryImages /target c:\windows
{% endhighlight %}

另外，Windows 8.1 Update是作为一个补丁出现的（类似于SP1），那么基于Windows 8.1原始版的ISO做WIMBoot启动时，你需要把WinPE环境从5.0升级为5.1，DISM也会升级才能支持WIMBoot相关参数，见[参考文章][winpe501]。

参考文章
----
* [Windows 映像文件启动 (WIMBoot) 概述](https://technet.microsoft.com/zh-cn/library/dn594399.aspx)
* [创建 WIMBoot 映像](https://technet.microsoft.com/zh-cn/library/dn621983.aspx)
* [部署 WIMBoot 映像：如果你事先知道映像的大小](https://technet.microsoft.com/zh-cn/library/dn605112.aspx)
* [部署 WIMBoot 映像：如果你事先不知道映像的大小](https://technet.microsoft.com/zh-cn/library/dn594395.aspx)
* [WIMBoot：识别你的电脑是否已配置为从 WIM 文件启动](https://technet.microsoft.com/zh-cn/library/dn631790.aspx)
* [将 WinPE 5.0 更新到 WinPE 5.1][winpe501]
* [DISM 中的新增功能](https://technet.microsoft.com/zh-cn/library/dn419776.aspx)

[wimfile]: http://fadeer.github.io/工作/2015/08/05/windows-wim-fileformat.html
[wadk81u]: http://www.microsoft.com/en-us/download/details.aspx?id=39982
[create]: https://technet.microsoft.com/zh-cn/library/dn621983.aspx
[winpe501]: https://technet.microsoft.com/zh-cn/library/dn613859.aspx

[pic1]: http://7xkxri.com1.z0.glb.clouddn.com/wimboot-1.png
[pic2]: http://7xkxri.com1.z0.glb.clouddn.com/wimboot-2.png
[pic3]: http://7xkxri.com1.z0.glb.clouddn.com/wimboot-3.png
