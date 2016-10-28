---
layout: post
title:  通过 udev 自动 mount U盘失败
date:   2016-10-28 20:00:00
author: fadeer
categories: 工作
tags: Linux fuse udev cgroups
---

场景和问题
----
最近整理 ClientOS 业务时，发现 NTFS 格式的U盘自动 mount 不能使用。可以看到 `mount` 成功了，但是 mount 点不可访问。

~~~bash
$ mount | grep media
/dev/sda1 on /media/Untitled-sda1 type fuseblk (rw,relatime,user_id=0,group_id=0,allow_other,blksize=4096)

$ ls /media/Untitled-sda1
ls: cannot access /media/Untitled-sda1: Transport endpoint is not connected
$ ll /media/
total 0
d????????? ? ? ? ?            ? Untitled-sda1
~~~

看起来不像是权限方面的问题，是目录所有信息都没有，挺奇怪的状态。但是，这个分区手动 `mount` 就很正常：

~~~bash
$ sudo mount /dev/sda1 /mnt
/dev/sda1 on /mnt type fuseblk (rw,relatime,user_id=0,group_id=0,allow_other,blksize=4096)
$ ps -aux | grep mnt
root      6975  0.0  0.1   4476  1752 ?        Ss   11:05   0:00 /sbin/mount.ntfs /dev/sda1 /mnt -o rw
~~~

同时增加的 exfat 格式的分区也是这个状态；而一般的 ext3、ext4 等 Linux 分区却也正常。

而我们的自动 mount 是通过 udev 规则来实现的，在设备出现、和消失时，调用 mount/umount 命令。另一方面，ntfs-3g 和 exfat 的 mount 都是走 fuse 实现的，所以这两个因素可能都有关系。

搜索原因
----
Google上找了一圈，发现邮件列表里这个[回复](https://lists.debian.org/debian-devel/2015/05/msg00440.html)描述的比较接近。
 
> I think that the **fuse process is being killed**.
> You cannot start long-lived processes **from a udev rule**, this should be 
> handled by systemd.

然后发现，手动 mount 确实后台一直在跑着一个 `mount.ntfs` 的进程，这以前还真没注意过。而通过udev调用的进程就会在U盘接上后4、5秒钟就消失了。像这样，只出现过3次：

~~~bash
$ while [ 1 ]; do ps -aux | grep mount | grep -v grep; sleep 1; done
...
root  6235  0.0  0.1   2900  1628 ?   Ss   10:53   0:00 /sbin/mount.ntfs /dev/sda1 /media/Untitled-sda1 -o rw,iocharset=utf8,umask=000
root  6235  0.0  0.1   2900  1628 ?   Ss   10:53   0:00 /sbin/mount.ntfs /dev/sda1 /media/Untitled-sda1 -o rw,iocharset=utf8,umask=000
root  6235  0.0  0.1   2900  1628 ?   Ss   10:53   0:00 /sbin/mount.ntfs /dev/sda1 /media/Untitled-sda1 -o rw,iocharset=utf8,umask=000
...
~~~

当 mount.ntfs 进程被杀掉，mount点就成了 `Transport endpoint is not connected` 的状态。

如何保持进程
----
然后，我尝试用脚本简单包装mount命令一样无效，mount.ntfs还是会被杀掉。进一步搜索发现了这个[回答](http://unix.stackexchange.com/questions/56243/how-to-run-long-time-process-on-udev-event)：

> Nowadays udev uses **cgroups to seek-n-destroy spawned tasks**. One solution is to use "at now" or "batch". Another solution is to do double fork and "relocate" process to another cgroup. This is an example python code (similar code can written in any language):

哈哈，udev这策略不错啊，清理规则执行垃圾会比较干净。于是要**执行长时间命令的保持**，本质上就是把 mount.ntfs 脱离这个cgroups，要么用另外的服务（at、batch就是），或者是手动脱离的方式（上面提到的python包装）。看了一下，感觉 `at` 就目前就足够用了。

另外，这篇[Advanced device mounting](http://www.volkerschatz.com/unix/advmount.html)也也提到了相同的问题；而在他[脚本](http://www.volkerschatz.com/unix/scripts/remmount)里脱离CGroups的方法是：

~~~bash
# Escape from systemd to avoid getting  killed prematurely:
if [ -d /sys/fs/cgroup/systemd ]; then
    echo $$ > /sys/fs/cgroup/systemd/tasks
fi
~~~

貌似更方便。

