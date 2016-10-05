---
layout: post
title:  "Node开发掉坑记"
date:   2015-08-14 13:00:00
author: fadeer
categories: 工作
tags: Node 
---

最近做了些Node的开发，其中一个服务打包后，在生产环境中运行出错，所有的请求都报这个错误：

~~~javascript
...
} has no method 'send'
   at C:\a_very_deep_folder\helpers\express4\express4.js:1:1945
   at Layer.handle [as handle_request] (C:\a_very_deep_folder\node_modules\express4\lib\router\layer.js:95:5)
   at trim_prefix (C:\a_very_deep_folder\node_modules\express4\lib\router\index.js:312:13)
   at C:\a_very_deep_folder\node_modules\express4\lib\router\index.js:280:7
...
~~~

找到出错的位置:

~~~javascript
app.use(function (error, req, res, next) {
	if (!error){
		res.send(404);
	}else{
		console.error(error.stack);
		res.send(500);
	}
});
app.all('*', function (req, res, next){
	//business
}
~~~

一看这是send无效啊，正好最近express升级到v4，可能跟这个有关，看看其他正常处理函数都是3个，这前面怎么还有个error，一定有问题，去掉！这样改，程序不出错了，能正常返回404。但是实际运行时express还会会有个警告：

~~~javascript
express deprecated res.send(status): Use res.sendStatus(status) instead helpers\express4\express4.js:105:9 
~~~

看来还是Express4有更新，改用sendStatus吧。

但是，不对啊，这光进404嘛意思，没进我注册的业务函数啊（应该通过app.all调用的）。想想Express4的逻辑，处理函数是按app.use、app.all的实现顺序来确定依次执行顺序的，如果一个处理函数不再调用next()，那一个对请求的处理就完成了。这里请求都被app.use响应了，如果把app.use放在app.all之后，那就正常了；试了下，果然可以。

我是不是做错了什么
----
但是细琢磨，这也不对啊；之前的代码都是跑过的，没遇到这么严重的问题啊；在本地运行一下也挺正常，根本没进原来4个参数的app.use；而修改过的3个参数的就每次都进，这什么情况，难不成express还带解析传入函数参数个数的？然后做了下测试，果然app.use有1~3个参数时，都会被执行，4及以上，就不会调用到了，会直接调用后面的app.all。

嗯，express有猫腻，来看看代码，router/index.js是它添加注册函数的地方：

~~~javascript
//express4/lib/router/index.js
var layer = new Layer(path, {
      sensitive: this.caseSensitive,
      strict: false,
      end: false
}, fn);
~~~

每个函数会实例化成为一个Layer，大概处理函数层次的意思。这里path就是注册响应的url路径，比如“/api/user”之类的，如果不传就是“/”，全部匹配了，因此前面的app.use就拦截了所有请求，都404了。再看看Layer的逻辑：

~~~javascript
//express4/lib/router/layer.js
Layer.prototype.handle_error = function handle_error(error, req, res, next) {
  var fn = this.handle;

  if (fn.length !== 4) {
    // not a standard error handler
    return next(error);
  }
	// call fn()
}
Layer.prototype.handle_request = function handle(req, res, next) {
	var fn = this.handle;

	if (fn.length > 3) {
	// not a standard request handler
	return next();
	}
	// call fn()
}

//express4/lib/router/route.js
if (err) {
  layer.handle_error(err, req, res, next);
} else {
  layer.handle_request(req, res, next);
}
~~~

这里有两个处理函数，正巧是我怀疑的3、4个参数的判断，是通过function.length属性（这个不错啊，又学到了，从哪个版本开始支持的？）来判断的。实际上3参数是注册的正常处理函数；4参数是注册的错误处理函数。那这个明白了，原来代码的逻辑没什么问题，app.use完成的是最后错误兜底的工作。

可是，那还有什么区别呢？这又是**在我机器上就没事儿**的经典状况。正常Release打包，我们都会用混淆工具UglifyJS2来缩减一下代码体积，那跟这个有关系么？来看看处理后的app.use函数：

~~~javascript
...
n.use(function(e,r,s){e?(console.error(e.stack),s.send(500)):s.send(404)})
...
~~~

这又是什么情况，原来的4个参数变成了3个参数；就是说**把本来的错误处理函数被改成了正常处理函数**，所以会出现最开始的错误。但是UglifyJS2为什么这么干，难道就因为第四个参数没用上么，这不地道啊？

寻找问题真正的原因
----
<!--preview-end-->
来，上[UglifyJS2的github页面][ujs.git]看看，看有人遇到这问题么、是不是改了，哪版改的。Issue里果然有发现：

[Broken function.length if last argument is unused. #188][issue188]，这遇到了跟咱同样的问题，通过function.length判断变量个数，但是无用的参数被截掉了。这个issue从2013年4月就开始讨论了：

* 正方（认可这个issue的用户）的观点是，做混淆不应该影响我业务逻辑啊。
* 反方（项目程序员？呵呵）的观点是，你这个function.length不是典型用法啊，我混淆还会改动函数名称呢，你难不成还用function.name做判断么？得举出更有说服力的例子才行。
* 正方给出了实际业务的用法、还有一个业务框架遇到的困境，判断函数参数在框架类代码里比较常见，终究所作的保护要比较多，function.length是比较方便的属性，而且也是JS语言标准之一。

期间还有反方逻辑不严格被正方抓出错来的，哈哈。然后这个问题在2014年以增加一个扩展参数来处理掉了，[这个Commit][fixargs]：

> Add option `keep_fargs`.
> 
> By default it's `false`.  Pass `true` if you need to keep unused function arguments.
> 
> Close #188.
> 
> master (#1)  v2.4.24 … v2.4.13
> 
> mishoo authored on 8 Feb 2014

但是UglifyJS2的老大@mishoo（主程？）还是觉得这是个别情况，因此参数默认是不开启的。

> I added a compressor option for it. To keep unused function arguments, pass keep_fargs: true to the compressor, for example:
> 
> `uglifyjs file.js -m -c keep-fargs=true`
> 
> I still believe that relying on this “feature” is silly, so it's disabled by default.

再看一下咱用的UglifyJS2是2.4.14，那也加上这个参数用就好了。但是这事儿还没完，其实还有另外一个Issue讨论同样的问题，[Removing unused arguments should be classed as unsafe? #121][issue121], 始于2014年2月。这里不依不饶的人更多，今年开始的讨论也更多了。直到正方@sc0ttyd给出了一个常用模块Lodash遇到的问题，而且是非function.length的例子。这终于开始能打动开发者了。

期间还扯到是不是做下代码的深度分析，显然谁都觉得这不太经济。最后，@mishoo在今年3月给出了[这个Commit][fixkeep]：

>  Keep unused function arguments by default
> 
>  Discarding unused function arguments affects function.length, which can lead to some hard to debug issues.  This optimization is now done only in "unsafemode".
> 
>  Fix #121
> 
>  master (#1)  v2.4.24 … v2.4.18
> 
>  mishoo authored on 20 Mar

不裁剪函数变量成了默认逻辑，这样用起来就更方便了；如果用户清楚自己的代码，还是可以主动用unsafe的方式，继续裁剪无用变量。这个补丁从2.4.18开始，那我们就把UglifyJS2升级到2.4.24好了。

思考
----
然后咱回过来看看整个事件分析处理的过程，我一开始也在很粗糙的以为根据字面的错误提示，改改代码就过去了，但是引发了更严重的问题。就像这漫画的效果赛的：

![](http://7xkxri.com1.z0.glb.clouddn.com/fix_bug.png)

图片来源: [Sina App Engine官方微博](http://www.weibo.com/saet)
{: .source}

但是最终还是要去理解代码的含义，不能有侥幸心理。

那再来看看UglifyJS2上关于裁剪函数无用变量的讨论，过程很曲折，甚至显得有点儿扯淡是不是；但其实一点儿也不，这是一个特别正常的讨论过程，这就是软件开发。要让大家对一个功能点的逻辑有共识，确实是很困难的，特别是这边界还在不断发展中的。上面这俩Issue都是2013年初开始的，那时function.length大概还是比较新的特性、使用的人、场景、意义还不显得很大；但是到了2015年看来，可能就完全不一样了。

嗯，有空我也得翻翻自己项目的边界了。

[ujs.git]: https://github.com/mishoo/UglifyJS2
[issue188]: https://github.com/mishoo/UglifyJS2/issues/188
[issue121]: https://github.com/mishoo/UglifyJS2/issues/121
[fixargs]: https://github.com/mishoo/UglifyJS2/commit/ef2ef07cbd945c7a6456adedc413858145a9ed10
[fixkeep]: https://github.com/mishoo/UglifyJS2/commit/ecfd881ac6f4f62b5e8a15664fccc86271c0d003









