---
layout: post
title: 关于应用程序日志
date: 2018-11-18 14:00:00 +0800
author: fadeer
categories: 工作
tags: Skill
---

## 日志的内容

日志，在我们程序开发调试、生产环境运行异常追踪、应用程序性能监控，甚至是用户行为分析等多个场景都会用到的工具。如何设计、实现**应用程序的日志机制**，来让我们及时获得必要的信息、达成的目标，是很值得讨论的话题。

日志是对事件的记录，根据我们的使用场景，不同的类型事件会包含不同的信息，记录在不同的日志文件（[Wiki: Log File](https://en.wikipedia.org/wiki/Log_file)）中。我们希望日志的内容充分而且有规则。一条日志，基本要包含这些信息：

什么时候发生的，**When**

- **日志时间**，记录日志的时刻。
- **时间戳**，事件发生的时刻，通常为了便于人工阅读，会保存时间字串来显示；在时区统一的系统里，用当地时区也便于人工使用。
- **业务 ID**，将多个事件关联起来的 ID。

在哪儿发生的，**Where**

- **应用程序信息**，比如名称，版本。
- **应用程序地址**，比如运行所在的节点，监听地址、端口等。
- **服务信息**，名称，协议等。
- **位置信息**，如果是移动终端设备，那么位置信息也是重要的。
- **路径信息**， 比如 Web 服务的请求地址，HTTP 方法。
- **代码信息**，产生事件的脚本、代码文件名称，模块名称等。

谁触发的，**Who**

- **源地址**，触发时间的来源，比如 HTTP 请求的源地址，可以关联到源设备详细信息的 ID 等。
- **用户 ID**，对于用户操作相关的事件，同时要记录操作账号的信息。

事件内容是什么，**What**

- **事件类型**，根据业务场景的特点，区分不同类型的日志，比如调试日志、访问日志等。
- **事件严重程度**，比如常见的，严重、错误、警告、信息等。
- **安全相关事件标志**，表示是否是在安全方面需要关注的事件。
- **详细描述**，事件的文字描述；通常，大量的业务信息会展开为多个属性和值。

## 日志的目标与常见类型

根据日志的不同业务场景，上述信息（特别是详细描述）会具体化为不同的内容；常见的日志及其内容，有这么几种：

### 应用运行调试日志

通常是开发者用于追溯应用的运行状况，捕获程序异常、业务异常，从而改善应用健壮性。这类日志，通常包含这些内容：

- **事件严重程度**，常见的取值是：`fatal/error/warn/info/debug/trace`。
- **程序模块/文件/行数**，便于开发者追溯到事件产生的位置。
- **业务 ID**，在微服务设计下，一个用户请求会被多个服务所处理；需要在日志里记请求的事务 ID，才能从多个服务日志中，还原请求的执行状况。
- **堆栈信息**，对于程序异常捕获，通常需要把异常的堆栈信息同时打印出来。值得注意的时，堆栈信息一般是大量的多行文字，人工识别还行，但是如何接入解析工具时需要注意的。

### 访问日志

通常是对服务访问信息，及其响应信息的记录；对于异常的访问，可能会单独记录。比如 Nginx 的[访问日志](http://nginx.org/en/docs/http/ngx_http_log_module.html)、[错误日志](http://nginx.org/en/docs/ngx_core_module.html)。

这类日志，有这些信息：

- **HTTP 请求头信息**，比如 URL 路径，HTTP 方法，发出请求的源地址、浏览器名称版本等。
- **请求内容**，具体的请求参数，内容类型，长度等。
- **请求过程信息**，比如请求的处理时间。
- **响应信息**，HTTP 返回值，响应的类型（txt、json、jpg），长度等。
- **错误信息**，针对错误日志，还会保存可阅读的错误描述文字。

### 应用性能日志

通常是是为了统计应用访问压力、处理能力、平均响应时间而保存的日志；这类信息通常有多种来源，比如上面访问日志的请求相应时间就是一个重要的来源。一条性能日志，通常会包含：

- **关注性能的对象**，我们所关注的性能信息，比如机器的 CPU，某一个业务的执行，请求的处理事件等。
- **性能对象的描述**，通常是多个维度的标签化标注，比如服务所在的数据中心、机柜、服务器、具体的服务、业务名称，甚至是函数名称。
- **关注的性能值**，比如 CPU 的使用率，业务请求的处理时间等；通常会是一个数字。

## 日志的格式

当我们整理好日志的内容，接下来就要考虑以那种格式保存下来，日志的格式的选择会受这些因素影响：

- **读者**，就是日志内容是给人看的，还是给机器看的；工整对齐的文字便于人工阅读；而结构化的格式（JSON，KeyValue Pairs）更适合机器解析。我们的日志，很可能要同时满足这两条。当然，随着人类工程师“阅读适应能力”的提高，JSON 是个不错的选择。
- **空间占用**，针对某些不希望占用过多空间，而且不考虑人阅读的业务，会使用压缩存储，或者二进制格式。

日志的格式有很多经验，也有很多现有的规则可以参考，比如：

- [Common Log Format](https://en.wikipedia.org/wiki/Common_Log_Format)
- [syslog](https://en.wikipedia.org/wiki/Syslog)
- [Extended Log Format](https://en.wikipedia.org/wiki/Extended_Log_Format)
- [Web Extended Log File Format](https://www.w3.org/TR/WD-logfile)
- [Apache Commons Logging](https://en.wikipedia.org/wiki/Apache_Commons_Logging)
- [Windows Common Log File System](https://en.wikipedia.org/wiki/Common_Log_File_System)

## 日志的其他注意事项

在日志的内容整理、持久化保存的过程中，还有一些额外的事项需要考虑。

- **过滤敏感内容**，比如用户的姓名、身份证号、银行卡号，请求的 Session ID、访问 Token，这些信息通常会包含在业务请求、响应中；我们不应该直接、完整的将这些信息保存在日志中，会造成敏感信息的泄漏。
- **高安全等级的数据**，要确保不进入一般的日志系统，需要考虑单独处理。
- **事件的后续处理**，针对某些事件、特别是异常事件，可以给出一些可操作的行动建议。
- **历史日志的压缩**，通常，我们主要关注和查看临近时间（比如 3 天）的日志；对发生一段时间（比如 2 周）的日志文件，会压缩处理来节省空间，需要时再展开查看；对历史（比如超过 2 周）的日志，就会直接删除了。这个机制叫做日志循环（[Wiki：Log rotation](https://en.wikipedia.org/wiki/Log_rotation)，）Linux 下常用 [Logrotate](https://wiki.archlinux.org/index.php/Logrotate) 来实现。

## 常见日志库

接下来，在我们具体的服务开发中，就要根据日志的内容、类型、存储形式、细节的注意事项来实现我们的日志了。一般，每个语言内建库，及其生态圈都有很多日志库的选择，一个可配置、功能全面的日志工具库可以极大的简化基础日志操作的工作，把工程时大部分精力放在恰当的描述事件内容上来。

这些库是我们经常遇到、使用的：

- Java：[Log4j](https://en.wikipedia.org/wiki/Log4j)
- Javascript/Node：[Log4js](https://log4js-node.github.io/log4js-node/)、[debug](https://github.com/visionmedia/debug)
- Go：[Package log](https://golang.org/pkg/log/)、[go-logging](https://github.com/op/go-logging)、[google-logger](https://github.com/google/logger)
- Python：[logging](https://docs.python.org/3/library/logging.html)

## 日志的集中存储与分析

现在的服务开发语境下，为了便于开发者获取和分析在众多服务节点上产生的日志，通常会对日志进行集中化处理、展示，进而考虑程序化分析。因此会有很多工具、服务做这一层面的工作。

> 服务的集中化，使得日志的“阅读”过程演变为**先机器、后人工、再机器**，这也反过来影响了日志格式的选择。

日志的集中存储，通常会考虑**采集 -> 解析/转换 -> 存储 -> 可视化**的过程，常见有这些套路：

### Windows/Linux 应用日志

- **采集**，[Beats](https://www.elastic.co/products/beats)，常用的是[Filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-overview.html)，负责监控日志目录、日志文件，将原始日志拆解成单条。如果存在多行日志（比如程序堆栈信息），要在这一层拆解对。
- **解析/转换**，[Logstash](https://www.elastic.co/products/logstash)，将每条日志解析为键值对，支持日志格式的解析
- **存储**，[Elasticsearch](https://www.elastic.co/products/elasticsearch)，分布式存储与文本搜索引擎。
- **可视化**，[Kibana](https://www.elastic.co/products/kibana)，从 Elasticsearch 里加载日志，按照索引、关键字搜索来查询日志，生成图表等。

这个过程体现了[Elastic Stack]()对日志处理的典型过程，其他日志流也有很大的相似性。

### Docker 容器日志

鉴于近几年容器化、Docker 的应用，这也是一个常见的场景；我们会把上面的工具栈稍微改造一下，用更轻量的工具替换几个组件。

- **输出**，对于传统应用直接将日志保存为文件，容器中的应用只需要把日志打印到控制台，就可以被 Docker Daemon 获得了。
- **采集**，[Logspout](https://github.com/gliderlabs/logspout) 通过 Docker API 采集容器日志，在原始日志内容的基础上，附加了容器主机、容器名称、镜像名称、版本等信息。
- **解析/转换**，[fluentd](https://www.fluentd.org/architecture)，日志管道，完成日志过滤、缓冲、路由过程，插件化支持日志输入输出的扩展。我们利用 fluentd 将日志解析、输出到存储层。
- **存储**，还用 Elasticsearch
- **可视化**，还用 Kibana。

由于容器生态的火热，其实，上面每一层都有很多选择；而逐渐演变到 Service Mesh，日志流的也有一些变化。

### 性能日志接入监控系统

讨论到应用的性能监控，通常我们会从 APM 领域展开讨论，常见到[StatsD](https://github.com/etsy/statsd)、[graphite](https://github.com/graphite-project)、[prometheus](https://prometheus.io/docs/introduction/overview/)等工具。这里，我们重点讨论，从日志（比如 Web 访问日志）挖掘性能数据的过程是怎样的。

- **采集**，这里沿用系统日志、容器日志的选择。
- **解析/转换**，我们会先从日志条目中拆解性能信息，fluentd 可以良好的完成这一工作。然后使用 [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/)，作为性能数据的管道，完成原格式（statsd）到目标格式（influx）的转换。
- **存储**，[Influxdb](https://www.influxdata.com/time-series-platform/influxdb/)，时序数据库，提供简单统计、分层存储等对性能数据常见的管理功能。
- **可视化**，[Grafana](https://grafana.com/grafana)监控领域常见到的可视化组件，支持大量常见数据源。

## 参考文章

- [How to Log a Log: Application Logging Best Practices](https://logz.io/blog/logging-best-practices/)
- [Microservices Logging Best Practices](https://blog.scalyr.com/2018/08/microservices-logging-best-practices/)，在请求与响应信息里添加唯一标识，日志的集中，结构化。
- [30 best practices for logging at scale](https://www.loggly.com/blog/30-best-practices-logging-scale/)，日志的创建、传输、管理。
- [Splunk Logging best practices](http://dev.splunk.com/view/logging/SP-CAAAFCK)
- [9 Logging Best Practices Based on Hands-on Experience](https://www.loomsystems.com/blog/single-post/2017/01/26/9-logging-best-practices-based-on-hands-on-experience)
- [Logging Cheat Sheet](https://www.owasp.org/index.php/Logging_Cheat_Sheet)

## 后记

整理这篇综述原因，是《左耳听风》学习小组的“命题作文”；这是挺好的一个机会，让自己完整地总结一下“日志”这个工作中经常遇到的话题，在讨论时都应该包含哪些内容。

> 我想，现在大概只写了 1/3，得空还要不断补充。

除了话题本身的内容，当**探索一个新概念**，或者去补充一个已知概念（比如这次）完整度时，该怎么做？也是一个有趣的实践过程，值的反复去训练。我一般会从这样的搜索开始。

一个新概念，拿“区块链”举个例子，**转换成英文去 Google 里搜索**。

- blockchain **Best Practices**，最佳实践，这是对当前经验总结的常用标题；甚至对于一些服务、工具的惯常用法，这个最佳实践很可能就出现在官方文档里。
- **awesome** blockchain，总有“好事”的程序员，去整理这个话题下有用的链接，通常还会伴随良好的分类，这个分类可以作为新概念“知识脑图”的草案。另一个选择是 “blockchain **Cheat Sheet**”。
- blockchain **startups** blog，一个概念通常代表着一个细分领域，体现了一些典型问题，也会产生一些初创公司；这些公司的开源产品可能直接为我所用，而他们在产品博客中的技术讨论，往往覆盖了领域内的一些痛点，不能忽略。

另外，从上面的探索中，我们会遇到很多大公司技术团队的讨论文章，也是补充我们知识的重要来源。
