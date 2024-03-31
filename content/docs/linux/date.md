---
title: "Date"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

#### 查看时间：
直接使用date显示当前时间
```
% date
Wed Jul  6 09:45:08 CST 2022
```

#### 格式化显示：
使用参数 +format，其中format是格式串。
比如显示秒
```
% date +%s
1657072300
```

#### 将时间戳(秒)转成时间显示
```
% date -r 1657072300    
Wed Jul  6 09:51:40 CST 2022
```

#### 查缺命令手册
```
man date
```
