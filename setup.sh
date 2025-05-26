#!/bin/sh

# 创建安装目录
mkdir -p ~/ubuntu-rootfs
cd ~/ubuntu-rootfs

# 下载安装脚本
curl -L -o install.sh https://raw.githubusercontent.com/zhumengkang/test/main/install.sh
chmod +x install.sh

# 执行安装脚本
./install.sh
