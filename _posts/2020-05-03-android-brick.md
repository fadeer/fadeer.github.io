---
layout: post
title: Oneplus 7T 变砖修复
date: 2020-05-03 22:00:00 +0800
author: fadeer
categories: 工作
tags: Android
---

这纯粹是隔离在家瞎折腾出的事故，做个备忘。

手机是 Oneplus 7T，习惯用 OxygenOS，之前几代还追 Public Beta 版，随着系统完善，不是 Android 跨代，就不尝鲜了。但是官方小版本更新，还是得有。

- 原来是 O2OS 10.0.7，补丁到 2019.11
- 看镜像网站，发现 10.0.7 更新，补丁到 2019.12；忽略了**其实是 H2OS**，结果就给升了。
- 启动后发现错了，**不能降级到 O2OS** 10.0.7，因为同版本 H2OS 往往比同版本的 O2OS 要新（内部版本或时间不同）。
- 尝试使用 OnePlus Updater 强制更新到刚发布 OTA 的 10.0.8，结果重启，一晚上没进系统；只能寻求恢复。
- 进 Recovery 模式清缓存、数据，能恢复到 H2OS，是上一版系统；但不死心，想刷回 O2OS。
- Android 在 **project treble** 改造后，分区形式有所变化，分离了 android 系统、驱动、厂商定制等分区，便于 android 系统的更新。这个模式下也移除了 Recovery 下直接刷用户分区 zip 或 `adb update`，需要走 fastboot 模式。
- 而 fastboot 刷机需要的镜像跟官方默认刷机包不同，社区有人专门定制了 Oneplus 最近系统的 Fastboot 镜像，如 [Stock Fastboot ROMs for OnePlus 7T](https://forum.xda-developers.com/7t-pro/how-to/rom-stock-fastboot-roms-oneplus-7t-pro-t3991189)，但是需要 Unlock 才能正常刷，于是：
  - 进 H2OS 初始化，进开发者菜单，关 OEM Lock 锁。
  - 进 Fastboot 模式，连 PC，执行 `fastboot oem unlock`
  - 解压 fastboot 包，执行 `flashall.bat`，没报错，可以进 O2OS 了。
  - 很高兴，但是这时 bootloader 还是 unlock 的，每次手机启动都有警告提示，不好。
  - 于是进 fastboot，连 PC，执行 `fastboot oem lock`
  - 重启，红色提示，boot 损坏，不允许启动，而且 10 几秒自动重启。
  - 此时，电源关机、电源+音量下都没效果。
  - 感觉**凉了，真变砖了**... 已经再思考是不是得再买个了...

一阵慌张，感觉之前大部分操作都没问题；只不过刷过 fastboot 镜像后，虽然标称 **Stock** 版本，但还不是完整官方镜像，还需要触发官方升级之后，**确保官网镜像再 Relock**。另外，如何跳出反复重启，进 Fastboot 模式。

整理后的操作如下：

- **反复重启状态下**，按住**电源+音量上下**三建，可进 Fastboot 模式。
- 先 Unlock，`fastboot oem unlock`；再进 Fastboot 刷机。
- 下载初始版本 Fastboot 镜像，比如[这里](https://sourceforge.net/projects/fastbootroms/files/OnePlus%207T/)的 10.0.3；还是执行 `flashall.bat`。
  - 注意，升级过程有一次重启到 Fastboot，执行的是 `fastboot boot fastboot`，实际上手机进的是 Recovery 模式；保持不要操作，不要手动再进 Fastboot。
  - 在 Recovery 下完成 System 及后面几个 img 写入才对。
- 完成后可以进入 O2OS，进系统更新升级；这时会弹出，**识别到 Unlock 状态**，需要**下载完整系统镜像**，不错；等自动更新重启完，进入系统，发现还是 10.0.3。
- 这时，再进 Fastboot，连 PC，执行 `fastboot oem lock`。
- 重启，顺利启动，进入系统；再进开发者菜单，确保系统 OEM Lock 锁打开。
- 终于**恢复官方状态**了。
- 再执行一次系统更新，终于**回到 O2OS 10.0.7** 了。

折腾下来，又更新了一下对 Recovery、Fastboot 的理解，还有 Android 的镜像现状，从 `flashall` 的过程看一下：

```s
aop.img
aop.img
bluetooth.img
boot.img
dsp.img
dtbo.img
LOGO.img
modem.img
oem_stanvbk.img
qupfw.img
storsec.img
multiimgoem.img
uefisecapp.img
recovery.img
vbmeta.img
vbmeta_system.img
opproduct.img
boot fastboot 后
system.img
vendor.img
product.img
```

另外用到的 Android 工具：

- [Android USB Driver Windows](https://dl-ssl.google.com/android/repository/latest_usb_driver_windows.zip)
- [Android Platform Tool Windows](https://dl.google.com/android/repository/platform-tools-latest-windows.zip)
