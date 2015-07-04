---
layout: post
title:  "测试帖子的常见元素的表现"
date:   2015-09-09 12:00:00
author: fadeer
categories: jekyll markdown test
---

这是一个测试帖，用来调试常见帖子元素的风格。比如：

文字，段落
----

When in the Course of human events, it becomes necessary for one people to dissolve the political bands which have connected them with another, and to assume among the Powers of the earth, the separate and equal station to which the Laws of Nature and of Nature's God entitle them, a decent respect to the opinions of mankind requires that they should declare the causes which impel them to the separation.
在有关人类事务的发展过程中，当一个民族必须解除其和另一个民族之间的政治联系，并在世界各国之间依照自然法则和自然之造物主的意旨，接受独立和平等的地位时，出于人类舆论的尊重，必须把他们不得不独立的原因予以宣布。

We hold these truths to be self-evident, that all men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty, and the pursuit of Happiness.
我们认为下面这些真理是不言而喻的：人人生而平等，造物者赋予他们若干不可剥夺的权利，其中包括生命权、自由权和追求幸福的权利。

That to secure these rights, Governments are instituted among Men, deriving their just powers from the consent of the governed.
为了保障这些权利，人类才在他们之间建立政府，而政府之正当权力，是经被治理者的同意而产生的。


常见的语法高亮
----

**Javascript**，代码和正文保持纵向对齐：
{% highlight javascript %}
function start(){
	num1++;
	document.title = num1;
}
document.addEventListener("mousedown",function(){
	this.addEventListener("mousemove",start,false);
},false);
document.addEventListener("mouseup",function(){
	this.removeEventListener("mousemove",start,false);
});
{% endhighlight %}
<!--preview-end-->

Linux **Bash**，包含横向滚动：
{% highlight bash %}
#!/bin/bash
for fullpath in "$@"
do
    filename="${fullpath##*/}"                      # Strip longest match of */ from start
    dir="${fullpath:0:${#fullpath} - ${#filename}}" # Substring from 0 thru pos of filename
    base="${filename%.[^.]*}"                       # Strip shortest match of . plus at least one non-dot char from end
    ext="${filename:${#base} + 1}"                  # Substring from len of base thru end
    if [[ -z "$base" && -n "$ext" ]]; then          # If we have an extension and no base, it's really the base
        base=".$ext"
        ext=""
    fi

    echo -e "$fullpath:\n\tdir  = \"$dir\"\n\tbase = \"$base\"\n\text  = \"$ext\""
done
{% endhighlight %}

**Java**， 包含行号：
{% highlight java linenos%}
public static void main( String[] args ){
    Dog aDog = new Dog("Max");
    foo(aDog);

    if( aDog.getName().equals("Max") ){ //true
        System.out.println( "Java passes by value." );

    }else if( aDog.getName().equals("Fifi") ){
        System.out.println( "Java passes by reference." );
    }
}
{% endhighlight %}

也可以在文字间加代码，比如`/etc/network/interfaces`这样。


列表内容
----

* 第一项，内容。
* 第二项，内容。
* 第三项，内容，**重要的内容**。
* 第四项，内容，[外部链接](http://www.google.com)。


这种把正文内容和引用的原始链接分开的方式不错，[参考1][链接1]和[参考2][链接2]，这样编辑markdown正文时，就不会被过长的[链接3]打断了。

<!-- 下面就是原始的链接，不会直接出现在正文里 -->
[链接1]:	http://www.google.com
[链接2]:	http://www.google.com
[链接3]:	http://www.google.com


富媒体内容
----
引用一张图片，是这样的：

![](https://drscdn.500px.org/photo/100664911/m%3D900/0f41604dc77d7a5d1d347b9533b844ba)

原始很大的图片，在高分辨率屏下效果应该不错；如果图片宽度不够，也要填满宽度，虽然会显得模糊：

![](http://www.workshifting.com/wp-content/uploads/2012/12/1-casual-4am-walks_-by-Josh-Sam-Downloaded-from-500px1-595x240.jpg)


更多元素
----
参考：[kramdown Syntax](http://kramdown.gettalong.org/syntax.html)


