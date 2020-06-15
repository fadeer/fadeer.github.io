---
layout: post
title: WSL2 下 Github-pages 容器运行
date: 2020-06-15 22:00:00 +0800
author: fadeer
categories: 工作
tags: Windows WSL Docker
---

Windows 10 2004 + WSL2 来了；尝试把之前的 Ubuntu 18.04 更新到 wsl2 版本，没成，直接新装 Ubuntu 20.04 吧。

WSL2 安装、更新：

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2
```

`Ubuntu 20.04 LTS`，之前直接下载 appx 的链接不可用，这个 [Issue](https://github.com/MicrosoftDocs/WSL/issues/645) 有讨论。所以从 [Store](https://www.microsoft.com/store/apps/9n6svws3rx71) 下载的，开始菜单直接启用就行。

- 进入 wsl Ubuntu，再任一 Powershell、cmd 窗口敲 `wsl` 就行，比如 VSCode 的终端窗口。
- 关闭 wsl Ubuntu，运行 `wsl --shutdown`。

接下来就是 Ubuntu 的原生体验了，Docker 安装按官方说明就行。由于 WSL 目前还不能使用 Systemd，见 [Blockers for systemd](https://github.com/microsoft/WSL/issues/994)；目前服务管理使用 `init script`。

```s
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get install docker-ce
sudo usermod -a -G docker $USER

# 启动 Docker 服务
sudo service docker start

# 默认启动 Docker 服务
sudo update-rc.d docker defaults

# 如果要配置 Docker Service 的代理，修改服务脚本
/etc/init.d/docker
```

接下来，基于官方的 `ruby` 做个 `github-pages` 镜像；然后，在博客工作目录下运行容器：

```s
# Genfile
source 'https://rubygems.org'
gem 'github-pages'

# Dockerfile
FROM ruby:2.7.1-alpine
RUN apk --update add --no-cache build-base
ADD Gemfile .
RUN bundle install

WORKDIR /blog
EXPOSE 4000
CMD ["bundle", "exec", "jekyll", "serve"]

# 运行服务
docker run -t --rm -v "$PWD":/blog -p 4000:4000 github-pages
```

浏览器访问 `http://localhost:4000` 就可以了。

参考：

- [Windows Subsystem for Linux Installation Guide for Windows 10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
- [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
