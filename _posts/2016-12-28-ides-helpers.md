---
layout: post
title:  iDES 中使用到的开源项目
date:   2016-12-28 10:00:00
author: fadeer
categories: 工作
tags: Project Linux
---

iDES是这几年一直在参与的桌面云产品，鉴于目前已经告一段落了，来回顾一下都借助哪些现成的技术和开源项目，也许有不少在未来的项目中还能用上。这是一个基于微软虚拟化方案的桌面云产品，目前首页是这样子的：

{% include image.html name="ides-portal" %}

桌面服务
----
**管理服务**的实现使用了公司内比较成熟的一个框架，使用 [Java](http://www.oracle.com/technetwork/topics/newtojava/overview/index.html) 和 [Tomecat](http://tomcat.apache.org/) 实现的。

**数据库** 早期使用轻量的[SQLite](https://sqlite.org/)，后来换成了[Postgresql](https://www.postgresql.org/)；数据访问层是 [Hibernate](http://hibernate.org/) 和 [MyBatis](https://github.com/mybatis/mybatis-3) 混合的。**数据缓冲**还是用的 [Redis](https://redis.io/)。

对 Hyper-V **Host 的远程管理**演变比较多：

* 一开始借用了SCVMM的包装，因此通过Windows Communication Foundation （[WCF](https://msdn.microsoft.com/en-us/library/dd456779(v=vs.100).aspx)）实现的集中管理，开始托管在IIS里。
* 后来去掉了SCVMM依赖，使用[PS Hyper-V](https://pshyperv.codeplex.com/)这个封装远程管理Host，那时的主力Hyper-V 还是2008R2 SP1的。
* 然后去掉了IIS，使用 Widnows 服务直接托管 WCF 实现。
* 目前，使用 [Node.js](https://github.com/nodejs/node) 实现的服务跑在各个 Host 上，也顺便完成一些远程不方便的业务动作。

前端就是一个**单页面**的逻辑，模块化使用了 [sea.js](http://seajs.org/docs/)，后来初步引入了 [vue.js](https://vuejs.org.cn/) 来完成一些数据绑定，还没有时间深入做下去。

后期，管理服务提供了一个基于**Web访问桌面**的方式，是基于 [Guacamole](http://guacamole.incubator.apache.org/doc/gug/) 的。这些服务（包括后面的监控服务），显然都是工作在 [Nginx](http://nginx.org/en/docs/)后面的。


终端设备
----
有桌面服务就要有终端设备，最早支持的还是X86类的笔记本，客户端系统是 [Ubuntu](http://releases.ubuntu.com/14.04/)，桌面选用的是 [xfce](https://www.xfce.org/)，引导还是轻量的 [extlinux](http://www.syslinux.org/wiki/index.php?title=EXTLINUX)。后来为了支持X64的新CPU，Ubuntu换成了64位的，引导也换成了 [Grub2](https://www.gnu.org/software/grub/manual/grub.html)。为了远程管理方便，还有 [X VNC Server](http://www.karlrunge.com/x11vnc/) 的支持。为了支持系统级更新，用 [Squashfs](http://squashfs.sourceforge.net/) 包装了一下系统分区。

随着 [Raspberry Pi](https://www.raspberrypi.org/)越来越成熟，这个ARM小板也成了我们低端设备的选择，2代、3代都在使用。系统就是官方的 [Raspbian](https://www.raspbian.org/)，桌面采用了更轻量的 [Openbox](http://openbox.org/wiki/Main_Page)（lxde这层桌面工具都跳过了）。至于浏览器，显然是 [Chromium](https://www.chromium.org/Home)，只不过在 Raspbian 正式添加（2016.11）之前，是从 [Ubuntu 的源](http://ports.ubuntu.com/pool/universe/c/chromium-browser/)里挖过来的。

**桌面业务的客户端程序**，本质上也是个单页应用，早期使用的是 [AppJS](https://github.com/appjs/appjs)，后来这个项目停止维护了。在[Node-Webkit](https://github.com/nwjs/nw.js) 和 [Electron](https://github.com/electron/electron) 之间选择了后者，这也为客户端程序同时支持 Linux/Windows、x86/x64/armhf 打下了良好基础。在这个应用上，还小规模测试了 [React](https://facebook.github.io/react/) + [Redux](https://github.com/reactjs/redux) 的实现，有了一些的实战体会。

至于**连接桌面的工具**，用的是目前更新很积极的[FreeRDP](http://www.freerdp.com/)，鉴于对新 RDP 协议的支持，基本追踪 [Master](https://github.com/FreeRDP/FreeRDP) 了。

而跑在**终端设备上的管理入口**，也是 Node.js 实现的。


部署，监控和运维
----
我们的虚拟桌面使用 Hyper-V，于是早期各个管理服务也是跑在**虚拟机**上的，基础系统也是 Ubuntu。这里面包含了不少运维负担，后来接触到容器，当各个**服务都容器化**之后，部署环境就标成了 Ubuntu + [Docker](https://docs.docker.com/)。而很快又转变为了 [CoreOS](https://coreos.com/)。而**镜像库**还是暂时使用官方的 [Registry](https://hub.docker.com/_/registry/) 实现。这部分的**充分讨论请参考** [iDES 项目中的 Docker 实践](https://fadeer.github.io/%E5%B7%A5%E4%BD%9C/2016/11/01/ides-docker.html)。

监控服务的演变是这样的：

* 通过 [WMI](https://msdn.microsoft.com/en-us/library/aa394582(v=vs.85).aspx) 采集 Windows、虚拟化方面的原始数据，使用 RRD文件来保存数据，管理服务层通过 [RRDtool](http://oss.oetiker.ch/rrdtool/) 来读写监控数据。这套实现坚持了很久，因为反正也没什么人用。
* 中后期，使用 [Statsd](https://github.com/etsy/statsd) 和 [Graphite-Web](https://github.com/graphite-project/graphite-web) 实现了一套新的监控服务，采集范围也扩大到了各个终端设备、管理服务状态，但是在大客户那跑起来之后发现性能几乎不可接受，IO太高了。
* 后来，数据采集入口换成了 [statsdaemon](https://github.com/bitly/statsdaemon)，增加了区域缓冲 [carbon-relay-ng](https://github.com/graphite-ng/carbon-relay-ng)，持久化的时序数据库换成了 [influxDB](https://www.influxdata.com/time-series-platform/influxdb/)。为了延续管理服务使用数据的接口，数据和图表接口使用了 [graphite-influxdb](https://github.com/pkittenis/graphite-influxdb/) 实现的 [Graphite-API](https://graphite-api.readthedocs.io/en/latest/)。当然，为了方便调试数据，也顺便架设了 [Grafana](https://github.com/grafana/grafana)。

所以，你在前面首页看到的**桌面服务状况**，很大部分是来自于这个监控服务支持的。而表现方式严重参考了 [Azure Portal](https://azure.microsoft.com/en-us/features/azure-portal/)，只是层次和可定制性还没那么丰富。弹性布局使用了 [freewall.js](http://vnjs.net/www/project/freewall/)，很有意思的小项目。


项目工程
----
除了**代码管理**使用公司的 [Subversion](https://subversion.apache.org/)，在工程方面也有不少尝试，有些效果还不错。

**开发、用户文档**使用 [markdown](https://en.wikipedia.org/wiki/Markdown) 编写，上代码库方便版本管理和更改的比对。正式发布使用 [pandoc](http://pandoc.org/) 来转换为 PDF 格式。为了好看点儿，字体使用了 [思源黑体](https://github.com/adobe-fonts/source-han-sans)。

平时工作**散碎任务管理**，尝试使用 [Worktile](https://worktile.com/) 来追踪；后来换成了 [Tower](https://tower.im)，貌似这个更适合我们的状况。


总结
----
使用了这么多杂七杂八的项目，有一戳就倒的感觉么？哈哈。人少事儿多就只能多依赖开源工具了；只不过稍闲的时候需要多敲打一下这些拐棍，有隐患的就得补足或者换掉。


