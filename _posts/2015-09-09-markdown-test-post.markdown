---
layout: post
title:  "测试帖子的markdown语法"
date:   2015-09-09 12:00:00
categories: jekyll markdown
---

这是一个测试帖，用来调试常见帖子元素的风格。比如：

包含大量废话的段落。废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话；废话、大段的废话。

列表：

* 第一项，内容。
* 第二项，内容。
* 第三项，内容，**重要的内容**。
* 第四项，内容，[外部链接](http://www.google.com)。

常见的语法高亮:
<!--preview-end-->

* Javascript
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

* Linux Bash
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

* Java， 包含行号
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

这种把正文内容和引用的原始链接分开的方式不错，[参考1][链接1]和[参考2][链接2]，这样正文就不会被过长的[链接3]打断了。

<!-- 下面就是原始的链接，不会直接出现在正文里 -->
[链接1]:	http://www.google.com
[链接2]:	http://www.google.com
[链接3]:	http://www.google.com

如果引用一张图片，效果是这样的：

![](http://www.markgray.com.au/images/gallery/large/desert-light.jpg)

如果图片宽度不够，效果是：

![](http://www.wallpaperkostenlos.com/cache/hintergrundbilder/Wasserfaelle-Sued-Amerika.-Lateinamerika_w454_h220_cw454_ch220_thumb.jpg)

更多的语法参考[kramdown Syntax](http://kramdown.gettalong.org/syntax.html)。


