---
layout: post
title:  理解 Raspberry Pi 的 APT 源
date:   2016-11-07 20:00:00
author: fadeer
categories: 工作
tags: Linux RaspberryPi
---

这个几乎天天在用，但是就没深究过；借着测试国内APT源分析一下。

Raspberry 官方源
----
来源有两个（这里跳过源码源）：

~~~bash
$ cat /etc/apt/sources.list
deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib non-free rpi

$ cat /etc/apt/sources.list.d/raspi.list
deb http://archive.raspberrypi.org/debian/ jessie main ui
~~~

逻辑是这样：

* **mirrordirector.raspbian**.org/**raspbian**/，里面是基本软件包的源，发行版是**jessie**，软件包目录选择了**main**、contrib、non-free、rpi，树莓派的架构是**armhf**。所以实际的索引包的路径（以main为例）就是：[raspbian/dists/jessie/main/binary-armhf/](http://mirrordirector.raspbian.org/raspbian/dists/jessie/main/binary-armhf/)。
* 同样，**archive.raspberrypi**.org/**debian**/，里面只包含了main和ui两个目录，感觉是偏核心的源，同理main的索引包实际路径是：[debian/dists/jessie/main/binary-armhf/](http://archive.raspberrypi.org/debian/dists/jessie/main/binary-armhf/)。两个main的Packages.gz分别是 12M 和 105K，什么区别？这个源下的main是树莓派Kernel相关的，所以这个必须有啊，要不脏奶牛怎么防。另外，新增的chromium-browser就在这个源的ui下。

然后，把这些源都切换到国内镜像，更新速度就能上来了。

国内的源
----
选择其实挺多，[网易](http://mirrors.163.com/)、[搜狐](http://mirrors.sohu.com/)、[阿里](http://mirrors.aliyun.com/)这方面做的都不错，先用着阿里的。

为了管理方便，**注掉了sources.list的内容**，增加了sources.list.d/**raspbian.list**作为基本源：

~~~bash
$ cat /etc/apt/sources.list.d/raspbian.list
deb http://mirrors.aliyun.com/raspbian/raspbian jessie main contrib non-free rpi
~~~

但是寻找Kernel源时费劲了，之前有文章指向debian的源http://mirrors.aliyun.com/debian，但是发现不对路啊，没有binary-armhf路径。

后来发现这部分[科大](https://lug.ustc.edu.cn/wiki/mirrors/help/raspbian)一直在同步。于是**raspi.list**修改为：

~~~bash
$ cat /etc/apt/sources.list.d/raspi.list
deb http://mirrors.ustc.edu.cn/archive.raspberrypi.org/debian/ jessie main ui
~~~

希望阿里什么时候也能跟上。


Docker的源
----
Docker的默认源是，[apt.dockerproject.org/repo/dists/raspbian-jessie/main](https://apt.dockerproject.org/repo/dists/raspbian-jessie/main)，国内访问起来也挺慢的，好在阿里也同步过来了（合作了就是不一样？），于是用上：

~~~bash
$ cat /etc/apt/sources.list.d/docker.list
deb http://mirrors.aliyun.com/docker-engine/apt/repo raspbian-jessie main
~~~


