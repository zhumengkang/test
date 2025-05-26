# Ubuntu Proot 环境安装器

## 项目简介
这是一个基于Proot的Ubuntu环境安装器，可以在任何Linux系统上快速部署一个完整的Ubuntu环境。该项目特别适用于需要在受限环境中运行完整Linux系统的场景。

## 功能特点
- 🚀 一键部署Ubuntu 24.04环境
- 🔧 自动检测系统架构（支持x86_64和aarch64）
- 🌐 内置中文环境支持
- 📦 预装50+常用软件包
- 🐳 集成Podman容器支持
- ⌨️ 完整的命令历史支持
- 🔄 智能下载（优先使用curl，自动切换到wget）
- 🎨 美观的命令行界面
- 🔍 命令自动补全功能

## 系统要求
- 任何Linux系统
- 至少1GB可用磁盘空间
- 网络连接

## 快速开始

### 一键安装
```bash
curl -L https://raw.githubusercontent.com/zhumengkang/test/main/install.sh | sh
```

### 手动安装
1. 下载安装脚本：
```bash
wget https://raw.githubusercontent.com/zhumengkang/test/main/install.sh
```

2. 添加执行权限：
```bash
chmod +x install.sh
```

3. 运行安装脚本：
```bash
./install.sh
```

## 使用方法

### 进入Ubuntu环境
```bash
./start.sh
```

### 退出Ubuntu环境
- 输入 `exit` 或按 `Ctrl+D`

### 常用命令
- 查看系统信息：`uname -a`
- 查看磁盘空间：`df -h`
- 查看内存使用：`free -h`
- 查看进程：`htop`
- 查看网络：`ip a`

### 使用技巧
- 使用上下键浏览历史命令
- 使用Tab键自动补全命令
- 使用Ctrl+C中断当前命令
- 使用 `ll` 查看详细文件列表
- 使用 `..` 返回上级目录

## 预装软件包
- 基础工具：curl, wget, git, vim, nano, htop, tmux, screen
- 开发工具：python3, nodejs, npm, build-essential, cmake, gcc, g++
- 网络工具：net-tools, iputils-ping, dnsutils
- 系统工具：sudo, locales, zip, unzip, tar, gzip, bzip2
- 容器工具：podman, podman-compose
- 其他工具：neofetch, bash-completion

## 目录结构
```
.
├── install.sh    # 安装脚本
├── start.sh      # 启动脚本
└── .installed    # 安装标记文件
```

## 常见问题

### 1. 安装失败
- 检查网络连接
- 确保有足够的磁盘空间
- 检查系统架构是否支持

### 2. 无法启动
- 确保start.sh有执行权限
- 检查.installed文件是否存在
- 检查proot是否正确安装

### 3. 中文显示问题
- 确保系统支持UTF-8
- 检查locale设置

## 作者信息
- 作者：康康
- Github：https://github.com/zhumengkang/
- YouTube：https://www.youtube.com/@康康的V2Ray与Clash
- Telegram：https://t.me/+WibQp7Mww1k5MmZl

## 许可证
Copyright (C) 2024, 康康

## 更新日志
- 2024-03-xx：初始版本发布
  - 支持Ubuntu 24.04
  - 添加中文环境支持
  - 集成Podman容器
  - 优化安装流程
