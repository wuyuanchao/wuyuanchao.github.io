---
title: "File Batch Processing"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---
工作中经常回遇到使用逗号替换换行符的场景：比如别人给你个excel，其中一列是id，我们需要通过id查询数据库数据，那么一般就是:
```sql
select * from t where id in(x,x,x)
```
这时候常用的方法就是把列复制出来，放到文本中，然后正则表达式替换一下：
```
vim a.txt
:%s/\n/,
:wq
```
但是当遇到一批文件需要这样处理的时候，一个一个vim打开处理实在太烦琐了。自然想到把命令`s/\n/,`统一发送给每个文件执行,经过一顿搜索，sed这个命令进入视线。不过sed，awk这样的工具都是面向行的，所以一开始
```
sed 's/\n//' *.txt
```
没来带来任何效果。再经过一顿搜索，发现sed有个高级用法，读下一行。
同时使用`:a;**;ta`进行循环,实现全部替换。
```
sed -i ':a;N;s/\n//;ta' *.txt
```

参考文档：

【1】[linux sed命令，如何替换换行符“\n”](https://blog.csdn.net/u011729865/article/details/71773840 "linux sed命令，如何替换换行符“\n”")

【2】[Sed and awk 笔记之 sed 篇：高级命令（一）](http://kodango.com/sed-and-awk-notes-part-4 "Sed and awk 笔记之 sed 篇：高级命令（一）")
