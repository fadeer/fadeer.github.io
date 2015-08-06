---
layout: post
title:  "Linux下的Union文件系统"
date:   2015-08-07 12:00:00
author: fadeer
categories: 工作
tags: Linux SquashFS AuFS OverlayFS
---

之前介绍[WIM文件时][wimfile]，展示了在WinPE里实现了一个只读的文件系统（精简的Windows）；而在[WIM启动][wimboot]里，展示了一个只读文件系统加上一个可写分区，实现的一个可以正常使用的Windows。这给Windows的部署和使用带来了很大弹性，而这样的逻辑在Linux下由来已久，我们也来了解下。

Ramdisk、Initramfs对比WIM
----
一个标准Linux的部署，系统部分通常分为三块儿：

* 内核文件，一般在启动分区下`vmlinuz-{kernel.version}`；对比Windows的内核是`C:\Windows\System32\ntoskrnl.exe`。
* 内存盘（Ramdisk）被引导文件加载起来的精简系统，通常也是压缩格式的，这文件一般叫`initrd.gz-{kernel.version}`，意思就是init（初始化时用的）、rd（内存盘）、gz（压缩的）。
* 系统分区，一般是一个完整的分区，EXT4之类格式的，放置完整的Linux系统组件。

我们主要看看**Ramdisk**的作用，这个精简的系统通常是包含必要驱动和工具，完成当前机器的硬件识别（最重要的是磁盘控制器和磁盘设备），找到并挂载系统分区，然后跳转过去进入正式的系统。Ramdisk的实现方式分为两个阶段：

* **固定的磁盘文件**，一般是创建出一个64MB的文件，格式化为EXT分区，然后把精简系统的文件放进去就行。最大的限制是受创建的这个文件大小限制，如果系统增大了，你还得再新建或扩大。另外就是因为这是内存盘，因此会实际解压到内存里，其他运行的程序只能使用Ramdisk之外的部分。由于这个缘故，Ramdisk文件也不能创建很大，以免超过物理内存。这个磁盘文件**跟VHD很类似**，而且也都是以磁盘块为单位存储的格式。
* 由于上述的限制，到了Linux 2.6内核，Ramdisk的实现更新为了**Initramfs**，它本质是把精简系统文件目录使用CPIO打包，然后gzip压缩，这首先去掉了磁盘文件固定空间的限制。使用时利用tmpfs解压到内存来使用，于是避免了额外内存占用的问题。从结构上看，Initramfs实现的Ramdisk文件，就是一个以文件为基础的、支持压缩的文件格式啊，这**跟WIM的思路一样**啊。从使用场景来看，这个加载起来的精简系统Initramfs文件也跟WinPE里的boot.img文件很相近。

SquashFS、Link对比WIMBoot
----
鉴于Linux系统定制的灵活性，如果把精简系统文件补充完整就可能直接成为一个直接可用的系统，如果我们把这个“打包系统文件”以只读方式来使用，那么我们就可以获得类似Windows下WIMBoot的好处，快速部署、快速系统还原等。

我们先来看看这个只读系统文件的选择，前面不错的Initramfs反倒不适合了，因为我们没必要把整个系统都加在到内存里，最好是文件形式随用随读就好。典型的有这些方式：

* **固定的磁盘文件**，又是它。比如我们把整个系统放到一个8G、EXT4格式化的磁盘文件里，使用的时候以只读方式mount到一个目录里。虽然这种磁盘文件还是受初始容量的限制，但是跟VHD一样，它的最大优势是可以跟让物理机和虚拟机共享同一个磁盘文件（Linux下的虚拟机，嗯，必须的），就像是[Windows的VHD启动][vhdboot]里折腾一样。
* 而更理想的选择还是一个只读的、根据内容动态增减的、支持压缩的文件系统，最常见到的就是**SquashFS**。SquashFS最早出现在在Linux 2.6.29，初始的压缩格式是gzip，随着Linux内核的更新，又增加支持了LZMA、LZMA2、LZ4等，为了获得更高的压缩率。SquashFS最常见的用途是支持Linux的LiveCD，这个后面再讨论。

接下来，我们利用一个SquashFS文件，创造一个叠加的可写系统目录：
{% highlight bash %}
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

#我们看看几个文件目录的信息：
/tmp/fadeer$ du -h ubuntu-core | tail -1
182M    ubuntu-core
/tmp/fadeer$ du -h ubuntu-core.squashfs
63M     ubuntu-core.squashfs
/tmp/fadeer$ du -h system-rw | tail -1
30M     system-rw
{% endhighlight %}

于是，我们利用SquashFS，把一个目标系统目录（182MB）打包为压缩文件（63MB），然后创建了一个可写系统分区（system-rw），建立了一堆链接（30MB）作为系统分区的文件，然后就可以`chroot`到system-rw里玩耍了，新建的所有文件都会存放在这个目录下。哎，这跟[install.wim和WIMBoot][wimboot]是一样一样的啊。

而SquashFS文件的制作是这样的：
{% highlight bash %}
#安装必要的工具
apt-get install squashfs-tools

#把目录打包为squashfs文件
mksquashfs ubuntu-core ubuntu-core.squashfs
{% endhighlight %}

Union FileSystem对比Custom.img
----
之前提到了，SquashFS通常在Linux的LiveCD来使用，除了提供高压缩节省空间的好处，最主要的还是可以基于光盘直接把Linux桌面跑起来（这才是Live嘛），让用户可以直接测试评估、甚至正常使用。这后面就用到了SquashFS叠加tmpfs可写内存文件系统的方式。但是用户运行时所作的更改重启后也就丢失了，那么有没有可能保存下来呢？当然，这就是**Union FileSystem**。终于回来了，我都觉得快跑题儿了。
<!--preview-end-->

Union FileSystem的核心逻辑是Union Mount，它支持把一个目录A叠加到另一个目录B之上；用户对目录B的读取就是A加上B的内容，而对B目录里文件写入和改写则会保存在目录A上，因为A在上一层。这个类似差分VHD的效果，但是是以文件为单位的。因为是Union FS主要责叠加访问的逻辑，因此对叠加的目录的原始文件系统适应性比较好。

再回到LiveCD，如果我们有机会把电脑本地的一个分区作为持久的可写目录叠加在squashfs目录上，那么我们就不用担心重启的问题了。Ubuntu的LiveCD就是这么干的，用户可以在本地硬盘创建一个id为`casper-rw`的分区，这个分区就会自动被`mount`到默认用户目录`/home/ubuntu`下，就可以持久保存用户在桌面、文档等目录下放置的文件了。

UnionFS 常见的实现有：

* **UnionFS**，很早就开始的实现，看名字就很霸道，目前使用较少。
* **AuFS**，全称是Advanced Multi Layered Unification Filesystem。创建于2006年，是对UnionFS的重构，因此初期也叫Another UnionFS。AuFS被众多Linux发行版所使用，主要的场景就是LiveCD。目前最新的版本是AuFS4。
* **OverlayFS**，近几年的Ubuntu发行版就使用的这个实现。OverlayFS的最大优势是在Linux 3.18时合并到内核，成为了Linux内建支持的文件系统了。

我们以AuFS为例，看看使用的效果：
{% highlight bash %}
#安装工具
/tmp/fadeer$ sudo apt-get install aufs-tools

#叠加mount，system-rw覆盖在ubuntu-core上，叠加的入口在/tmp/aufs
/tmp/fadeer$ sudo mount -t aufs -o br=/tmp/fadeer/system-rw:/tmp/fadeer/ubuntu-core none /tmp/aufs

#看看效果
/tmp/fadeer$ cd /tmp/aufs/
/tmp/aufs$ ls
bin  etc  home  lib  lib64  opt  sbin  sys  usr  var #看着跟ubuntu-core一样
/tmp/aufs$ touch new-file #新建个文件
/tmp/aufs$ ls
bin  etc  home  lib  lib64  new-file  opt  sbin  sys  usr  var
/tmp/aufs$ ls /tmp/fadeer/ubuntu-core
bin  etc  home  lib  lib64  opt  sbin  sys  usr  var #ubuntu-core是只读的
/tmp/aufs$ ls /tmp/fadeer/system-rw/
new-file #新文件实际保存在system-rw里
{% endhighlight %}

OverlayFS也差不多：
{% highlight bash %}
sudo mount -t overlayfs -o rw,upperdir=/tmp/fadeer/system-rw,lowerdir=/tmp/fadeer/ubuntu-core overlayfs /tmp/overlayfs
{% endhighlight %}

进一步折腾
----
从设计上看，Union文件系统的叠加深度没有限制，但是从读写性能来看，不建议层次太多。在Ubuntu下，OverlayFS的**默认叠加深度只有2**，这是遵循Linux的设置`FILESYSTEM_MAX_STACK_DEPTH`。如果需要更多，就得重编加以支持。

那么，**多层叠加**有什么用途？那就是目前很火热的**Docker**。Docker是利用Linux的容器技术，来实现的轻量化Linux运行实例。而存储层的支持之一就是Union FileSystem，叠加的特性让Docker实例可以由基础Linux、Web容器、数据库、业务程序、运行配置与数据（可写）等多层来构成，而每层作为一个独立的软件包，可以共享使用和方便管理。Docker最先使用的存储支持就是AuFS，后来才增加了OverlayFS。

关于Docker的话题，值得以后另开一篇。

参考
----
* [Union mount](https://en.wikipedia.org/wiki/Union_mount)
* [Unionfs: A Stackable Unification File System](http://unionfs.filesystems.org/)
* [UnionFS](https://en.wikipedia.org/wiki/UnionFS)
* [OverlayFS](https://en.wikipedia.org/wiki/OverlayFS)
* [OverlayFS documentation](https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/filesystems/overlayfs.txt)
* [Aufs](http://aufs.sourceforge.net/)
* [Initramfs](https://wiki.ubuntu.com/Initramfs)
* [SquashFS](https://en.wikipedia.org/wiki/SquashFS)
* [A brief history of union mounts](https://lwn.net/Articles/396020/)
* [OverlayFS commit to Linux](https://github.com/torvalds/linux/commit/e9be9d5e76e34872f0c37d72e25bc27fe9e2c54c)
* [Introduction to Docker (as presented at December 2013 Global Hackathon)](http://www.slideshare.net/jpetazzo/introduction-to-docker-0-7-hackathon)
* [Comprehensive Overview of Storage Scalability in Docker](http://developerblog.redhat.com/2014/09/30/overview-storage-scalability-docker/)

[wimfile]: http://fadeer.github.io/工作/2015/08/05/windows-wim-fileformat.html
[wimboot]: http://fadeer.github.io/工作/2015/08/06/windows-wim-boot.html
[vhdboot]: http://fadeer.github.io/%E5%B7%A5%E4%BD%9C/2015/07/23/windows-native-vhd-boot.html



