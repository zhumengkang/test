#!/bin/sh

# 作者信息
echo "\033[36m┌────────────────────────────────────────────────────────┐\033[0m"
echo "\033[36m│ \033[32m作者: 康康                                                  \033[36m│\033[0m"
echo "\033[36m│ \033[32mGithub: https://github.com/zhumengkang/                    \033[36m│\033[0m"
echo "\033[36m│ \033[32mYouTube: https://www.youtube.com/@康康的V2Ray与Clash         \033[36m│\033[0m"
echo "\033[36m│ \033[32mTelegram: https://t.me/+WibQp7Mww1k5MmZl                   \033[36m│\033[0m"
echo "\033[36m└────────────────────────────────────────────────────────┘\033[0m"

# 设置基本变量
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

# 检测系统架构
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
  PROOT_URL="https://raw.githubusercontent.com/zhumengkang/test/main/proot-x86_64"
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
  PROOT_URL="https://raw.githubusercontent.com/zhumengkang/test/main/proot-aarch64"
else
  printf "不支持的CPU架构: ${ARCH}\n"
  exit 1
fi

# 下载函数
download_file() {
  local url=$1
  local output=$2
  
  # 首先尝试使用curl
  if command -v curl >/dev/null 2>&1; then
    curl -L --retry $max_retries --retry-delay 1 --connect-timeout $timeout -o "$output" "$url" && return 0
  fi
  
  # 如果curl失败或不存在，尝试使用wget
  if command -v wget >/dev/null 2>&1; then
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$output" "$url" && return 0
  fi
  
  return 1
}

# 检查是否已安装
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                    Ubuntu 环境安装器"
  echo "#"
  echo "#                           Copyright (C) 2024, 康康"
  echo "#"
  echo "#"
  echo "#######################################################################################"

  # 下载并解压Ubuntu基础系统
  echo "正在下载Ubuntu基础系统..."
  download_file "http://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04-base-${ARCH_ALT}.tar.gz" "/tmp/rootfs.tar.gz"
  tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR

  # 下载proot
  echo "正在下载proot..."
  mkdir -p $ROOTFS_DIR/usr/local/bin
  download_file "$PROOT_URL" "$ROOTFS_DIR/usr/local/bin/proot"

  # 确保proot下载成功并设置权限
  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    echo "proot下载失败，正在重试..."
    rm -f $ROOTFS_DIR/usr/local/bin/proot
    download_file "$PROOT_URL" "$ROOTFS_DIR/usr/local/bin/proot"
    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi
    sleep 1
  done

  # 设置DNS
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  
  # 创建安装标记文件
  touch $ROOTFS_DIR/.installed
fi

# 定义颜色
CYAN='\e[0;36m'
WHITE='\e[0;37m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
RESET_COLOR='\e[0m'

# 显示使用说明
display_usage() {
  echo -e "\n${YELLOW}使用说明：${RESET_COLOR}"
  echo -e "${WHITE}1. 进入root终端：${RESET_COLOR}"
  echo -e "   ${GREEN}./start.sh${RESET_COLOR}"
  echo -e "${WHITE}2. 退出root终端：${RESET_COLOR}"
  echo -e "   ${GREEN}输入 'exit' 或按 Ctrl+D${RESET_COLOR}"
  echo -e "${WHITE}3. 常用命令：${RESET_COLOR}"
  echo -e "   ${GREEN}• 查看系统信息：uname -a${RESET_COLOR}"
  echo -e "   ${GREEN}• 查看磁盘空间：df -h${RESET_COLOR}"
  echo -e "   ${GREEN}• 查看内存使用：free -h${RESET_COLOR}"
  echo -e "   ${GREEN}• 查看进程：htop${RESET_COLOR}"
  echo -e "   ${GREEN}• 查看网络：ip a${RESET_COLOR}"
  echo -e "\n${YELLOW}提示：${RESET_COLOR}"
  echo -e "${WHITE}• 使用上下键可以浏览历史命令${RESET_COLOR}"
  echo -e "${WHITE}• 使用Tab键可以自动补全命令${RESET_COLOR}"
  echo -e "${WHITE}• 使用Ctrl+C可以中断当前命令${RESET_COLOR}"
}

# 显示完成信息
display_complete() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${GREEN}-----> 安装完成 ! <----${RESET_COLOR}"
  echo -e ""
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
}

# 创建启动脚本
cat > start.sh << 'EOF'
#!/bin/sh
ROOTFS_DIR=$(pwd)
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
EOF
chmod +x start.sh

# 清理屏幕并显示完成信息
clear
display_complete
display_usage

# 启动proot环境并安装常用软件包
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
  /bin/sh -c '
    # 更新软件源
    apt update && apt upgrade -y
    
    # 安装常用软件包
    apt install -y curl wget git vim nano htop tmux screen \
    python3 python3-pip nodejs npm \
    build-essential cmake gcc g++ make \
    net-tools iputils-ping dnsutils \
    zip unzip tar gzip bzip2 \
    openssh-server openssh-client \
    sudo locales \
    podman podman-compose \
    readline-common readline-doc \
    bash-completion \
    neofetch \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*
    
    # 设置中文环境
    locale-gen zh_CN.UTF-8
    update-locale LANG=zh_CN.UTF-8
    
    # 配置命令历史
    echo "HISTSIZE=10000" >> /root/.bashrc
    echo "HISTFILESIZE=10000" >> /root/.bashrc
    echo "HISTCONTROL=ignoreboth" >> /root/.bashrc
    echo "shopt -s histappend" >> /root/.bashrc
    
    # 配置bash自动补全
    echo "if [ -f /etc/bash_completion ]; then" >> /root/.bashrc
    echo "    . /etc/bash_completion" >> /root/.bashrc
    echo "fi" >> /root/.bashrc
    
    # 配置命令提示符
    echo "PS1=\"\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ \"" >> /root/.bashrc
    
    # 配置别名
    echo "alias ll=\"ls -la\"" >> /root/.bashrc
    echo "alias la=\"ls -a\"" >> /root/.bashrc
    echo "alias l=\"ls -l\"" >> /root/.bashrc
    echo "alias ..=\"cd ..\"" >> /root/.bashrc
    echo "alias ...=\"cd ../..\"" >> /root/.bashrc
    
    # 配置podman
    podman --version
    
    # 设置默认shell为bash
    chsh -s /bin/bash root
    
    # 显示系统信息
    neofetch
    
    # 启动bash
    exec /bin/bash
  '
