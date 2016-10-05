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

~~~bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# 检查一下状态
brew doctor
# 看看版本信息
brew config

# 补充常用命令：
brew install wget
~~~

Homebrew Cask
----
[Brew Cask](https://caskroom.github.io/)是用命令行的方式，安装桌面下的应用（通常是不通过商店发布的），比如常用的Chrome、iTem2等。

~~~bash
# 安装 Brew Cask
brew tap caskroom/cask

# 安装常用软件
brew cask install iterm2
brew cask install sublime-text
brew cask install google-chrome
brew cask install google-drive

brew cask install mplayerx
brew cask install qq
~~~

终端配置
----
主要是颜色配置相关的，呵呵。先安装GUN基础工具命令：

~~~bash
brew install coreutils
~~~

找一个合用的颜色配置文件：

~~~bash
wget https://github.com/seebi/dircolors-solarized/raw/master/dircolors.ansi-dark -P ~/
~~~

配置命令的颜色输出：

~~~bash
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
alias vi='vim'
~~~

定义终端提示符风格：

~~~bash
# ~/.bash_profile
export TERM="xterm-color"
export PS1="\[\033[0;32m\]\A \[\033[0;31m\]\u\[\033[0;34m\]@\[\033[0;35m\]\h\[\033[0;34m\]:\[\033[00;36m\]\W\[\033[0;33m\] $\[\033[0m\] "
~~~

vim语法高亮：

~~~bash
# ~/.vimrc
filetype plugin indent on
syntax on
set background=dark
~~~

man 语法高亮：

~~~bash
# man page highlight
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline
~~~

ZSH
----
<!--preview-end-->
OSX 目前系统已经内建 zsh 5.0了，所以直接安装oh-my-zsh就好：

~~~bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
~~~

安装 [Menlo Powerline 字体](https://gist.github.com/qrush/1595572/raw/417a3fa36e35ca91d6d23ac961071094c26e5fad/Menlo-Powerline.otf)，修改 iTerm2 配置，默认使用这个字体。

然后修改zsh的个人配置，记得把之前 bash 的命令高亮内容拷过来，当然最好是写一个共享的配置文件`~/.myShellConfig`，谁还会换回Bash么？

~~~bash
# ~/.zshrc
# 修改主题
ZSH_THEME="agnoster" 

# 调整PATH优先级
export PATH=/usr/local/bin:/usr/local/sbin/:$HOME/bin:$PATH

# Shell 通用配置
source ~/.myShellConfig
~~~

我目前觉得默认的 robbyrussell 主题挺好，可以稍微改下提示符内容：

~~~bash
#~/.oh-my-zsh/themes/robbyrussell.zsh-theme
PROMPT='${ret_status} %{$fg[cyan]%}%d%{$reset_color%} $(git_prompt_info)> '
~~~

Ruby
----
参考[更新OSX下的Ruby及组件](https://fadeer.github.io/%E5%B7%A5%E4%BD%9C/2015/07/05/upgrade-ruby-in-osx.html)。

Cntlm
----
公司翻墙必备啊，OSX 下安装也很方便。

~~~bash
brew install cntlm

# 然后改下配置文件 
/usr/local/etc/cntlm.conf

# 前端运行看看有错么，平时直接cntlm后台就行。
cntlm -f
~~~

参考
----
* [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
* [Mac 下配置终端环境 iTerm2 + Zsh + Oh My Zsh + tmux](http://www.dreamxu.com/mac-terminal/)
* [终极 Shell](http://macshuo.com/?p=676)


