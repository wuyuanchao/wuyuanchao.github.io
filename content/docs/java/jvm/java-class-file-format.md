---
title: "Java Class File Format"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

# Java Class 文件格式

## 准备工作

编写并编译一个java的HelloWorld程序：

```
cat <<  EOF > Main.java
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }
}
EOF
javac Main.java && java Main
```

运行完上述命令，如果看到控制台输出 `Hello World!` 就表明准备工作完成了。`javac` 命令已经编译出了一个Main.class文件，就是我们需要分析对象。

分析这个class文件，我们借助两个工具：
 
1. hexdump

> hexdump is a built-in Linux utility to filter and display the contents of different files in hex, decimal, octal, or ASCII formats. 

```
hexdump -C Main.class
```

2. javap

> The javap command disassembles one or more class files. 

```
javap -verbose Main
```

## 基础知识

###  The ClassFile Structure

```
ClassFile {
  u4 magic;
  u2 minor_version;
  u2 major_version;
  u2 constant_pool_count;
  cp_info constant_pool[constant_pool_count-1];
  u2 access_flags;
  u2 this_class;
  u2 super_class;
  u2 interfaces_count;
  u2 interfaces[interfaces_count];
  u2 fields_count;
  field_info fields[fields_count];
  u2 methods_count;
  method_info methods[methods_count];
  u2 attributes_count;
  attribute_info attributes[attributes_count];
}
```

java的class文件是一组以字节(Byte - 8 bit)为基础单位的二进制流。通过无符号数和表来组织。

oracle官网的jvm规范中有对java class文件格式的详细描述，以下是jdk1.8版本的文档。

https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html

本笔记列出大致的结构，帮助记忆。详细细节可以参见官方文档。

### 魔数和版本号

class文件的开头8个字节，依次是 4个字节的魔数(ca fe ba be)，2个字节的次版本号和2个字节的主版本号。

### 常量池 

在魔数和版本号之后，紧接着的是常量池。2个字节的常量池数量以及相应长度的常量池数据。

常量结构cp_info struct如下：

```
cp_info {
  u1 tag;
  u1 info[];
}
```

不同的常量类型，有不同的数据结构。通过一个字节的常量tag进行区分，后续紧跟对应长度的常量信息。

#### Table of Constant pool tags

| Constant Type | Value |
| ------------- | ----- |
| CONSTANT_Class | 7 |
| CONSTANT_Fieldref | 9 |
| CONSTANT_Methodref | 10 |
| CONSTANT_InterfaceMethodref | 11 |
| CONSTANT_String | 8 |
| CONSTANT_Integer | 3 |
| CONSTANT_Float | 4 |
| CONSTANT_Long | 5 |
| CONSTANT_Double | 6 |
| CONSTANT_NameAndType | 12 |
| CONSTANT_Utf8 | 1 |

以最常见的字符串常量为例：

```
CONSTANT_Utf8_info {
    u1 tag;
    u2 length;
    u1 bytes[length];
}
```

第一个字节为tag，1表示是CONSTANT_Utf8，然后使用2个字节表示字符串长度（即2的16次方，64KB），最后是对应长度的字节数组。

### 类访问标志、类索引、父类索引和接口索引集合

常量池之后，依次是2个字节的类访问标志(共16个标志位)、2个字节的类索引、2个字节的父类索引和接口索引集合（2个字节数量和对应数量的2个字节的接口索引）。

#### Table of Class access and property modifiers

| Flag Name | Value | Interpretation |
| --------- | ----- | -------------- |
| ACC_PUBLIC | 0x0001 | Declared public; may be accessed from outside its package. |
| ACC_FINAL	| 0x0010 | Declared final; no subclasses allowed. |
| ACC_SUPER | 0x0020 | Treat superclass methods specially when invoked by the invokespecial instruction. |
| ACC_INTERFACE | 0x0200 | Is an interface, not a class. |
| ACC_ABSTRACT | 0x0400 | Declared abstract; must not be instantiated. |
| ACC_SYNTHETIC | 0x1000 | Declared synthetic; not present in the source code. |
| ACC_ANNOTATION | 0x2000 | Declared as an annotation type. |
| ACC_ENUM | 0x4000 | Declared as an enum type. |

### 字段表和方法表集合

紧接着的是字段表和方法表。

首先是2个字节的字段表长度，跟着是相应长度的字段信息表。

字段信息数据结构如下:

```
field_info {
    u2             access_flags;
    u2             name_index;
    u2             descriptor_index;
    u2             attributes_count;
    attribute_info attributes[attributes_count];
}
```

然后是2个字节的方法表长度，也跟着相应长度的方法信息表。

```
method_info {
    u2             access_flags;
    u2             name_index;
    u2             descriptor_index;
    u2             attributes_count;
    attribute_info attributes[attributes_count];
}
```

两者的数据结构几乎一样。都由2个字节的访问标志，2个字节的名称索引，2个字节的描述符索引和属性表组成（2个字节数量和对应长度的属性表数据）。

其中描述符主要用于描述字段的数据类型、方法的参数列表和返回值。

#### Table of field descriptors

| term | Type | Interpretation |
| -------------- | ---- | -------------- |
| B | byte | signed byte |
| C	| char | Unicode character code point in the Basic Multilingual Plane, encoded with UTF-16 |
| D	| double | double-precision floating-point value |
| F	| float | single-precision floating-point value |
| I	| int | integer |
| J	| long | long integer |
| L`ClassName`; | reference	| an instance of class ClassName |
| S	| short	| signed short |
| Z	| boolean | true or false |
| [	| reference	| one array dimension |

例如：

字符串数组 `String[][]` 将表示为 `[[java/lang.String;`

方法 `Object m(int i, double d, Thread t) {...}` 将表示为 `(IDLjava/lang/Thread;)Ljava/lang/Object;`

### 类属性表

最后是类属性表。由2个字节的属性数量和对应长度属性表信息组成。

属性信息的数据结构如下：

```
attribute_info {
    u2 attribute_name_index;
    u4 attribute_length;
    u1 info[attribute_length];
}
```
