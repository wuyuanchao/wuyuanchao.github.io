---
title: "Special Characters in Shell"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

The >, >>, &, && and || characters are extremely useful whenever you're working on the Linux command line.

https://www.networkworld.com/article/972419/the-power-of-and-on-linux.html

## >

覆盖输出到文件。如果文件已存在，会先清空文件，然后将内容输出到文件。
```
$ echo hello > world
$ echo hello > world
$ cat world
hello
```
注意，只会有一个hello

如果要清空文件：
```
cat /dev/null > report
```

## >>

追加输出到文件。将内容追加到文件末尾。

```
$ echo "My Report" > report
$ date >> report
$ cat report
My Report
Tue Apr 16 22:14:49 CST 2024
```

## &

让任务后台运行。可以使用`jobs`查看运行的任务。使用`fg`将后台任务唤起到前台。

```
$ bigjob &
[1] 4092
$ jobs
[1]+  Running                 bigjob &
$ fg %1
bigjob
```

## &&

只有前面的命令执行成功了，后面的命令才会执行。

```
$ ping 192.168.0.1 && echo router is reachable
router is reachable
```

## ||

如果前面的命令执行成功了，后面的命令就不执行。

```
$ [ -d scripts ] || mkdir scripts
$ ls -ld scripts
drwxrwxr-x 2 shs shs 4096 Jul  8 12:24 scripts
```

## !
在进行条件测试时取反。

```
$ [ ! -f donuts ] && echo "We need donuts!"
```

[]是测试操作，成功返回0。可以使用 `echo $?` 命令查看上一条命令的结果

## $()
命令替换
```
% echo "my hostname is: $(hostname)"
my hostname is: yuanchaodeMacBook-Pro.local
```

## $(( ))
算术展开(arithmetic expansion)
```
$ echo "$(( 5 + 5 ))"
10
```

## ${ }
引用变量并避免名称混淆
```
% v="hello"
% echo "$v"
hello
% echo "$vbye"

% echo "${v}bye"
hellobye
```

