---
title: "Class.forName() no longer required"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

## 为什么现在不需要Class.forName("驱动名称")了

#### JDBC进化史
https://blog.csdn.net/u011179993/article/details/47291827

到了JDBC 4.0（jdk 1.6），应用程序不再需要显式地使用Class.forName("驱动名称")加载驱动程序。

！对于没有提供spi的jdbc驱动，应该还是要手动加载的吧！

#### Java SPI实现
https://blog.csdn.net/qq_44503987/article/details/124085718

Java 为解决 SPI 问题，java提供了一个服务加载类 ServiceLoader（@since 1.6）。ServiceLoader可以直接加载Jar按规定提供的服务接口实现，具体使用方式如下所示：

- 在类加载路径下，在目录META-INF/services下的文件(以Interface全路径命名)中添加具体实现类的全路径名；
- 接口的实现类放在程序的加载路径下。
- 实现接口实现类，特别注意：实现类必须提供一个无参构造方法。

#### DriverManager
DriverManager 的 getConnection 方法中，调用了 ensureDriversInitialized。该方法通过 ServiceLoader 加载驱动。
> If the driver is packaged as a Service Provider, load it.
```
ServiceLoader<Driver> loadedDrivers = ServiceLoader.load(Driver.class);
```

然后在 getConnection 方法中遍历所有驱动尝试连接。

经典用法：
```
Class.forName(******);
DriverManager.getConnection(url, user, password);
```

#### Datasource

Datasource自jdk1.4开始。

> An alternative to the {@code DriverManager} facility, a {@code DataSource} object is the preferred means of getting a connection.

在 MysqlDataSource 实现中（mysql-connector-java:5.1.28），mysqlDriver 使用的是 NonRegisteringDriver。意思是通过 MysqlDataSource 获取connection 是不需要注册驱动的？

所以如果使用datasource获取connection，即使没有spi，也没有手动注册驱动，也是可以的？
