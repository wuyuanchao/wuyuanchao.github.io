---
title: "Content Placeholder"
_build:
  render: never
  list: never
  publishResources: false
---


1. 分页技术(paging)
虚拟地址空间划分成称为页（page）的单位，而相应的物理地址空间也被进行划分，单位是页框(frame)，页和页框的大小必须相同。

常见的页大小是 4KB 或 8KB，具体大小取决于操作系统和硬件架构。

在mac中,可以使用以下命令查看页大小
```
getconf PAGE_SIZE
```