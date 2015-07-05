---
layout: post
title:  "有关ARM编译环境"
date:   2014-12-19 10:19:00
categories: Linux ARM
---


原始知识
----
构建ARM执行档、内核的编译运行环境，之前理解有这么两种：

**交叉编译环境**，一般开发板都会提供一个工具包（ToolChain），包含支持编译ARM架构的GCC、基础库，有的还有源码包用来编内核、驱动。用户编译自己ARM版的执行档，配置使用ARM的GCC就行。这样的环境弹性不大，当用户要使用某社区Linux和内核时，就要自己来构建这个工具链，甚至要先编译一个ARM版的GCC。这个方法没有实际使用过，所以描述可能不准确，基本原理是X86下的支持目标ARM ABI编译的GCC，加上ARM的基础库，编译链接出ARM的执行档。限制是编译好的执行档还要到ARM板子上运行调试，前些年的ARM板子性能限制大还得考虑远程调试。

最直接和最土的方法，就是直接在板子上编，总连板子不方便，于是相应的就有了**ARM虚拟机的方法**。通常是使用Qeum模拟某个ARM架构的芯片，比如树莓派的BCM2835、Cortex-A9等，因为是个完整的VM，所以需要对应的kernel、ramdisk、rootfs。好处是编译完可以直接运行、调试，某些驱动级的调试也有可能。限制是能模拟的CPU有限，但是ARMEL、ARMHF接口一样时，可以选择模拟快的CPU。从当初模拟树莓派的经验（windows上qemu模拟的）来看，速度跟开发板上几乎一样（等速模拟？），这个当时也未深究。

最近帮同事创建虚拟机，了解到他们使用**qemu-arm-static来进行交叉编译**，似乎是条中间路线，就探索了一下。其实，咱实验ARM开发板时也就是这么做的，当初不理解也就忽略了，所以这里也是补课一下。

大致的方法是，需要一个目标ARM架构的rootfs，可以选择开发板提供的rootfs，或者以Ubuntu Core（其他发行版也有）为基础构建一个，目前开发板常见的就是ARMHF的了。apt-get安装qemu-user-static，然后将/usr/bin/qemu-arm-staic拷贝到arm-rootfs/usr/bin下，在**chroot到arm-rootfs**，就进入到了ARM的rootfs里，可以运行ARM的执行挡，编译程序、内核，甚至apt-get、完善rootfs都可以了，神奇啊。从表现上跟一个ARM VM区别不大啊，直接免了模拟ARM CPU这步。


Qemu Static机制
----
**这是怎么实现的**？我大概查了查，有这么几点：

qemu-user-static依赖binfmt-support，这里包含**binfmt_misc**。这是Linux内核支持的一个扩展，可以对其他架构的执行档以**模拟或者虚拟机的方式来执行**，这个虚拟机**更像是Java虚拟机**，我们运行编译好的java二进制文件，实际是通过java虚拟机即时进行解释执行的。Python运行预编译好的pyo，在X86上直接跑ARM程序，也是这机制。

系统如何识别异构执行档和选择虚拟机？binfmt_misc是被mount到proc下的：

{% highlight bash %}
binfmt_misc on /proc/sys/fs/binfmt_misc type binfmt_misc (rw,noexec,nosuid,nodev)
{% endhighlight %}

/proc/sys/fs/binfmt_misc下的内容是:

{% highlight bash %}
python2.7     qemu-alpha  qemu-cris        qemu-mips    qemu-ppc64       qemu-sh4    qemu-sparc32plus  status
python3.4     qemu-arm    qemu-m68k        qemu-mipsel  qemu-ppc64abi32  qemu-sh4eb  qemu-sparc64
qemu-aarch64  qemu-armeb  qemu-microblaze  qemu-ppc     qemu-s390x       qemu-sparc  register
{% endhighlight %}

看到吧，这么老多，这里还有python，我们关注的主要是arm，先来看qemu-arm的内容:

{% highlight bash %}
enabled
interpreter /usr/bin/qemu-arm-static
flags: OC
offset 0
magic 7f454c4601010100000000000000000002002800
mask ffffffffffffff00fffffffffffffffffeffffff
{% endhighlight %}

系统就是靠magic等信息识别执行档，然后通过interpreter来解释执行的。在外部的X86-Linux上，我们也可以直接运行ARM执行档，这两个命令是等效的：

{% highlight bash %}
~$ ubuntu-core-armhf-rootfs/bin/ls
/lib/ld-linux-armhf.so.3: No such file or directory
~$ /usr/bin/qemu-arm-static ubuntu-core-armhf-rootfs/bin/ls
/lib/ld-linux-armhf.so.3: No such file or directory
{% endhighlight %}

出错是arm的库在外部linux下没有。而chroot到arm-rootfs下也没干什么高级的事儿，由于mount的binfmt_misc没有变化，所以还是依赖于chroot后路径的`/usr/bin/qemu-arm-static`。chroot后执行sleep 10，外部Linux可以看到：

{% highlight bash %}
root      1410  0.0  0.0  68140  2472 pts/1    S    09:32   0:00 sudo chroot ubuntu-core-armhf-rootfs/
root      1411  0.7  0.2 4137480 9160 pts/1    S    09:32   0:00 /usr/bin/qemu-arm-static /bin/bash -i
root      1415  0.6  0.0 4137480 3320 pts/1    S+   09:32   0:00 /usr/bin/qemu-arm-static /bin/sleep 10
{% endhighlight %}

所以，看起来我们在arm-rootfs下执行的每一个arm执行档，只不过都是通过qemu-arm-static即时解释执行的。另外，看看内外部uname的信息：

{% highlight bash %}
Linux ubt1404-tico.itc.inventec 3.13.0-43-generic #72-Ubuntu SMP Mon Dec 8 19:35:06 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
Linux ubt1404-tico.itc.inventec 3.13.0-43-generic #72-Ubuntu SMP Mon Dec 8 19:35:06 UTC 2014 armv7l armv7l armv7l GNU/Linux
{% endhighlight %}

arm-rootfs里显然没有内核，但是指令集的信息已经变成了armv7l了。


比较一下
----
下面简单来看这三个方法**gcc编译arm**，**ARM虚拟机**和**qemu-user-static**，在实践中的一些比较（有些是猜想）：

* 编译效率，是否能用足外部X86-Linux的性能：gcc编译arm > qemu > ARM虚拟机。
* 链接效率：这个都差不多，通常卡在磁盘IO上。
* 即时运行调试：ARM虚拟机、qemu可以，gcc编译arm不行。
* 驱动级别的调试：只有ARM虚拟机。
* 多人共享一个交叉编译环境的，主要考虑方便、隔离程度：ARM虚拟机 > gcc编译arm > qemu。
* 可以进行rootfs的搭建工作：qemu > ARM虚拟机，gcc编译arm不行。
* 自定义交叉编译环境搭建难度：qemu > ARM虚拟机 > gcc编译arm。
* 多异构架构编译环境的一致性，比如x86、x64、armhf、armel都要支持：qemu > ARM虚拟机 > gcc编译arm。

综合看来，qemu-user-static+chroot的方法确实比较好。

参考文章
----
* [Emulating ARM on Debian/Ubuntu](https://gist.github.com/bdsatish/7476239) 
* [QemuARMVexpress](https://wiki.ubuntu.com/Kernel/Dev/QemuARMVexpress) 
* [Cross compilation for ARM](http://community.arm.com/groups/embedded/blog/2013/11/21/cross-compilation-for-arm) 
* [WIKI binfmt_misc](http://en.wikipedia.org/wiki/Binfmt_misc) 
* [What is the difference between arm-linux-gcc and arm-none-linux-gnueabi](http://stackoverflow.com/questions/13797693/what-is-the-difference-between-arm-linux-gcc-and-arm-none-linux-gnueabi) 
* [Ubuntu Core 14.04 LTS Images](http://cdimage.ubuntu.com/ubuntu-core/releases/14.04/release/) 

