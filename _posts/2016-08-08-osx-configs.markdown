---
layout: post
title:  "OSX 基础配置"
date:   2016-08-08 12:00:00
author: fadeer
categories: 工作
tags: OSX
---

备忘一些OSX常见的配置操作，主要是命令行环境方面的。

Homebrew
----
安装基础包管理工具：

{% highlight bash %}
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# 检查一下状态
brew doctor
# 看看版本信息
brew config

# 补充常用命令：
brew install wget
{% endhighlight %}

Homebrew Cask
----
[Brew Cask](https://caskroom.github.io/)是用命令行的方式，安装桌面下的应用（通常是不通过商店发布的），比如常用的Chrome、iTem2等。

{% highlight bash %}
# 安装 Brew Cask
brew tap caskroom/cask

# 安装常用软件
brew cask install iterm2
brew cask install sublime-text
brew cask install google-chrome
brew cask install google-drive

brew cask install mplayerx
brew cask install qq
{% endhighlight %}

终端配置
----
主要是颜色配置相关的，呵呵。先安装GUN基础工具命令：
{% highlight bash %}
brew install coreutils
{% endhighlight %}

找一个合用的颜色配置文件：
{% highlight bash %}
wget https://github.com/seebi/dircolors-solarized/raw/master/dircolors.ansi-dark -P ~/
{% endhighlight %}

配置命令的颜色输出：
{% highlight bash %}
# ~/.bash_profile
if brew list | grep coreutils > /dev/null ; then
    PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
    alias ls='gls -F --color'
    alias ll='ls -l'
    alias dir='gdir --color'
    eval $(gdircolors ~/dircolors.ansi-dark)
fi

alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
{% endhighlight %}

定义终端提示符风格：
{% highlight bash %}
# ~/.bash_profile
export TERM="xterm-color"
export PS1="\[\033[0;32m\]\A \[\033[0;31m\]\u\[\033[0;34m\]@\[\033[0;35m\]\h\[\033[0;34m\]:\[\033[00;36m\]\W\[\033[0;33m\] $\[\033[0m\] "
{% endhighlight %}

vim语法高亮：
{% highlight bash %}
# ~/.vimrc
filetype plugin indent on
syntax on
set background=dark
{% endhighlight %}

ZSH
----
这个还没用上，稍后更新。

Ruby
----
参考[更新OSX下的Ruby及组件](https://fadeer.github.io/%E5%B7%A5%E4%BD%9C/2015/07/05/upgrade-ruby-in-osx.html)。


