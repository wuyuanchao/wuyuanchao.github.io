---
title: "JVM Tuning"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

# JVM调优

## 什么是JVM调优？

JVM调优，就是调整虚拟机的默认参数以适应应用程序的需要的过程。它包括堆大小的调整，垃圾收集器的调整等。

> Java virtual machine tuning is the process of adjusting the default parameters to match our application needs.This includes simple adjustments like the size of the heap, through choosing the right garbage collector to using optimized versions of getters.

## 怎样进行调优？

在调优之前，需要考虑下面几个问题：

1. 成本。增加硬件可能比花时间调优jvm获得更好的收益。

2. 期望结果。从长远考虑，稳定比性能更有效，不过有时他们确实是重叠的。

3. 现存问题。调优可能会暂时隐藏已经存在的问题，所以一定要在调有前对系统进行彻底的检查。

4. 内存泄漏。调优无法解决内存泄漏问题。

JVM调优虽然很重要，但出色的调优着眼于整个系统以及所有可能影响性能的层，包括数据库和操作系统。如果应用程序的架构设计糟糕或代码编写糟糕，不要指望通过调优获得很好的性能提升。在进行JVM调优前，确保已经优化过系统架构和代码。

### 性能指标

JVM调优关注的性能指标如下：

1. 延迟。运行垃圾收集事件所需的时间量。

2. 吞吐量。虚拟机执行应用程序所花费的时间与执行垃圾收集所花费的时间的百分比。

3. 占用空间。垃圾收集器平稳运行所需的内存量。

三者相互约束，比如：低延迟和较少的内存使用量会导致吞吐量降低。

### 调优的原则：

1. Minor GC 收集 – Minor GC 应收集尽可能多的死亡对象，以减少 Full GC 的频率。

2. GC内存最大化 – GC在一个周期内可以访问的内存越多，清理的效率就越高，收集频率就越低。

3. 三选二 – 根据业务需求，决定哪两个指标与应用程序最相关。

比如一个后台运行的任务行应用程序，吞吐量比低延迟更重要。而一个B/S系统的服务端，低延迟更符合这类应用的需求。

### 基本步骤

1. 测量内存占用

通过GC日志测量应用程序的内存占用情况

2. 调优延迟

延迟需要关注的的指标有：
- Minor GC 频率
- 最大 Full GC 停顿
- Full GC 频率
- 平均 Minor GC 停顿

通过调整新生代，老年代的大小来优化这些指标。

也可以考虑更换垃圾收集器。比如：

- PS/PS Old的组合，适合高吞吐量需求的后台任务系统。
- ParNew/CMS+Serial Old适合运行在高性能硬件下的低延迟要求的服务。
- Serial/Serial Old则适合单CPU（单核）环境。
- G1则是最先进的收集器，目标也是低延迟，可以考虑替换CMS。

3. 吞吐量调优

对于垃圾回收，吞吐量调整有两个目的：

1. 最小化传递到老年代的对象数量

2. 减少 Full GC 执行时间（Stop-the-World 事件）。

如果调优后，差距大于20%，则需要重新审视吞吐量目标，该设计可能无法满足整个Java应用程序的要求。

## 总结

对于JAVA程序来说，调优就是尽量缩小代码与其运行所在的虚拟机之间的资源差距。

> When it comes to Java applications, to make sure they run at peak performance, it’s critical to close the resource gap between the code and the virtual machine it’s running on – if there is one. 

当然，如果有条件，可以考虑升级jdk版本，但在企业应用中，这件事需要非常慎重。

参考：

https://sematext.com/blog/jvm-performance-tuning/
