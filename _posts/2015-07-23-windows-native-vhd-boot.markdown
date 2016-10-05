---
layout: post
title:  "Windows的Native VHD Boot"
date:   2015-07-23 17:00:00
title2: ""
author: fadeer
categories: 工作
tags: Windows VHD
---

VHD的历史
----
VHD是微软的虚拟磁盘文件格式，创造者是Connectix公司。微软收购了Connectix和它的Virtual PC产品，于是开始有了“自己”的客户端虚拟化产品线，VHD就是Virtual PC里使用的虚拟磁盘文件。VHD支持固定大小、动态扩展和差分三种模式；这时期VHD格式的容量上限是127GB。

到了Windows Server 2008，微软开始了自己服务器虚拟化产品线Hyper-V，VHD也是其虚拟磁盘文件格式。微软将VHD容量上限提升到2TB，更详细的描述见[VHD规格](http://download.microsoft.com/download/f/f/e/ffef50a5-07dd-4cf8-aaa3-442c0673a029/Virtual%20Hard%20Disk%20Format%20Spec_10_18_06.doc)。

在Windows Server 2012这一代，微软引入了VHDX文件格式；作为VHD的扩展，容量上限提升到了64TB，另外还包括一些性能和可靠性的改善。详细的描述见[VHDX规格](http://download.microsoft.com/download/E/F/E/EFED95B0-FAED-4BED-8543-84B6C33B8824/VHDX%20Format%20Specification-v1.00.docx)。

Native VHD Boot
----
那么，除了在虚拟机里使用，VHD可以在物理机有应用场景么？在虚拟机使用场景里，VHD一直作为虚拟机完整的硬盘，包括启动信息、启动分区、系统分区（所见的C盘），甚至还包括数据分区（所见的D盘等）。在物理机下，把VHD作为系统分区就是一个好玩又好用的模式，这就是Windows的Native VHD Boot。

Native VHD Boot是从Windows 7这一代开始引入的，用户可以将系统安装到一个VHD文件里，作为系统分区来启动、使用。那Native Boot到底有嘛好处？

* 将系统部署到一个VHD文件里，可以方便的限制系统分区容量，不够时还能扩展，提供比分区更灵活的管理方式。
* 得益于Windows的硬件兼容性，VHD文件可以方便的在多个硬件环境下迁移、甚至是物理机、虚拟机之间使用（这个后面有利用）。
* VHD文件方便备份和拷贝部署。利用VHD文件的差分机制，也可以方便实现多“分支”，便于一些实验、测试等。
* Native VHD Boot同样支持Windows Server，VHD可以实现快捷的系统恢复。

创建一个从VHD启动的Windows 7
---
<!--preview-end-->
咱们在一个正在使用的Windows 7上，再增加一个VHD的Windows 7，就是咱先免掉了新建启动分区这一步。

首先，**创建一个安装用的U盘**（4G以上容量）：

~~~powershell
diskpart
select disk 5 ::选择U盘disk
clean
create partition primary
format fs=ntfs quick
active
exit
~~~
然后将Windows 7安装盘的内容拷贝到U盘上，注意选用企业版或者旗舰版。

然后，**创建一个用于安装Windows 7的VHD文件**：

~~~powershell
diskpart
create vdisk file=c:\windows7.vhd maximum=25600 type=expandable 
exit
~~~
注意，虽然VHD是动态扩展的，但是C盘分区还是要能保证剩余空间可以放开完整的VHD，这里是25GB。
另外，这一步也可以通过磁盘管理器的创建虚拟磁盘来完成。

U盘启动，进入Windows安装，再点击安装前，按Shift-F10弹出命令行窗口，**挂载VHD文件**：

~~~powershell
diskpart
select vdisk file=c:\windows7.vhd
attach vdisk
exit
~~~

然后就可以开始跟往常一样的安装过程了，注意设备选择VHD这个硬盘。
直到再次启动，你可以看到启动项里多了一个Windows 7，这个就是VHD里的了。启动完成后，就可以像往常一样使用Windows了，丝毫感觉不到什么区别，VHD所带来的性能影响也是很小的。值得关注的一点是，看看C盘的空间，这个VHD文件就直接显示为最大容量，这就是之前需要保证剩余空间的原因。因为对于动态扩展磁盘，随着windows的使用要逐渐增大，Native Boot要保证不会因为没空间增长而产生错误。

Native VHD Boot的一些限制
----
除了上面这个磁盘剩余空间的注意事项，Native Boot还有些本身的限制：

* 不支持系统休眠
* VHD不支持放置在SMB共享上
* BitLocker加密不能使用
* 不能使用动态磁盘，比如Raid模式等。
* 不支持系统升级，就是说，如果你想把一个VHD上的Windows 8 升级到 8.1是不行的，只能再新建一个VHD。
* Windows 7这一代，Native Boot只能启动企业版和旗舰版。官方的说法是，任何版本Windows7都支持Native Boot启动，但是只有企业版和旗舰版才能运行。就是说，前面的步骤，如果你安装一个Windows 7专业版都是能成功的，但是直到启动时，你会看到一个当前系统不支持从VHD启动的错误，这不坑爹么，这跟不支持有什么区别。当然Windows Server都是支持的，另外Windows 7 Embedded Standard也能支持，我家的下载机就是这么用的。
* Windows 8/8.1支持专业版、企业版、旗舰版。

从头创建一个Native Boot的Windows
----
对于一台没有系统的机器、或者新的硬盘、移动硬盘等，我们要全新部署一个VHD上的Windows，过程大致如下。

首先，还是USB安装盘启动，这一步最好使用完整的WinPE（准备过程暂不在这里讨论），要用到imagex工具（也可以单独下载放到上面做的安装U盘上）。我们要在一个全新的磁盘上，创建启动分区、数据分区，然后在数据分区上放置用于安装Windows的VHD。在安装前按Shift-F10打开命令行窗口：

~~~powershell
diskpart

::选择全新磁盘的disk
select disk 5
clean

::创建300MB的启动分区
create partition primary size=300
format fs=fat32 quick
active
assign letter=u

::剩余空间作为数据分区
create partition primary
format fs=ntfs quick
assign letter=v

::创建VHD文件，40GB
create vdisk file=v:\windows7.vhd maximum=40000 type=expandable
attach vdisk
create partition primary
format fs=ntfs quick
assign letter=w

exit
~~~

接下来，不使用图形安装，而是利用imagex直接释放Windows镜像内容：

~~~powershell
imagex /apply x:\sources\install.wim 1 w:
~~~

然后，向启动分区安装启动信息：

~~~powershell
cd v:\windows\system32
bcdboot v:\windows /s s: /l windows7-vhd
~~~

最后，摘掉VHD文件：

~~~powershell
diskpart
select vdisk file=v:\windows7.vhd
detach vdisk
exit
~~~
重启，就看到一个崭新的Windows了。

另外，对于**Windows 8和以后的系统**，可以使用新的格式和工具：

~~~powershell
::建议使用VHDX格式
create vdisk file=v:\windows8.vhdx maximum=40000 type=expandable

::还可以使用dism工具来完成windows的部署
dism /apply-image /imagefile:x:\sources\install.wim /index:1 /applydir:w:\
~~~

进一步折腾
----
之前限制里提到了，Native VHD Boot不支持Windows升级，比如从8升级到8.1，那怎么办？来换换脑子，回到VHD的原始场景，虚拟机。可以把这个VHD挂在到一个Hyper-V虚拟机上（Windows 8同样支持Hyper-V功能啊），那它又变回了物理模式（在虚拟机里看），然后就用8.1的ISO升级安装嘛，更新好的VHD再替换到Native VHD Boot的路径下。



参考
----
* [VHD (file format) Wiki](https://en.wikipedia.org/wiki/VHD_(file_format))
* [Understanding Virtual Hard Disks with Native Boot](https://technet.microsoft.com/en-us/library/hh825689.aspx)
* [Deploy a Virtual Hard Disk for Native Boot](https://technet.microsoft.com/en-us/library/dd744338(WS.10).aspx)
* [Add a Native-Boot Virtual Hard Disk to the Boot Menu](https://technet.microsoft.com/en-us/library/dd799299(v=ws.10).aspx)
* [Booting Windows to a Differencing Virtual Hard Disk](http://blogs.msdn.com/b/heaths/archive/2009/10/13/booting-windows-to-a-differencing-virtual-hard-disk.aspx)
* [Download and install Windows PE (WinPE) so you can boot from a USB flash drive or an external USB hard drive](https://technet.microsoft.com/en-us/library/hh825709.aspx)
* [Windows 8 Native VHD Boot](http://goxia.maytide.net/read.php/1648.htm)
* [Windows 10 Native VHD Boot](http://goxia.maytide.net/read.php/1764.htm)
* [Upgrading Windows 8 to 8.1 (Native VHD Boot)](https://social.technet.microsoft.com/forums/windows/en-US/b9ca72ab-cdc3-4ae8-be6f-1ce9cb18ffb6/upgrading-windows-8-to-81-native-vhd-boot)


