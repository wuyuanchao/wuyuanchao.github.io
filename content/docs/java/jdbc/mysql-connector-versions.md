---
title: "Mysql Connector Versions"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

### 记一次jdbc连接mysql失败

主要原因：
mysql-connector-java 太低，mysql版本太高

表现：
mysql-connector-java 可以连接测试 mysql，数据库工具可以连接本地mysql，但是jdbc无法连接本地mysql。

测试mysql版本为 5.6
本地mysql版本为 8.0

mysql-connector-java 版本为：5.1.28

更新后 mysql-connector-java 版本为 8.0.29

### 版本对应关系

- MySQL Connector/J 8.0 supports MySQL Server versions 5.6, 5.7, and 8.0.
- MySQL Connector/J 5.1 supports MySQL Server versions 5.0, 5.1, 5.5, 5.6, and 5.7.
