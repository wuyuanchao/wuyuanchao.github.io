---
title: "Binlog"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

## The Binary Log

> The binary log contains “events” that describe database changes such as table creation operations or changes to table data.
The binary log also contains information about how long each statement took that updated data. 

### 查看binlog是否打开：

```
mysql> SHOW VARIABLES LIKE 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | ON    |
+---------------+-------+
1 row in set (0.00 sec)
```

如果binlog没有打开，需要找到mysql的配置文件，添加如下配置后重启：
```
[mysqld]
log_bin = /var/lib/mysql/binlog  # 设置 Binlog 存储路径
binlog_format = ROW              # 推荐使用 ROW 格式
server_id = 1                    # 必须设置，否则 Binlog 无法启用，且一个集群内不能重复
expire_logs_days = 7              # 设定 Binlog 过期时间，防止日志占满磁盘
```

binlog有三种格式：
1. STATEMENT
2. ROW
3. MIXED

查看mysql的binlog格式：
```
mysql> SHOW VARIABLES LIKE 'binlog_format';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
1 row in set (0.00 sec)
```

### 查看binlog文件

```
mysql> SHOW BINARY LOGS;
+---------------+-----------+-----------+
| Log_name      | File_size | Encrypted |
+---------------+-----------+-----------+
| binlog.001067 |       181 | No        |
| binlog.001068 |       181 | No        |
| binlog.001069 |       181 | No        |
| binlog.001070 |       181 | No        |
| binlog.001071 |     21968 | No        |
| binlog.001072 |      1790 | No        |
+---------------+-----------+-----------+
6 rows in set (0.00 sec)
```

### 查看当前服务器正在使用的binlog文件

```
mysql> SHOW MASTER STATUS;
+---------------+----------+--------------+------------------+-------------------------------------------------+
| File          | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                               |
+---------------+----------+--------------+------------------+-------------------------------------------------+
| binlog.001072 |     1790 |              |                  | ae0337bd-e1a4-11ee-bd3a-00163e142e2f:1-38595837 |
+---------------+----------+--------------+------------------+-------------------------------------------------+
1 row in set, 1 warning (0.00 sec)
```

### 查看binlog的内容

```
mysql> SHOW BINLOG EVENTS in 'binlog.001072' from 809 limit 3;
+---------------+------+----------------+-----------+-------------+--------------------------------------+
| Log_name      | Pos  | Event_type     | Server_id | End_log_pos | Info                                 |
+---------------+------+----------------+-----------+-------------+--------------------------------------+
| binlog.001072 |  809 | Update_rows    |         1 |        1053 | table_id: 98 flags: STMT_END_F       |
| binlog.001072 | 1053 | Xid            |         1 |        1084 | COMMIT /* xid=164 */                 |
| binlog.001072 | 1084 | Anonymous_Gtid |         1 |        1161 | SET @@SESSION.GTID_NEXT= 'ANONYMOUS' |
+---------------+------+----------------+-----------+-------------+--------------------------------------+
3 rows in set (0.00 sec)
```

这种方式只适用于快速查看 Binlog 事件的结构，但无法获取具体 SQL。

可以使用 mysqlbinlog 命令解析具体内容，但需要拥有MySQL 服务器的文件访问权限。

首先找到binlog的位置

```
mysql> SHOW VARIABLES LIKE 'log_bin_basename';
+------------------+-----------------------------+
| Variable_name    | Value                       |
+------------------+-----------------------------+
| log_bin_basename | /usr/local/var/mysql/binlog |
+------------------+-----------------------------+
1 row in set (0.01 sec)
```

然后使用`--verbose --base64-output=DECODE-ROWS`参数查看具体的行数据。
```
mysqlbinlog --verbose --base64-output=DECODE-ROWS /usr/local/var/mysql/binlog.001072;
```


