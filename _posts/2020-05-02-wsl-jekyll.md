---
layout: post
title: Windows WSL 下配置 jekyll 运行环境
date: 2020-05-02 22:00:00 +0800
author: fadeer
categories: 工作
tags: Windows
---

家里电脑更新成了 `NUC10 i7`，系统也就迁移到了 Windows 10。由于 `WSL` 对 Linux Docker 的支持要 Windows 20H1 内建的 `WSL2` 才行；之前工作很少使用。借着运行 `Jekyll + Github Pages` 运行环境，也算用起来了。

安装 WSL 功能，需要重启:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

下载安装 Ubuntu 18.04 镜像:

```powershell
curl.exe -L -o ubuntu-1804.appx https://aka.ms/wsl-ubuntu-1804
Add-AppxPackage .\ubuntu-1804.appx
```

然后开始菜单就能看到 `Ubuntu 18.04`，启动完成初始化，就进入 Linux 环境了。

```s
# 基础依赖包，都安装到系统里
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install ruby-full build-essential

# 当前版本
$ ruby --version
ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux-gnu]
$ gem --version
2.7.6

# 从 gems 开始，安装到用户目录下
$ export GEM_HOME="~/.gems"
$ gem update
$ gem install bundle

$ bundle --version
Bundler version 2.1.4

# bundle 的 gems 配置，配置文件写在 .bundle/config
$ bundle config set path "~/.gems"
# 通过 bundle 安装依赖，其实只有一个 github-pages
$ bundle install

# 然后就可以 ？
$ bundle exec jekyll serve
```

还不行，这里会报一个 `apply2files` 的权限错误：

> jekyll 3.8.5 | Error: Operation not permitted @ apply2files - /mnt/c/...

这是因为 WSL 默认挂载 `C:` 的权限问题，需要重新 `mount`；持久化配置要修改 `/etc/wsl.conf`，重启生效。

```s
sudo umount /mnt/c
sudo mount -t drvfs C: /mnt/c -o metadata

# /etc/wsl.conf
[automount]
enabled = true
options = "metadata"
```

然后就可以愉快的：

```s
bundle exec jekyll serve
```

新一代的 SSD、CPU 真是快了很多...
