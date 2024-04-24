---
title: "Ffmpeg"
date: 2024-04-24T22:58:10+08:00
# bookComments: false
# bookSearchExclude: false
---

ffmpeg是工作中我们经常用于音视频处理的工具。
最近在为孩子做点读笔音频时，也遇到需要转换音频格式的情况。
于是在自己的mac上安装了一个：

```
brew install ffmpeg
```

接着我们就可以用一个脚本，让电脑批量处理一大堆文件，自己边上喝个咖啡坐等完成就行。
```
#!/bin/bash

# 设置要转换的目录路径
input_dir="."

# 确保目录存在
if [ ! -d "$input_dir" ]; then
    echo "输入目录不存在！"
    exit 1
fi

# 进入输入目录
cd "$input_dir" || exit

# 遍历目录中的所有 WAV 文件
for file in *.wav; do
    # 检查文件是否存在并且是文件
    if [ -f "$file" ]; then
        # 构建输出文件名，将.wav替换为.mp3
        output_file="${file%.wav}.mp3"
        # 使用 ffmpeg 进行转换
        ffmpeg -i "$file" "$output_file"
        echo "已转换文件: $file -> $output_file"
    fi
done

echo "转换完成！"
```

官网：https://ffmpeg.org/

> Converting video and audio has never been so easy.
>
> ```
> $ ffmpeg -i input.mp4 output.avi
> ```
