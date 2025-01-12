---
title: "Mysql"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

## mysql深分页性能问题

https://blog.stackademic.com/interviewer-why-is-the-query-with-limit-0-10-fast-while-the-query-with-limit-1000000-10-slow-d1c12ab39cc7

### 实验数据

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

### 实验结果

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

### 优化方法

1. 起始ID定位方式(Starting ID Positioning Method)

使用前一个查询的最后一个 ID 作为该查询的起始 ID。

```
select name, age, grade from student where id > 990000 order by id limit 10;
```

这种方式特别适合瀑布流页面的应用。ID有序自增，查询时按ID顺序或逆序展示。
但是不适合直接跳转到第几页的场景。或者按其他要求排序。


2. 覆盖索引 + 子查询(Covering Index + Subquery)

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

覆盖索引技术：

> Index coverage is a database query optimization technique. It means that when executing a query, the database engine can directly obtain all the required data from the index without having to go back to the table (access the primary key index or the actual data rows in the table) to obtain additional information. This way can reduce disk I/O operations and thus improve query performance.

此方法的性能优化主要得益于子查询只获取了ID，然后使用少量的ID查询主表。优化前，需要加载1000010条完整数据，然后丢弃1000000条。优化后，虽然也需要加载1000010条数据并丢弃1000000条，但只需要加载自查询索引数据，减少了I/O和内存使用。

> 1. The subquery only reads the index entries (create_time + id), which are much smaller than full rows and stored sequentially on disk
> 2. Sorting happens on these small index entries instead of full rows, using much less memory
> 3. Only after getting the 10 needed IDs does it fetch the complete row data, resulting in just 10 primary key lookups
> The key performance gain comes from working with the compact, pre-sorted index data first, minimizing both disk I/O and memory usage during the sorting phase. The approach is similar to using an index in a book to find specific pages rather than reading every page to find what you need.
