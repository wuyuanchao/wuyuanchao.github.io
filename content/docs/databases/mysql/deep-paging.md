---
title: "Mysql Deep Paging"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

# mysql深分页性能问题

https://blog.stackademic.com/interviewer-why-is-the-query-with-limit-0-10-fast-while-the-query-with-limit-1000000-10-slow-d1c12ab39cc7

## 实验
### 实验数据准备

```
-- Create a table named 'Student' to store student information.
CREATE TABLE Student (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    gender ENUM('Male', 'Female'),
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Here is the stored procedure for inserting 5 million student records:
DELIMITER //
CREATE PROCEDURE insert_students()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 5000000 DO
        INSERT INTO Student (name, age, gender) VALUES (CONCAT('Student', i), FLOOR(RAND() * 100), ELT(FLOOR(RAND() * 2 + 1), 'Male', 'Female'));
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Call a stored procedure to insert data.
CALL insert_students();
```

### 问题表现

```
mysql> SELECT * FROM Student LIMIT 0, 10;
+----+-----------+------+--------+---------------------+
| id | name      | age  | gender | create_time         |
+----+-----------+------+--------+---------------------+
|  1 | Student1  |   47 | Female | 2025-01-12 10:08:05 |
|  2 | Student2  |   52 | Male   | 2025-01-12 10:08:05 |
|  3 | Student3  |   69 | Female | 2025-01-12 10:08:05 |
|  4 | Student4  |   43 | Male   | 2025-01-12 10:08:05 |
|  5 | Student5  |    2 | Female | 2025-01-12 10:08:05 |
|  6 | Student6  |   53 | Female | 2025-01-12 10:08:05 |
|  7 | Student7  |   93 | Female | 2025-01-12 10:08:05 |
|  8 | Student8  |    2 | Male   | 2025-01-12 10:08:05 |
|  9 | Student9  |   96 | Male   | 2025-01-12 10:08:05 |
| 10 | Student10 |   22 | Male   | 2025-01-12 10:08:05 |
+----+-----------+------+--------+---------------------+
10 rows in set (0.00 sec)

mysql> SELECT * FROM Student LIMIT 10000000, 10;
Empty set (1.79 sec)

mysql> SELECT * FROM Student LIMIT 4000000, 10;
+---------+----------------+------+--------+---------------------+
| id      | name           | age  | gender | create_time         |
+---------+----------------+------+--------+---------------------+
| 4000001 | Student4000001 |   63 | Female | 2025-01-12 10:30:03 |
| 4000002 | Student4000002 |   55 | Female | 2025-01-12 10:30:03 |
| 4000003 | Student4000003 |   79 | Female | 2025-01-12 10:30:03 |
| 4000004 | Student4000004 |   21 | Male   | 2025-01-12 10:30:03 |
| 4000005 | Student4000005 |   82 | Male   | 2025-01-12 10:30:03 |
| 4000006 | Student4000006 |   71 | Female | 2025-01-12 10:30:03 |
| 4000007 | Student4000007 |   13 | Male   | 2025-01-12 10:30:03 |
| 4000008 | Student4000008 |   21 | Female | 2025-01-12 10:30:03 |
| 4000009 | Student4000009 |   87 | Male   | 2025-01-12 10:30:03 |
| 4000010 | Student4000010 |   61 | Male   | 2025-01-12 10:30:03 |
+---------+----------------+------+--------+---------------------+
10 rows in set (1.35 sec)
```

## 优化方法

### 1. 起始ID定位方式(Starting ID Positioning Method)

使用前一个查询的最后一个 ID 作为该查询的起始 ID。

```
select name, age, grade from student where id > 990000 order by id limit 10;
```

这种方式特别适合瀑布流页面的应用。ID有序自增，查询时按ID顺序或逆序展示。
但是不适合直接跳转到第几页的场景。或者按其他要求排序。


### 2. 子查询(Subquery)

增加索引前后性能对比：
```
mysql>  select t1.name, t1.age, t1.gender, t1.create_time from student as t1    inner join     (select id from student order by create_time desc limit 1000000,10) as t2 on t1.id = t2.id;
+----------------+------+--------+---------------------+
| name           | age  | gender | create_time         |
+----------------+------+--------+---------------------+
| Student4001914 |   88 | Female | 2025-01-12 10:30:03 |
| Student4001915 |   15 | Female | 2025-01-12 10:30:03 |
| Student4001916 |    6 | Female | 2025-01-12 10:30:03 |
| Student4001917 |   83 | Female | 2025-01-12 10:30:03 |
| Student4001918 |   20 | Female | 2025-01-12 10:30:03 |
| Student4001919 |   33 | Male   | 2025-01-12 10:30:03 |
| Student4001920 |   61 | Male   | 2025-01-12 10:30:03 |
| Student4001921 |   66 | Male   | 2025-01-12 10:30:03 |
| Student4001922 |    3 | Male   | 2025-01-12 10:30:03 |
| Student4001923 |   74 | Male   | 2025-01-12 10:30:03 |
+----------------+------+--------+---------------------+
10 rows in set (3.26 sec)

mysql> ALTER TABLE `jolly`.`Student` ADD INDEX `idx_create_time` (`create_time` ASC) VISIBLE;
Query OK, 0 rows affected (7.01 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql>  select t1.name, t1.age, t1.gender, t1.create_time from student as t1    inner join     (select id from student order by create_time desc limit 1000000,10) as t2 on t1.id = t2.id;
+----------------+------+--------+---------------------+
| name           | age  | gender | create_time         |
+----------------+------+--------+---------------------+
| Student4000000 |   27 | Male   | 2025-01-12 10:30:03 |
| Student3999999 |    6 | Male   | 2025-01-12 10:30:03 |
| Student3999998 |   43 | Female | 2025-01-12 10:30:03 |
| Student3999997 |   57 | Female | 2025-01-12 10:30:03 |
| Student3999996 |   16 | Male   | 2025-01-12 10:30:03 |
| Student3999995 |   72 | Male   | 2025-01-12 10:30:03 |
| Student3999994 |   74 | Female | 2025-01-12 10:30:03 |
| Student3999993 |   48 | Female | 2025-01-12 10:30:03 |
| Student3999992 |   38 | Female | 2025-01-12 10:30:03 |
| Student3999991 |   76 | Male   | 2025-01-12 10:30:03 |
+----------------+------+--------+---------------------+
10 rows in set (0.29 sec)
```

有索引但是不使用子查询的性能：
```
mysql> SELECT name, age, gender, create_time FROM student ORDER BY create_time DESC LIMIT 1000000 , 10;
+----------------+------+--------+---------------------+
| name           | age  | gender | create_time         |
+----------------+------+--------+---------------------+
| Student3999538 |   86 | Female | 2025-01-12 10:30:03 |
| Student3999539 |   27 | Female | 2025-01-12 10:30:03 |
| Student3999540 |   54 | Female | 2025-01-12 10:30:03 |
| Student3999541 |   86 | Male   | 2025-01-12 10:30:03 |
| Student3999542 |   58 | Male   | 2025-01-12 10:30:03 |
| Student3999543 |   38 | Male   | 2025-01-12 10:30:03 |
| Student3999544 |    1 | Male   | 2025-01-12 10:30:03 |
| Student3999545 |   85 | Male   | 2025-01-12 10:30:03 |
| Student3999546 |   15 | Male   | 2025-01-12 10:30:03 |
| Student3999547 |   30 | Male   | 2025-01-12 10:30:03 |
+----------------+------+--------+---------------------+
10 rows in set (5.02 sec)
```

此方法的性能优化主要得益于子查询只获取了ID，然后使用少量的ID查询主表。优化前，需要加载1000010条完整数据，然后丢弃1000000条。优化后，虽然也需要加载1000010条数据并丢弃1000000条，但只需要加载自查询索引数据，减少了I/O和内存使用。

> 1. The subquery only reads the index entries (create_time + id), which are much smaller than full rows and stored sequentially on disk
> 2. Sorting happens on these small index entries instead of full rows, using much less memory
> 3. Only after getting the 10 needed IDs does it fetch the complete row data, resulting in just 10 primary key lookups
> The key performance gain comes from working with the compact, pre-sorted index data first, minimizing both disk I/O and memory usage during the sorting phase. The approach is similar to using an index in a book to find specific pages rather than reading every page to find what you need.

### 3.覆盖索引技术(Covering Index)

> Index coverage is a database query optimization technique. It means that when executing a query, the database engine can directly obtain all the required data from the index without having to go back to the table (access the primary key index or the actual data rows in the table) to obtain additional information. This way can reduce disk I/O operations and thus improve query performance.

没有索引耗时：
```
mysql> select id, name, create_time from student order by create_time LIMIT 1000000, 10;
+---------+----------------+---------------------+
| id      | name           | create_time         |
+---------+----------------+---------------------+
| 1000001 | Student1000001 | 2025-01-12 10:13:25 |
| 1000002 | Student1000002 | 2025-01-12 10:13:25 |
| 1000003 | Student1000003 | 2025-01-12 10:13:25 |
| 1000004 | Student1000004 | 2025-01-12 10:13:25 |
| 1000005 | Student1000005 | 2025-01-12 10:13:25 |
| 1000006 | Student1000006 | 2025-01-12 10:13:25 |
| 1000007 | Student1000007 | 2025-01-12 10:13:25 |
| 1000008 | Student1000008 | 2025-01-12 10:13:25 |
| 1000009 | Student1000009 | 2025-01-12 10:13:25 |
| 1000010 | Student1000010 | 2025-01-12 10:13:25 |
+---------+----------------+---------------------+
10 rows in set (4.56 sec)
```

增加`create_time`索引：
```
ALTER TABLE `jolly`.`Student` 
ADD INDEX `idx` (`create_time` ASC) VISIBLE;
;
```
没有任何提升
```
mysql> select id,name,create_time from student order by create_time LIMIT 1000000, 10;
+---------+----------------+---------------------+
| id      | name           | create_time         |
+---------+----------------+---------------------+
| 1000001 | Student1000001 | 2025-01-12 10:13:25 |
| 1000002 | Student1000002 | 2025-01-12 10:13:25 |
| 1000003 | Student1000003 | 2025-01-12 10:13:25 |
| 1000004 | Student1000004 | 2025-01-12 10:13:25 |
| 1000005 | Student1000005 | 2025-01-12 10:13:25 |
| 1000006 | Student1000006 | 2025-01-12 10:13:25 |
| 1000007 | Student1000007 | 2025-01-12 10:13:25 |
| 1000008 | Student1000008 | 2025-01-12 10:13:25 |
| 1000009 | Student1000009 | 2025-01-12 10:13:25 |
| 1000010 | Student1000010 | 2025-01-12 10:13:25 |
+---------+----------------+---------------------+
10 rows in set (4.73 sec)
```

可以看到，当offset增大到一定值时，mysql就放弃了索引。
```
mysql> explain select id,name,create_time from student order by create_time LIMIT 15000, 10;
+----+-------------+---------+------------+-------+---------------+------+---------+------+-------+----------+-------+
| id | select_type | table   | partitions | type  | possible_keys | key  | key_len | ref  | rows  | filtered | Extra |
+----+-------------+---------+------------+-------+---------------+------+---------+------+-------+----------+-------+
|  1 | SIMPLE      | student | NULL       | index | NULL          | idx  | 5       | NULL | 15010 |   100.00 | NULL  |
+----+-------------+---------+------------+-------+---------------+------+---------+------+-------+----------+-------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select id,name,create_time from student order by create_time LIMIT 16000, 10;
+----+-------------+---------+------------+------+---------------+------+---------+------+---------+----------+----------------+
| id | select_type | table   | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra          |
+----+-------------+---------+------------+------+---------------+------+---------+------+---------+----------+----------------+
|  1 | SIMPLE      | student | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 4988328 |   100.00 | Using filesort |
+----+-------------+---------+------------+------+---------------+------+---------+------+---------+----------+----------------+
1 row in set, 1 warning (0.00 sec)

```

性能下降非常剧烈
```
mysql> select id,name,create_time from student order by create_time LIMIT 15000, 10;
+-------+--------------+---------------------+
| id    | name         | create_time         |
+-------+--------------+---------------------+
| 15001 | Student15001 | 2025-01-12 10:08:10 |
| 15002 | Student15002 | 2025-01-12 10:08:10 |
| 15003 | Student15003 | 2025-01-12 10:08:10 |
| 15004 | Student15004 | 2025-01-12 10:08:10 |
| 15005 | Student15005 | 2025-01-12 10:08:10 |
| 15006 | Student15006 | 2025-01-12 10:08:10 |
| 15007 | Student15007 | 2025-01-12 10:08:10 |
| 15008 | Student15008 | 2025-01-12 10:08:10 |
| 15009 | Student15009 | 2025-01-12 10:08:10 |
| 15010 | Student15010 | 2025-01-12 10:08:10 |
+-------+--------------+---------------------+
10 rows in set (0.01 sec)

mysql> select id,name,create_time from student order by create_time LIMIT 16000, 10;
+-------+--------------+---------------------+
| id    | name         | create_time         |
+-------+--------------+---------------------+
| 16001 | Student16001 | 2025-01-12 10:08:10 |
| 16002 | Student16002 | 2025-01-12 10:08:10 |
| 16003 | Student16003 | 2025-01-12 10:08:10 |
| 16004 | Student16004 | 2025-01-12 10:08:10 |
| 16005 | Student16005 | 2025-01-12 10:08:10 |
| 16006 | Student16006 | 2025-01-12 10:08:10 |
| 16007 | Student16007 | 2025-01-12 10:08:10 |
| 16008 | Student16008 | 2025-01-12 10:08:10 |
| 16009 | Student16009 | 2025-01-12 10:08:10 |
| 16010 | Student16010 | 2025-01-12 10:08:10 |
+-------+--------------+---------------------+
10 rows in set (2.99 sec)
```

由于需求是查询`id`，`name`，`create_time` 三个字段,这种场景下可以使用覆盖索引技术：

建立复合索引（composite indexes）
```
ALTER TABLE `jolly`.`Student` 
DROP INDEX `idx` ,
ADD INDEX `idx` (`create_time` ASC, `name` ASC) VISIBLE;
```

性能提升显著：
```
mysql> select id,name,create_time from student order by create_time LIMIT 100000, 10;
+-------+--------------+---------------------+
| id    | name         | create_time         |
+-------+--------------+---------------------+
| 99831 | Student99831 | 2025-01-12 10:08:35 |
| 99832 | Student99832 | 2025-01-12 10:08:35 |
| 99833 | Student99833 | 2025-01-12 10:08:35 |
| 99834 | Student99834 | 2025-01-12 10:08:35 |
| 99835 | Student99835 | 2025-01-12 10:08:35 |
| 99836 | Student99836 | 2025-01-12 10:08:35 |
| 99837 | Student99837 | 2025-01-12 10:08:35 |
| 99838 | Student99838 | 2025-01-12 10:08:35 |
| 99839 | Student99839 | 2025-01-12 10:08:35 |
| 99840 | Student99840 | 2025-01-12 10:08:35 |
+-------+--------------+---------------------+
10 rows in set (0.03 sec)
```
