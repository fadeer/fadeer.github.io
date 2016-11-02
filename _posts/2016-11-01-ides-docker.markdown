---
layout: post
title:  iDES 项目中的 Docker 实践
date:   2016-11-01 22:00:00 +0800
author: fadeer
categories: 工作
tags: Linux Docker Windows
---

> 这篇源自一个公司内部的技术分享，讲稿PPT只包含梗概的条目，于是还想把讲解的说明记录下来。另外，也需要一个知识树，随着实践、理解的增加而不断扩充。

Docker化的iDES服务
---- 
Docker这个工具其实关注很久了，容器技术在很多公司已经使用的很普遍了，但是在我们的项目里还没有机会涉及；一直也想找个场景，那就先来看看项目的现状如何。

iDES的基本服务包括Manager Service、Gateway Service和Database，大致的环境要求是：

* Manager Service：Tomcat 5、JRE 5、Redis
* Gateway Service：Tomcat 7、JRE 7、Guacamole
* Database：Postgresql

这些服务都跑在一个Ubuntu 14.04的虚拟机上，所有依赖环境都预先部署到一个vhd上（基础架构服务是基于Hyper-V的）。后来要增加一个Monitor Service，又会引入这些环境依赖：

* Monitor Service：memcached、django、nodejs、nginx

所以此时，基于预定义vhd基础环境的机制就有些麻烦了，那**目前的痛点**有什么：

* 如果不断增加新服务，那么环境依赖就会越来越多，这些是手动操作保存在**二进制的vhd**里的，只靠（不及时的）文档保存操作步骤；遇到大的版本更新时，**重做的负担和出错概率较大**。
* 不同**服务的依赖**可能遇到**冲突**，比如Monitor Server默认使用的nginx 和 iDES要增加自己的nginx，如何合并配置？
* 自定义的服务都会要部署自己的代码，新版的**上线和回滚步骤繁琐，容易出错**。
* 每个服务都会有自己的配置和运行产生的**用户数据**，目前**备份和恢复**是以vhd为单位的，**效率比较低**。
* 而上述很多步骤都没有工具化，**依赖于操作者的经验、熟练程度**；经验的转移风险大、易出错。

> 别笑，我们这项目很原始的。

变化在我真正开始搭建Monitor Service的时候，这是基于Graphite+Statsd的监控服务，就是原始Python那套实现。现成的部署过程很容易找到，但是看步骤太多就琢磨是不是有现成的可以借用。这时就翻到了Hub上的[hopsoft/graphite-statsd](https://hub.docker.com/r/hopsoft/graphite-statsd/)，心想着如果能顺便用上一直关注的Docker也不错。

于是，第一个Docker化的服务就这样：

~~~bash
# 安装 Docker Engine，详见[Install Docker Engine](https://docs.docker.com/engine/installation/)
$ curl -sSL https://get.docker.com/ | sh

# 获取镜像，运行服务
$ docker pull hopsoft/graphite-statsd

$ docker images 
REPOSITORY                 TAG      IMAGE ID       CREATED        SIZE
hopsoft/graphite-statsd    latest   c39664f3d4e5   3 months ago   720.6 MB

$ docker run –d --name graphite --restart=always \
             -p 80:80 -p 8125:8125/udp -p 8126:8126 \
             hopsoft/graphite-statsd
 
$ docker ps
CONTAINER ID  IMAGE                           COMMAND         CREATED     STATUS      PORTS   
b7d21accb9c0  hopsoft/graphite-statsd:lastst  "/sbin/my_init" 4 days ago  Up 4 days   80/tcp, 8125/udp

# 看运行起来的服务进程、监听端口
$ ps -aux | grep nginx
root    20646  0.0  0.0   4248    76 ?        Ss  Oct08   0:00  runsv nginx    
33      20661  0.0  0.0 131156  6108 ?        S    Oct08  12:56 nginx: worker process 
34      20662  0.0  0.0 131128  6304 ?        S    Oct08  13:14 nginx: worker process 

$ netstat -nlp 
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name 
tcp6       0      0 :::80                   :::*                    LISTEN      20587/docker-proxy 
udp6       0      0 :::8125                 :::*                                19503/docker-proxy 
~~~

跑个服务就这么省事儿，但是我感触最深的还是来自Dockerfile：

~~~bash
FROM phusion/baseimage:0.9.18
MAINTAINER Nathan Hopkins <natehop@gmail.com>

RUN apt-get -y update\
 && apt-get -y upgrade

# dependencies
RUN apt-get -y --force-yes install nginx python-pip memcached sqlite3 nodejs

# python dependencies
RUN pip install django==1.5.12 python-memcached==1.53 django-tagging==0.3.1 ...

# install graphite
RUN git clone -b 0.9.15 --depth 1 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web
RUN python ./setup.py install
ADD conf/opt/graphite/conf/*.conf /opt/graphite/conf/

# install whisper
# install carbon
# install statsd
# config nginx
# init django admin

EXPOSE 80 2003-2004 2023-2024 8125/udp 8126
VOLUME ["/opt/graphite/conf", "/opt/graphite/storage", "/etc/nginx", "/opt/statsd", "/etc/logrotate.d", "/var/log"]
WORKDIR /
ENV HOME /root
CMD ["/sbin/my_init"]
~~~

我看着这个Dockerfile的内容啊，第一个念头就是，这我也能写；因为这就是每个服务手动部署的过程嘛，**RUN**里面的多么直白。完整Dockerfile规则参考[文档](https://hub.docker.com/r/hopsoft/graphite-statsd/~/dockerfile/)。

然后build一下就可以自己构建出之前从hub上拉下来的镜像了：

~~~bash
$ docker build –t ides/monitor:1.0 .
~~~

所以Dockerfile的这个形式带来了几个好处：

* **可版本化的服务环境定制经验**(Dockerfile本身)，依赖的调整都能从代码的变化看到。
* **可自动化的环境服务构建过程**(`docker build`)，不用在怕手动犯错了。
* **可自动化的服务上线**（`docker run`），而且很多服务参数是从命令传进去的。

下一步就是尝试写写Dockerfile，看看iDES的现存服务是不是可以顺便Docker化。这事儿大概干了两周多，第一版的5个服务就跑起来了，第五个是前面盖了自己的Nginx。因为模仿自hopsoft/graphite-statsd，我们也使用了phusion/baseimage:0.9.18作为基础镜像。**这一轮Docker化，给项目的部署和稳定带来了可见的好处**：

* **用户数据备份与恢复 ~5分钟**，备份就是打包所有数据卷（都在/opt/ides下）然后拷走，恢复就是解压覆盖。
* **单一服务版本升级 ~2分钟**，新版Image都可以提前拷贝，升级就是（docker）stop、rename、run新版。
* **批量服务升级 ~5分钟**，脚本化而已。
* **批量服务回滚 ~10分钟**，比上面多个恢复数据的时间。
* 基于SVN，**从0构建可运行的服务 ~2小时**，这其实是最重要的好处。从0是指，只依赖可以公开下载到的资源（ubuntu iso、hub上的镜像、第三方项目预打包或者源代码），可以不依赖与人的操作，自动化构建出并运行出可以向用户提供的服务的实例来。
 

容器机制及相关项目 
----
我理解的**容器**是什么？先来看个图： 

<!--preview-end-->

1. Physical Server，我们常见的**物理服务器**，硬件、操作系统、运行环境、业务应用，这是服务跑起来需要的几层。我理解的容器是这些层都在被标准化、接口化。
1. 应用容器，比如常见的JVM、Web容器等；这大约是把业务应用对环境的依赖抽象起来，形成了一致的接口，托管应用的运行和整个生命周期；其实类似的还有浏览器。这个大约**应用运行环境容器化**。
1. 应用操作系统，这是特别针对某一特定类型的应用，专门构建的操作系统；这样可以减少通用操作系统为了混杂运行多种业务带来的额外负担，提高单一应用的运行效率。这里的例子是[OSv](http://osv.io/)，它专门运行Java和C的程序，虽然不确定支持场景有多少，但是看到这个项目时还挺新鲜的。这个大约是**单一应用类型系统容器化**。
1. 虚拟机，就是随着硬件效能越来越高，构建相互隔离的虚拟机来分享物理能力的模式了。Vmware、Hyper-V、Virtualbox是最常见的例子了。这就是**物理机器的容器化了**，这个模式可行和高效的基础是CPU虚拟化指令、PCI-E虚拟化支持等技术的发展。
1. 应用容器化，对于很多实际的项目来讲，不一定只依赖于Java这单一类型的应用，通常会混杂很多不同的服务实现；另一反面，基于虚拟机的部署，多个操作系统也带来了不必要的负担，这时Docker这种轻量化的应用容器就比较合适了。容器化模式的产生，还是依赖于操作系统的发展，这当然是从Linux开始的。
1. 上面这些容器模式的包装都还是软件层面的，而物理层的尝试则是**服务器的资源池化**，这通常以机柜为单位来实现。从每台服务器来讲，当应用虚拟化之后，真实负载对物理能力的要求通常会有区别，运算能力（cpu，内存），IO能力（磁盘），网络能力（网卡）的比例是不同的；即便在超融合架构那样的模式下，也会有物理能力浪费的情况。如何根据应用的需求来调整物理能力的匹配，则是数据中心里用好每一分钱的重要话题。所以，目前发展的PCI-E交换、甚至新出来的[Gen-Z Consortium](http://www.anandtech.com/show/10751/gen-z-consortium-formed-developing-a-new-memory-interconnect)都在向这个目标来努力。我们看到的每个物理服务器，都不再限制在一个1U、2U的盒子里了，而是根据需要动态连接起来的，那么这个服务器也就是一个容器了。
1. 再进一步呢，我只是猜测，随着物理硬件的发展，我们未来有机会为每一个应用构建一个足够精简的容器；这个应用所依赖的运行环境、操作系统、物理能力都是被恰好配置的，不多也不少，甚至可以在运行中动态变化。这个容器也许可以叫做**正合适容器**。

如果比较上面这些容器（无论是否牵强），大约可以看到这些共同点。

* 抽象出**标准化、接口化**的一个壳子（容器），支持内部业务的运行。
* 因为接口已经标准化，**内部业务不需要关心外部的实现**（可以跟旧模式不同）过渡期通常可以不经修改就直接在容器里运行，比如开始的虚拟机、现在的容器应用。
* 通常**业务不关心是否运行在容器里**；但是，如果内部业务知道运行在容器里，总有些快捷的方式提高效率，比如所谓半虚的虚拟机。
* 因为接口标准化，业务对外部的**依赖通常会抽象为一些能力**（计算，IO），而这些能力的消耗通常可以计量。
* 随着实现技术的发展，**能力的提供就可以做到灵活的配置**。
* 于是，这种抽象，形成了可以灵活配置、使用可计量、不关心实现方式的能力提供，就**可能形成一种服务**。比如IaaS、PaaS，于是也会有C（Container）aaS。

那么再回到Docker的容器方式，这可行性都**源自Linux内核的发展**，所以我们看看Linux容器基础技术，有这几方面。

* Namespace 进程隔离 
* Cgroup 资源控制 
* Union FS 分层镜像 
    * AUFS 
    * OverlayFS 

> 这原理部分还没真的上手过，还是直接看酷壳上几篇分享吧，[Linux Namespace（上）](http://coolshell.cn/articles/17010.html)，[Linux Namespace（下）](http://coolshell.cn/articles/17029.html)，[Linux CGroup](http://coolshell.cn/articles/17049.html)，[Linux AUFS](http://coolshell.cn/articles/17061.html)，[Linux DeviceMapper](http://coolshell.cn/articles/17200.html)。了解了机制，你甚至可以自己实现合用的容器工具链了。

**Docker项目本身涉及的组件有**：

* Docker **Engine**，支持容器镜像、实例管理的基础服务，比如前面用到的，`docker build`, `docker run`，和 Dockerfile。 
* Docker **Machine**，Docker环境的配置工具，通常我们需要一致化Docker基础环境就需要这个组件。
* Docker **Compose**，Docker的本地编排工具，因为通常一个业务会有多个服务（实例，镜像）构成，通常会有一致的生命周期，那么就可以一起定义（services.yml）来运行，这个目前没有实践。 
* Docker **Swarm**，Docker的多节点管理、编排工具；值得在iDES的未来用一用。
* Docker **Hub**，公开托管镜像的服务，前面拉过来的基础镜像都来自这里。
* **Enterprise**，Docker作为商业公司，做企业服务的部分。
 
> 更多可以参考：[官网](https://www.docker.com/)，[文档](https://docs.docker.com/)，[源码仓库](https://github.com/docker/docker)，[镜像仓库](https://hub.docker.com/)。

我们初期搭建Docker运行环境是，第一个想法还是Ubuntu + Docker Engine的方式。但是，这样忽略了Docker服务本身的依赖要求，由一个异地部署的机会，我们就用上了CoreOS，这也是关注很久没得机会用用的项目。**CoreOS作为一个专门的容器化运行平台**，包含这些组件。

* 以Gentoo Linux为基础, Linux 4.7+，较新的内核才能保证Bug修改和新特性的支持。 
* **Docker Engine**，显然目前要用上的。
* **Rocket**，另一个竞争的容器项目，同时也跟Docker定义了不同的镜像标准。关心区别和比较的可以看看[rkt vs other projects](https://coreos.com/rkt/docs/latest/rkt-vs-other-projects.html)。
* **etcd**，一个分布式Key-Value数据库，被好几个容器集群项目使用。
* **clair**，安全方面组件。
* **flannel**，分布式网络实现。
* **cloud-init**，CoreOS自身配置工具，可以提供一个Cloud-Config的用户配置，就可以完成机器名、静态IP、服务运行状态、添加默认账号等方面的定义。iDES用这个为天津、重庆、上海的部署写几个配置文件就好。

CoreOS预打包的发布形式有iso、vhd、vmdk，也在AWS，Azure上有现成的镜像可用。 

> 更多信息参考：[官网](https://coreos.com/)，稳定版镜像[下载](https://stable.release.core-os.net/amd64-usr/current/)。

Kubernetes，这应该是大型容器集群编排工具的第一选择了，就像Linux的容器实现很大程度得益于Google的贡献；Kubernates也是来源于Google内部的容器管理Borg。虽然目前iDES没用上，还是必须要了解的。

我理解，容器化的服务被抽象为：服务=（节点+镜像+数据+运行参数+服务IP端口）*组合，于是，每个元素的管理和组合的实现就是编排的意义了。同类竞争的项目还有Apache的marathon/mesos（更不懂，待补课）。

参考：[官网](http://kubernetes.io)，[插画版Kubernetes指南](http://www.codeceo.com/article/kubernetes-guide.html)。

前面提到了，标准化的容器抽象会产生基于容器的服务，这就是CaaS（Container-as-a-Service，容器云）

* 提供容器云最自然的就是现在的IaaS服务商，比如Azure、AWS、Aliyun，简单来说内置Docker Engine的VM都能算作这种。
* 当然更彻底的是独立的容器服务商，比如DaoCloud、网易蜂巢这类的。

而作为服务商，通常也会提供自有Hub托管和API，用于跟用户自己的运维流程、服务编排工具相结合。这个话题目前没有实践，就不展开了。

回顾上面容器的产生，和围绕在周围的项目，我们可以大致回顾一下容器的生态： 

* 引擎，运行环境，镜像标准 
* 编排工具 
* 操作系统 
* 镜像仓库 
* 云服务商 
* 监控  


IDES项目中的实践
----
在第一版之后，随着使用中的理解，iDES总结了一些实践经验吧。

**使用phusion/baseimage代替标准的Ubuntu**

好吧，这个一开始为了图省事，借用前面Graphite-Statsd镜像的构建方式。但是后来了解一下也是比较合适的。完整的思考可以参考项目的[github](https://github.com/phusion/baseimage-docker)，这里写两个iDES的角度：

* 微服务，iDES的Docker化没有特别彻底的微服务化，manager里包含了3个必要的小服务，这必然涉及Container内启动多服务的管理，phusion用的runit还比较好用。
* 对比Offical/Ubuntu，虽然官方镜像小不少，但是附加基础支持又是一份经验，先借助一个拐棍比较好。

那么[phusion/baseimage](https://hub.docker.com/r/phusion/baseimage/)做了什么呢？

* 基于Ubuntu LTS，开始的0.9.18是14.04.4，后来更新了0.9.19就是16.04了。
* runit，轻量的服务管理，参考[runit](http://smarden.org/runit/)，[runit 快速入门](https://segmentfault.com/a/1190000006644578)。
* cron，定期任务
* syslog-ng，日志服务
* logrotate，日志定期压缩，这个用上了，挺方便。
* setuser，0.9.19引入的，代替了sudo（因为Container里默认交互用户就是root了），升级到0.9.19时主要耽误在这个变化上了。

**Dockerfile**

这部分优化核心策略都是为了减少最后打包镜像的容量和速度（尽量使用Cache），也一定程度提高运行时的IO效率。
 
* 减少镜像层 和 层内文件
    * RUN 按照组件合并
    * RUN 内部先加后删
* 项目内尽量公用镜像层，利用Cache
    * FROM，MAINTAINER
    * RUN 语言设置
    * RUN 系统升级、附加软件（net-tools、ping…）
* 其他
    * COPY 代替 ADD，因为ADD有默认解压缩的功能，除非已知需要，否则默认COPY就好。
    * LABEL 增加镜像内标签，因为平时所见的tag都可以任意添加，为了避免错误，还是在镜像内增加一些名称、版本、日期等信息为好。

另外参考：[官方参考](https://docs.docker.com/engine/reference/builder)，[Dockerfile 最佳实践](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices)，[Understand images, containers, and storage drivers](https://docs.docker.com/engine/userguide/storagedriver/imagesandcontainers)，[Select a storage driver](https://docs.docker.com/engine/userguide/storagedriver/selectadriver)。

然后，通过Dockerfile做好的镜像就要拷贝到生产环境了，之前一直使用Save/Load的方式：

~~~bash
ssh test@docker-builder "docker save ides/manager:$Ver_Manager" | docker load
~~~

而这种方式没有享受到镜像层共享的好处，每个都需要完整传一遍。这时就顺便用上了**私有仓库（Registry）**。私有仓库也是一个服务，当然也会是容器化的，用起来这样：

~~~bash
# 运行仓库服务
docker run -p 5000:5000 -v <HOST_DIR>:/tmp/registry-dev registry

# 上传服务镜像到私有仓库
docker push $itc_registry/ides/gateway:$Ver_Gateway

# 运行环境从仓库获取新版服务
docker pull $itc_registry/ides/gateway:$Ver_Gateway 
~~~

当然，这默认是个不安全的仓库，需要Engine例外允许。更多配置参考[Hub Registry](https://hub.docker.com/_/registry/)。

**从Ubuntu到CoreOS**，这个意义上面已经说过，这里展开一下给iDES部署带来的变化。

* 之前手动构建基于Ubuntu 14.04和Docker的基础vhd有2.2G，而CoreOS 1068.8.0的vhd只有0.9G。
* 而且CoreOS实际包含了两份系统，可以安全的完成升级、回滚过程，提供了更好的健壮性。
* Ubuntu默认的存储镜像是AUFS，而CoreOS默认是overlay。好吧，这个没改属于犯懒。
* Ubuntu是的环境初始化还是手动的，而CoreOS就可以用上Cloud-Init来配置系统了。

这里举个Cloud-Config的例子：

~~~yaml
#cloud-config
users:
  - name: "ides"
    passwd: "加密串"
    groups:
      - "sudo"
      - "docker"

coreos:
  units:
  - name: settimezone.service
    command: start
    content: |
      [Unit]
      Description=Set the time zone

      [Service]
      ExecStart=/usr/bin/timedatectl set-timezone Asia/Shanghai
      RemainAfterExit=yes
      Type=oneshot
  units:
  - name: docker.service
    drop-ins:
      - name: 50-insecure-registry.conf
        content: |
          [Service]
          Environment='DOCKER_OPTS=--insecure-registry="127.0.0.1/8"'

write-files:
  - path: "/etc/systemd/network/static.network"
    permissions: "0644"
    owner: "root"
    content: |
      [Match]
      Name=eth0

      [Network]
      Address=192.168.79.121/23
      Gateway=192.168.79.1
      DNS=192.168.1.10
      DNS=192.168.1.11
      Domains=no.domain
      NTP=192.168.1.11
      NTP=192.168.1.10
~~~

生效只需要执行：

~~~bash
$ sudo coreos-cloudinit --from-file=/home/core/cloud-config.yaml
~~~

Cloud-init也是个非常好的工具，会作为云服务节点的初始化工具，更多可以参考：[Using Cloud Config](https://coreos.com/os/docs/latest/cloud-config.html)，[Cloud-init](http://cloudinit.readthedocs.io/en/latest/index.html)。

这里，再从iDES项目的角度，总结一下**服务容器化的工程意义**：

* 隔离服务之间的环境要求。
* 脚本化服务镜像打包，系统、依赖、程序。
* 精细化看待服务的 最小依赖、配置、运行参数，适应不同业务。
* 简便的用户数据备份与恢复。
* 脚本化的服务升级与回滚。
* 可追溯、可升级的构建、部署经验；不依赖于工程师个体的经验。
* DevOps的趋势，在开发阶段就考虑服务部署。 
* 从提交 到 线上系统更新；只要SVN在，一切回得来。


Docker的应用场景与奇怪玩法
---- 
接下来就是轻松点儿的话题了，来看看什么场景会用是用上Docker，或者更准确的说是会用上容器。
 
**微服务** 

借用一下[Wiki上的](https://zh.wikipedia.org/wiki/%E5%BE%AE%E6%9C%8D%E5%8B%99)描述，微服务是一种**软件架构风格**，它是以专注于单一责任与功能的小型功能区块为基础，利用模组化的方式组合出 复杂的大型应用程序，各功能区块使用与语言无关的 API 集相互通讯。

所以，微服务只是一种风格，不是必然的趋势；服务的粒度总跟很多情况有关。但是Docker确实支持微服务/服务化好用的工具，因为：

* Docker便于隔离服务，减少服务迭代的影响；一个服务的实现可以从一个语言、框架换成另外一种，不会影响别的服务运行。 
* Docker便于服务粒度的调整，如果以微服务为方向做尝试，服务拆分或者合并都可以方便很多。  

**DevOps** 

[DevOps](https://zh.wikipedia.org/wiki/DevOps)就是Development + Operations的组合，主要内容是 透过自动化“软件交付”和“架构变更”的流程，来使得构建、测试、发布软件 能够更加地快捷、频繁和可靠。

从iDES应用Docker相关工具的变化也可以看出，Docker带来的脚本化、自动化、构建、部署经验版本化的好处，确实符合DevOps的一些基本要求。希望能在未来的项目里，更多地实践这个理念。

**远程机器的目标状态管理**

但凡有多节点的环境统一管理，运行业务的一致化要求是，就会有这样的场景产生；比如桌面环境的管理、服务器环境配置管理等。后来看微软直接把这个业务称作“其他状态的配置（Desired State Configuration）”，更加直白了。

这类工具从传统的Chef、Puppet、Ansible、Saltstack，到微软视图统一Windows、Linux的[PowerShell DSC](https://msdn.microsoft.com/en-us/powershell/dsc/overview)，都是这个领域的。而从服务的角度看，Docker的容器编排。

> 之所以单列出这节，是因为未来考虑在树莓派节点上使用Docker来管理上层服务，等有更多实践时再做补充。


**容器化桌面应用**

我们通常通过容器运行起来的业务负载都是服务类应用，不需要图形显示；那Linux下的桌面应用是不是可以容器化呢？其实一次Docker大会上就有人做这样的演示，其实是得益于X协议的机制，图形程序只要连接上可输出的Xserver，就可以看到应用内容了。我也实践一下，使用的环境就是树莓派。

* 树莓派跑的Docker Host系统不再是Ubuntu了，也没有用默认的raspbian，而是直接使用了[HypriotOS](http://blog.hypriot.com/post/releasing-HypriotOS-1-0)，这是一个预打包的Docker运行环境，类似于CoreOS的工作。
* 然后在基础系统上配置习惯的桌面环境，我还用Openbox。
* 基础镜像使用[resin/rpi-raspbian:jessie](https://hub.docker.com/r/resin/rpi-raspbian)，这就是一般的基础系统了，不像phusion/baseimage管那么多事儿。
* 然后就是Chromium的Dockerfile和打包镜像了，跟平时定制没什么区别。
* 关键就是如何启动这个桌面容器实例了，就像考虑服务的参数一样，桌面应用必须要知道的就是DISPLAY变量；另外，如果网页需要发声就还要访问Host的音频设备。

~~~bash
docker run \
    --net=host \
    -e DISPLAY=:0 \
    -e CH_APP="https://192.168.12.211/?node=abc.001" \
    -v /opt/chromium/data:/data \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /var/run/dbus:/var/run/dbus \
    -v /dev/snd:/dev/snd \
    --privileged \
    --rm \
    rasp/chromium:1.0-53.0.2785.143
~~~

于是这个桌面容器就跑起来了，关闭窗口容器实例就移除了；当然也可以像服务一样，关闭自动重启，窗口就会再打开了。

**可迁移个人工作环境**

这里的工作环境，主要是指基于Linux的开发、编译环境，包含了个人习惯（提示符、命令行环境配置、vi/emacs 自定义等），项目环境要求（基础发行版，依赖开发包等）。一个预先配置好的开发环境，有时也会成为项目中**不敢重建的黑盒**之一。而备份、复制这样的环境，见过那么几个方式：

* 基于虚拟机，一般基于项目的需求构建一个单纯的开发环境，保存一个磁盘镜像大家使用，黑盒由此而来。
* 基于Github，把个人自定义的环境打包上传到版本管理里，换一个环境可以再下载生效；这个通常在多个个人环境来使用。
* 基于Docker，可以把基础系统、环境依赖、个人定制都通过Dockerfile来生成，有任何改动只要更新Dockerfile就可以。而使用时只需要运行一个容器就可以。


Docker 后续
----
容器虽然产生于Linux领域，但是由于很快在开发、部署场合应用起来，那么在Windows、OSX环境的延伸也自然而然的了。我接触的有那么几个阶段：

**Docker on Windows/OSX**

早期Docker**移植**到Windows/OSX下的方式，因为借用了VirtualBox（得益于良好的API可管理），所以两个平台的机制比较一致。这个版本叫做[Docker Toolbox](https://www.docker.com/products/docker-toolbox)，大概机制是：

* Engine 工作 VirtualBox 的虚拟机里（显然是个Linux），是通过 Docker Machine 来部署的，因为这个虚拟机就是Docker Host的角色。
* Client/Machine/Compose 工作在 Windows/OSX 里，作为
* Image/Container 运行在虚拟机里，这个显然要跟Engine在一起；因此，VM的CPU、内存配置影响了容器实例可用资源，这都是在Docker toolbox里可配置的。

到了 Docker 1.12，MAC下开始支持了更原生的模式，就叫做[Docker for OSX](https://www.docker.com/products/docker#/mac)。大概机制是：

* 因为使用了OSX新增的轻量虚拟机框架，因此要求系统是 OS X 10.10.3 以上。
* 打包为标准的 OSX APP 包，拖放安装即可。
* 使用[HyperKit](https://github.com/docker/HyperKit)创建Docker虚拟机, 这层Host Linux（目前是Alpine Linux）是跑不了了。
* Docker Engine 暴露 API Socket跟 Client通信。 
* Docker Client 工作在 OSX 上，Image也是（待查）。 
* Engine/Container 还是跑在虚拟机里。 
* 因为HyperKit虚拟机的限制，目前不支持OSX上硬件向虚拟机的Device Passthrough，所以，如果有特别需求，还得换回Docker toolbox。

其他信息参考[官方文档](https://docs.docker.com/docker-for-mac)。

我目前就在笔记本上用这个，挺方便，速度也不错。HyperKit依赖另一个项目[xhyve](https://github.com/mist64/xhyve)，这两个以后可以多了解一下。

相对应的，[Docker for Windows](https://www.docker.com/products/docker#/windows)就更加自然了，因为Windows下很早就有Hyper-V，而且下放到Windows Client下也已经很久了。也是从Docker 1.12开始，大概机制是：

* 需要Windows 10 Pro Update 1151+、Build 10586+，开启Hyper-V角色
* Engine/Image/Container 工作在 Hyper-V 虚拟机里，显然，还是个Linux。
* Client/Compose 作为Powershell扩展，运行在Windows下。

更多信息参考[官方文档](https://docs.docker.com/docker-for-windows)。在Powershell里可以查看Docker Client和Engine的版本，工具是Windows，引擎还是Linux的：

~~~bat
Client:
Version:      1.12.1
API version:  1.24
Go version:   go1.6.3
Git commit:   23cf638
Built:        Thu Aug 18 17:32:24 2016
OS/Arch:      **windows/amd64**
Experimental: true

Server:
Version:      1.12.1
API version:  1.25
Go version:   go1.6.3
Git commit:   23cf638
Built:        Thu Aug 18 17:32:24 2016
OS/Arch:      **linux/amd64**
Experimental: true
~~~

但是，作为一个Windows，只能看着Docker使用自己的虚拟机跑Linux容器负载，这情何以堪，纠结啊。终于，微软在2016年9月底的Ignite大会上发布了[Windows Container](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/containers_welcome)，终于开始好玩儿了。这个支持Windows容器的机制是：

* 基础环境需要 Windows 10 Anniversary Update 或者Windows Server 2016。
* 容器分为两种，一个是[Hyper-V Containers](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/management/hyperv_container)
    * 大概用到了轻量虚拟化技术，而且要跑在虚拟机里完成，所以Windows增加了**嵌套虚拟化**支持（ExposeVirtualizationExtensions）。VM里再跑VM这个玩儿法，最早见于Vmware Workstation，可以在虚拟机里再安装ESXi那一套，构建一整套虚拟化实验环境。
* 另一个是Windows Server Containers
    * 这就更接近与Linux支持容器的机制了，容器实例和Host Windows 共享 Windows Kernel，也有namespace、resource control、process isolation等机制。
* 既然是Windows的容器，那么基础镜像也得是Windows啊，微软已经在Hub上发布了常见的服务镜像，基础的有microsoft/windowsservercore 和 microsoft/nanoserver。
* 基于Dockerfile构建镜像的过程也没有变，只不过[bash会变成powershell](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/docker/manage_windows_dockerfile)。额外的话题是，目前Windows管理的第一入口，似乎已经从GUI切换到脚本化的PowerShell了。

跑起来，看，引擎已经变为Windows了：

~~~bat
Client:
Version:      1.12.1
API version:  1.24
Go version:   go1.6.3
Git commit:   23cf638
Built:        Thu Aug 18 17:32:24 2016
OS/Arch:      **windows/amd64**
Experimental: true

Server:
Version:      1.13.0-Dev
API version:  1.25
Go version:   go1.7.1
Git commit:   c2debe
Built:        Thu Sep 13 15:12:54 2016
OS/Arch:      **windows/amd64**
Experimental: true
~~~

目前这些还在测试版状态，我也没有上手尝试，希望有机会试试。

除了对Linux外这两大系统的支持，Docker自己最大的特性就是容器编排的**Docker Swarm**，而且从1.12开始已经内建到Engine里了，用起来更自然了。涉及的话题有：

* Cluster，Service，Scale 
* Overlay Network，Virtual IP Address 

先看看官方的图：

《》

另外参考[概览](https://docs.docker.com/swarm/overview)、[Docker Built-In Orchestration Ready For Production](https://blog.docker.com/2016/07/docker-built-in-orchestration-ready-for-production-docker-1-12-goes-ga)、[Production-Ready Docker Swarm](http://www.slideshare.net/Docker/docker-online-meetup-28-productionready-docker-swarm)、[Get started with multi-host networking](https://docs.docker.com/engine/userguide/networking/get-started-overlay/)。跨Host网络是这里的重点，等有了具体的实践再补充。


通过Docker学到的
----
一开始，Docker只作为项目中一个可以借力的工具来使用；随着使用的深入，就开始思考如何让一个开源项目健康成长：

* 开源项目、工具、技术分享与借鉴。 
* 工程价值、生态。 
* 商业化、公司、竞争与合作。 

不妨参考一下[感觉值得引进一下国外造轮子的套路](https://segmentfault.com/a/1190000007142098)。其实项目、公司也是一个道理。


