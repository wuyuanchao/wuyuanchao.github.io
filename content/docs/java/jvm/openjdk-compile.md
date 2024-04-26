---
title: "OpenJDK9 Compile"
weight: 1
# bookFlatSection: false
# bookToc: true
# bookHidden: false
# bookCollapseSection: false
# bookComments: false
# bookSearchExclude: false
---

# 编译OpenJDK

_这是一篇很久以前写的笔记，目前OpenJDK源码已经有github仓库了。获取源码后进入目录，然后一路 `sh ./configure` 根据提示安装依赖，最后 `make images`。愿一切顺利。_

_我在MAC下编译，唯一遇到的一个小障碍就是 `configure: error: XCode tool 'metal' neither found in path nor with xcrun` ，只要执行下 `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` 就可以解决了。这里 https://github.com/gfx-rs/gfx/issues/2309 有详细说明_

---------------------

学习jvm，有必要学会自己编译一个jdk。《深入理解java虚拟机》里的“实战：自己编译JDK”用的是OpenJDK7, 可能是因为环境的问题，按照书本上的指导我没有编译成功。于是果断上官网 [http://openjdk.java.net/](http://openjdk.java.net/) ，在[Developers' Guide](http://openjdk.java.net/guide/)里有详细的获取源码的教程。

为了避免不必要的坑，当然不会在windows下玩。我的环境是：Ubuntu 16.04.1 LTS

## 首先：获取源码

OpenJDK的代码管理用的是Mercurial，如果有git或svn经验，其实差不多。（可能是作者写书那会网络还不是很好，现在的网络已经可以分分钟搞定了，所以建议clone下来）。

Mercurial的安装参照官网 [https://www.mercurial-scm.org/wiki/Download](https://www.mercurial-scm.org/wiki/QuickStart)。因为我有pip所以就直接pip install Mercurial。然后检查下是否安装成功。

```
$ hg version

# Output：
# Mercurial Distributed SCM (version 4.1)
```

按照手册上说：Mercurial安装好就可以clone了，除非你想提交代码，那需要配置~/.hgrc。现在只是学习源码，就免了。

> A Mercurial installation is sufficient to clone a repository. Contributors who wish to submit changes will need some additional configuration as described below.

安装好以后就能直接下载代码了（熟悉git的能看到就是把git变成了hg）：

```
$ hg clone http://hg.openjdk.java.net/jdk9/dev 9dev

```

因为jdk是个森林(forest)，所以上一步我们clone的是主树(main tree)。

官网手册里可以hg tclone，可能我的Mercurial装的版本问题，没有tclone这个命令，不深究。

> _hg: unknown command 'tclone'  
> (did you mean clone?)_

接下来需要使用get_source.sh来获取整个森林。

```
$ cd 9dev
$ sh ./get_source.sh
```

由于网络的原因，一开始我没全部clone下来。会有如下提醒信息(截取部分)：

>                  ......
> 
>                   jdk:   transaction abort!  
>                   jdk:   rollback completed  
>                   jdk:   abort: stream ended unexpectedly (got 173 bytes, expected 327)
> 
>                   ......
> 
> WARNING: hotspot exited abnormally (255)  
> WARNING: jdk exited abnormally (255)  
> WARNING: nashorn exited abnormally (255)

我没有注意，直接make了。报了错才发现没有jdk这个目录，jdk根本没有下下来。

> /bin/bash: line 0: cd: /happynewyear/jdksrc/9dev/jdk/make: No such file or directory  
> make/Main.gmk:81: recipe for target 'interim-cldrconverter' failed  
> make\[2\]: *** \[interim-cldrconverter\] Error 1

不停地试了很多遍才全部下载完成。

## 然后：编译

当你获得源码后，首先应该看的是README。里面有简单的介绍：

>  Simple Build Instructions:  
>    
>     0\. Get the necessary system software/packages installed on your system, see  
>        http://hg.openjdk.java.net/jdk9/jdk9/raw-file/tip/README-builds.html  
>    
>     1\. If you don't have a jdk8 or newer jdk, download and install it from  
>        http://java.sun.com/javase/downloads/index.jsp  
>        Add the /bin directory of this installation to your PATH environment  
>        variable.  
>    
>     2\. Configure the build:  
>          bash ./configure  
>    
>     3\. Build the OpenJDK:  
>          make all  
>        The resulting JDK image should be found in build/*/images/jdk  
>    
>   where make is GNU make 3.81 or newer, /usr/bin/make on Linux usually  
>   is 3.81 or newer. Note that on Solaris, GNU make is called "gmake".

Ant已经不需要了，ALT_*配置也不再支持。 所以书上的一大堆环境变量的配置，全部忽略。

>     \* Ant is no longer used when building the OpenJDK  
>     \* Use of ALT_* environment variables for configuring the build is no longer  
>       supported

大胆的 bash ./configure，缺什么都会有提示。

比如需要jdk8或者9：

> configure: Found potential Boot JDK using java(c) in PATH  
> configure: Potential Boot JDK found at /opt/jdk1.7.0\_71 is incorrect JDK version (java version "1.7.0\_71"); ignoring  
> configure: (Your Boot JDK must be version 8 or 9)  
> configure: Could not find a valid Boot JDK. You might be able to fix this by running 'sudo apt-get install openjdk-8-jdk'.  
> configure: This might be fixed by explicitly setting --with-boot-jdk  
> configure: error: Cannot continue  
> configure exiting with result code 1

比如需要 sudo apt-get install libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev

> configure: error: Could not find X11 libraries. You might be able to fix this by  
> running 'sudo apt-get install libx11-dev libxext-dev libxrender-dev libxtst-dev  
> libxt-dev'.  
> configure exiting with result code 1

比如需要 sudo apt-get install libcups2-dev

> configure: error: Could not find cups! You might be able to fix this by running  
> 'sudo apt-get install libcups2-dev'.  
> configure exiting with result code 1

比如需要 sudo apt-get install libfreetype6-dev

> configure: error: Could not find freetype! You might be able to fix this by running 'sudo apt-get install libfreetype6-dev'.  
> configure exiting with result code 1 

比如需要 sudo apt-get install libasound2-dev

>  configure: error: Could not find alsa! You might be able to fix this by running 'sudo apt-get install libasound2-dev'.  
> configure exiting with result code 1

当然，你可以在这之前都把所有的依赖安装好。

```
sudo apt-get install libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev libcups2-dev libfreetype6-dev libasound2-dev
```

或者可以试试build-essential包（未验证，讲道理应该可以）：

```
$ sudo apt-get install build-essential
```

最后，所有的检查都通过以后，我们就可以进行make了。

make需要花点时间，耐性等待。成功后有如下提示：

> Finished building target 'default (exploded-image)' in configuration 'linux-x86_64-normal-server-release'

##  最后：测试

进入build目录，找到jdk，然后./java --version检查是否

```
cd  build/linux-x86_64-normal-server-release/jdk
./bin/java --version
```

得到如下输出：

> openjdk 9-internal  
> OpenJDK Runtime Environment (build 9-internal+0-adhoc.wuyc.9dev)  
> OpenJDK 64-Bit Server VM (build 9-internal+0-adhoc.wuyc.9dev, mixed mode)

 可以看到自己的用户名，顺利完成作业。
