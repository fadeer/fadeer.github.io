---
layout: post
title:  "更新OSX下的Ruby及组件"
date:   2015-07-05 23:15:00
author: fadeer
categories: 工作
tags: OSX Ruby
---

最近为创建博客而折腾Jekyll运行环境，因此接触到了ruby、gem什么的。在Raspbian下基本根据[官网][jekyll]的介绍，没费嘛事儿就跑起来了。理解的依赖关系大致是：

* jekyll，静态页面框架。
* liquid、pygments、kramdown等，jekyll使用的模块。
* github-pages，好吧，用github托管页面的大合集？
* ruby，上面这些都是ruby的gem（包），可以通过bundle自动获取。
* nodejs和其他OS基础组件。

所以，配置环境的重点就是ruby、gem、bundle。

OSX下遇到问题
----
隐约知道OSX下有ruby支持，因为安装更新homebrew就用的ruby脚本。但是为了新点儿，还是用`brew install ruby`更新了一下，目前的最新版是2.2.2。

然后跑`jekyll serve`报错，缺kramdown；然后bundle若干、gem若干次、sudo若干次、挂代理尝试若干，依然缺。仔细看看报错，是.../2.0.0..，什么，为什么不是/usr/local下的2.2.2，这才是brew跟装的ruby目录啊。which了一下各个命令，发现bundle似乎是旧版的。搜了下，看到stackoverflow下[11年的一个问题][sof-11]，知道了对于更新ruby，RVM不错，rbenv可能更好。

然后进[rbenv的github页面][rbenv]，了解了一下rbenv支持ruby多版本的机制和用法，觉得这个确实比较清晰，跟系统里自带的切割的比较好，于是用rbenv重新配置运行环境了。
<!--preview-end-->

清理现存ruby和gems
----
首先，查看并删除brew安装的所有gems
{% highlight bash %}
gem info —local
gem uninstall —all
{% endhighlight %}

会有几个默认的gem不能删除，接下来删除通过brew安装新版ruby：
{% highlight bash %}
brew uninstall ruby
{% endhighlight %}

然后，对于系统自带的ruby，也先把不用的gem都移掉，但是老版的gem不支持all参数，使用如下脚本：
{% highlight bash %}
for i in `gem list --no-versions`; do gem uninstall -aIx $i; done
{% endhighlight %}

使用rbenv安装新版ruby和gems
----
通过brew安装rbenv、ruby-build，并且初始化。
{% highlight bash %}
brew install rbenv ruby-build
rbenv init
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
{% endhighlight %}

查看并安装新版ruby，也是2.2.2的。这里`rbenv install`命令是ruby-build包里的。
{% highlight bash %}
rbenv install -l
rbenv install 2.2.2
{% endhighlight %}

选择使用ruby 2.2.2，全局就可以。
{% highlight bash %}
rbenv versions
* system (set by /Users/7Days/.rbenv/version)
  2.2.2
rbenv global 2.2.2
rbenv versions
  system (set by /Users/7Days/.rbenv/version)
* 2.2.2
{% endhighlight %}

来，接下来依次安装bundle和jekyll依赖的组件，#bash是新开终端窗口，用于确认使用的命令已更新。
{% highlight bash %}
#bash
which ruby
which gem
gem install bundle
#bash
which bundle
bundle install
#bash
which jekyll
{% endhighlight %}

这样，jekyll又可以愉快的跑起来了。

参考文章
----
* [Bundler](http://bundler.io/)
* [rbenv](https://github.com/sstephenson/rbenv)
* [jekyll][jekyll]


<!-- 引用链接 -->
[jekyll]: http://jekyllrb.com/
[sof-11]: http://stackoverflow.com/questions/6482738/installing-ruby-gems-not-working-with-home-brew
[bundler]: http://bundler.io/
[rbenv]: https://github.com/sstephenson/rbenv


