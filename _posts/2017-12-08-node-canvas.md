---
layout: post
title:  关于 Node 渲染 Canvas
date: 2017-12-08 09:00:00 +0800
author: fadeer
categories: 工作
tags: Skill
---

昨天查了一下 **pdf 转图片**的事儿，npm 好几个库都可以做这个，大多数使用 GraphicsMagick 和 ImageMagick （node 库是 [gm](https://www.npmjs.com/package/gm)），直接解析 pdf 输出图片了，意思不大。

有趣的是 [pdf2json](https://github.com/modesty/pdf2json)，它是直接利用 Mozilla 的 [pdf.js](https://github.com/mozilla/pdf.js) 来做 pdf 解析；但是它是利用 pdf.js 的文字解析能力，调用的 getRawTextContent、getAllFieldsTypes，这类接口，见[ pdfpraser.js](https://github.com/modesty/pdf2json/blob/master/pdfparser.js)。

而 pdf.js 展示 pdf 内容是把**解析出的 page 绘制在 canvas 上**，见 [example](https://mozilla.github.io/pdf.js/examples/)。那么，如果能在 node 里**把 cavans 的内容直接转成图片**就方便了，翻了翻，就是[node-canvas](https://github.com/Automattic/node-canvas)，它的图形支持使用的 [Cairo](http://cairographics.org/)。

进一步讲，所有**基于 cavans 绘制内容的 js 库，都可能在 node 范围直接输出图片**；我想到了 eCharts。

**eCharts 的服务端渲染**？其实很多人琢磨过，翻几个 Issue：

* [可否让ECharts在Node.js服务器上跑？](https://github.com/ecomfe/echarts/issues/554)，2014 年的问题。
* [echarts是否能让后端生成图片，解决前端大规模数据时的性能缺陷？](https://github.com/ecomfe/echarts/issues/5526)
* [可以服务端生成图表png吗？](https://github.com/ecomfe/echarts/issues/2706)
* [java后台如何调用echarts动态生成图片](https://github.com/ecomfe/echarts/issues/6939)
* [echarts在服务端运行的问题](https://github.com/ecomfe/echarts/issues/4400)

eCharts 服务端出图，最大的业务点就是**生成离线报告，比如邮件报告、微信通知附加的图片**，这类不需要交互的场景。主要的路子就是两个，node-canvas 和无头浏览器，比较一下：

**无头浏览器**，比如 puppeteer、PhantomJS。好处是渲染页面的实现方式是跟已经实现的网页视图同构的，多语言、资源、配置等都一样；劣势是调用要经过完整的浏览器打开标签、加载完整页面渲染，总体耗时偏长，之前 graphite-api 那种 URL 速出图片的体验基本达不到了。目前的截图服务就是这个路子。

**node-canvas**，好处是直接在后端做 canvas 渲染和输出，速度应该好很多；劣势是要把实现从网页试图中抽取出来（服务端渲染都免不了这个分解过程），如果有多语言话题还要另外思考一下。

可参考的项目就是 **node-echarts**，直接看[代码](https://github.com/suxiaoxin/node-echarts/blob/master/index.js)吧；这么简单的封装就别引用了，自己借鉴做接口吧。同类型的还有 [chartjs-node](https://github.com/vmpowerio/chartjs-node)。

再进一步，在 node 范围内，完成对网页的一些解析、转换、处理也是有趣的话题，比如一些库：

* [jsdom](https://github.com/tmpvar/jsdom)，用量很大啊？
* [cheerio](https://github.com/cheeriojs/cheerio)，更轻量，貌似陈龙他们用过？

以上，都是**前端**。





