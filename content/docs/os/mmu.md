---
title: "Memory Management Unit"
_build:
  render: never
  list: never
  publishResources: false
---

### 核心子部件
- 页表遍历单元（Page Table Walker, PTW） 
  - 在 TLB 未命中时，负责按照多级页表格式去内存里查表。
  - 例如 x86-64 的四级/五级页表、ARM 的两级/四级页表。 
  - 有的 CPU 是 硬件遍历（x86），有的依赖 软件遍历（早期 ARM）。
- TLB（Translation Lookaside Buffer，快表）
  - 一个高速缓存，存放近期访问的虚拟地址 → 物理地址的映射。
  - 分为：
    - iTLB（指令地址映射，用于取指令）
    - dTLB（数据地址映射，用于读写数据）
  - 有时还分 L1 TLB、L2 TLB，类似多级 cache。
- 权限检查单元（Access Control / Protection Check）
  - 根据页表项里的权限位（R/W/X/U）判断： 
    - 用户态/内核态访问是否允许 
    - 是否允许读、写、执行 
  - 如果违规 → 触发 Page Fault 异常。
- 页缓存/影子寄存器（Page Table Base Register）
  - 存放当前进程的顶级页表基址，比如：
    - x86：CR3 寄存器
    - ARM：TTBR0/TTBR1（Translation Table Base Register）
  - 进程切换时，操作系统会修改这些寄存器。
- 异常处理触发器（Page Fault Generator）
  - 当虚拟地址无法转换，或者访问权限违规时，产生异常。 
  - 硬件只负责抛异常，内核负责处理中断（比如缺页加载、终止进程）。

### 多核CPU中MMU的组织方式

#### 每个核心有自己独立的 MMU
- 每个核心独立执行指令流
- 每个核心有自己的 TLB
- 上下文切换

#### 多核之间的协作
- 共享物理内存和页表
  - 页表存在物理内存中，所有核心访问的是同一份页表数据。
  - 各核心的 Page Table Walker 都能从内存中查到一致的数据。
- TLB shootdown
  - 如果内核修改了页表（比如换页、解除映射），必须通知所有核心刷新对应的 TLB 条目。
  - Linux 内核里就有 TLB shootdown 机制： 一个核心修改页表后，会发 IPI（Inter-Processor Interrupt）通知其他核心，要求 flush 对应 TLB。
- ASID / PCID（地址空间标识符）
  - 为了减少多核 TLB 刷新的开销，现代 CPU 引入了 ASID/PCID：这样即使多个进程的映射都存在 TLB 中，也能通过 ID 区分。








  1. 分页技术(paging)
虚拟地址空间划分成称为页（page）的单位，而相应的物理地址空间也被进行划分，单位是页框(frame)，页和页框的大小必须相同。

常见的页大小是 4KB 或 8KB，具体大小取决于操作系统和硬件架构。

在mac中,可以使用以下命令查看页大小
```
getconf PAGE_SIZE
```