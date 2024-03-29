+++
title = 'Vim Nerdtree'
date = 2024-03-29T09:39:42+08:00
+++

The NERDTree allows you to explore your filesystem and to open files and
directories.

#### 1. 刷新NERDTree窗口:
- r命令：刷新光标当前所在的目录。
- R命令：刷新根目录。

#### 2. 打开文件但是光标仍然停留在NERDTree窗口
- 在NERDTree窗口中，移动光标到你想要打开的文件上。
- 按go键。

#### 3. 显示隐藏文件
- 按I键进行切换
- 在`.vimrc` 中添加 `let NERDTreeShowHidden=1`

