FFmpeg README
=============

FFmpeg是一个处理多媒体内容的库和工具的集合，如音频、视频、字幕和相关元数据。
此项目在FFmpeg源码的基础上，根据需求做了定制化修改。

## 功能

1. H264软编码 - x264
2. H264硬编解码 - h264_nvenc / h264_cuvid
3. H265软编码 - x265
4. H265硬编解码 - hevc_nvenc / hevc_cuvid
5. XAVC Intra Class 300编码
6. AVS软编码 - xavs
7. AVS2软编解码 - xavs2 / davs2

## 说明

1. 以上库以静态库的形式链接到FFmpeg
2. 去掉了libpostproc的编译
3. 使用的FFmpeg版本为**release/4.2**

## 编译步骤(仅支持Linux)

可选择本地编译或者使用docker容器编译

### dokcer镜像（可选）

由于需要支持硬件编解码功能，编译环境需要安装cuda，推荐使用**nvidia/cuda**的镜像进行编译。

```bash
# 启动容器，挂载路径
docker run -it -v ~/FFmpeg/:/FFmpeg nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04 /bin/bash
```

### 安装相关软件

```bash
sudo apt update
sudo apt install -y pkg-config build-essential cmake nasm yasm
```

### 执行脚本编译安装
```bash
cd FFmpeg
./build_linux.sh
```
