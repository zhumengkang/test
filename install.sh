#!/bin/sh

# 显示作者信息的函数
show_banner() {
    printf "\n\033[1;36m################################################################################\033[0m\n"
    printf "\033[1;33m#                                                                              #\033[0m\n"
    printf "\033[1;33m#   \033[1;35m作者: 康康\033[1;33m                                                            #\033[0m\n"
    printf "\033[1;33m#   \033[1;34mGithub: https://github.com/zhumengkang/\033[1;33m                              #\033[0m\n"
    printf "\033[1;33m#   \033[1;31mYouTube: https://www.youtube.com/@康康的V2Ray与Clash\033[1;33m                  #\033[0m\n"
    printf "\033[1;33m#   \033[1;36mTelegram: https://t.me/+WibQp7Mww1k5MmZl\033[1;33m                           #\033[0m\n"
    printf "\033[1;33m#                                                                              #\033[0m\n"
    printf "\033[1;33m################################################################################\033[0m\n"
    printf "\033[1;32m\n★ YouTube请点击关注!\033[0m\n"
    printf "\033[1;32m★ Github请点个Star支持!\033[0m\n\n"
}

# 关键：使用与freeroot相同的目录结构
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin:~/.local/bin
max_retries=50
timeout=30
ARCH=$(uname -m)

# 架构检测
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# 检查是否是首次安装
if [ ! -e $ROOTFS_DIR/.installed ]; then
  show_banner
  
  echo "##############################################################################"
  echo "#"
  echo "#                         Ubuntu 24.04 环境一键安装器"
  echo "#"
  echo "#                        Copyright (C) 2024, 康康修改版"
  echo "#"
  echo "##############################################################################"
  
  read -p "Do you want to install Ubuntu 24.04? (YES/no): " install_ubuntu
  
  # 安装Ubuntu基础系统
  case $install_ubuntu in
    [yY][eE][sS]|"")
      echo "开始下载Ubuntu 24.04基础系统..."
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "https://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
      
      if [ -s /tmp/rootfs.tar.gz ]; then
        echo "解压Ubuntu基础系统..."
        tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
        echo "✓ Ubuntu基础系统安装完成"
      else
        echo "✗ Ubuntu基础系统下载失败"
        exit 1
      fi
      ;;
    *)
      echo "跳过Ubuntu安装."
      exit 0
      ;;
  esac

  # 安装proot
  mkdir $ROOTFS_DIR/usr/local/bin -p
  
  echo "下载proot工具..."
  # 首先尝试康康的源
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/zhumengkang/test/main/proot-${ARCH}"
  
  # 检查下载是否成功，如果不成功则尝试freeroot的源
  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm $ROOTFS_DIR/usr/local/bin/proot -rf
    echo "尝试备用源下载proot..."
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
    
    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      echo "✓ proot下载成功"
      break
    fi
    
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    sleep 1
  done
  
  chmod 755 $ROOTFS_DIR/usr/local/bin/proot

  # 基础配置
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 8.8.8.8" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.gz /tmp/sbin
  
  # 创建初始化标记
  touch $ROOTFS_DIR/.installed
  echo "✓ 基础配置完成"

  # 首次安装后自动配置环境
  echo "正在配置Ubuntu环境，请稍候..."
  
  $ROOTFS_DIR/usr/local/bin/proot \
    --rootfs="${ROOTFS_DIR}" \
    -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
    /bin/bash -c '
  echo "更新软件源..."
  apt update

  echo "安装基础软件包..."
  DEBIAN_FRONTEND=noninteractive apt install -y \
    curl wget git vim nano htop tmux \
    python3 python3-pip nodejs npm \
    build-essential net-tools \
    zip unzip sudo locales tree \
    ca-certificates gnupg lsb-release

  echo "配置语言环境..."
  locale-gen en_US.UTF-8

  echo "配置bash环境..."
  cat > /root/.bashrc << "BASHRC_END"
# ~/.bashrc: executed by bash(1) for non-login shells.

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 自定义PS1
PS1="\[\033[01;32m\]\u@ubuntu-24.04\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

# 别名
alias ll="ls -la --color=auto"
alias la="ls -a --color=auto"
alias ls="ls --color=auto"
alias ..="cd .."
alias ...="cd ../.."
alias grep="grep --color=auto"
alias h="history"
alias c="clear"

# 欢迎信息
if [ -t 0 ]; then
  clear
  printf "\n\033[1;36m################################################################################\033[0m\n"
  printf "\033[1;33m#                                                                              #\033[0m\n"
  printf "\033[1;33m#   \033[1;35m作者: 康康\033[1;33m                                                            #\033[0m\n"
  printf "\033[1;33m#   \033[1;34mGithub: https://github.com/zhumengkang/\033[1;33m                              #\033[0m\n"
  printf "\033[1;33m#   \033[1;31mYouTube: https://www.youtube.com/@康康的V2Ray与Clash\033[1;33m                  #\033[0m\n"
  printf "\033[1;33m#   \033[1;36mTelegram: https://t.me/+WibQp7Mww1k5MmZl\033[1;33m                           #\033[0m\n"
  printf "\033[1;33m#                                                                              #\033[0m\n"
  printf "\033[1;33m################################################################################\033[0m\n"
  printf "\033[1;32m\n★ YouTube请点击关注!\033[0m\n"
  printf "\033[1;32m★ Github请点个Star支持!\033[0m\n\n"
  printf "\033[1;36m欢迎进入Ubuntu 24.04环境!\033[0m\n\n"
  
  echo "════════════════════════════════════════════════════════════════"
  echo "                        使用说明"
  echo "════════════════════════════════════════════════════════════════"
  printf "\033[1;32m进入环境:\033[0m ./root.sh\n"
  printf "\033[1;31m退出环境:\033[0m exit 或按 Ctrl+D\n"
  echo "════════════════════════════════════════════════════════════════"
  echo "系统信息:"
  cat /etc/os-release | grep PRETTY_NAME
  echo "架构: $(uname -m)"
  echo "可用工具: git, vim, htop, python3, node, curl, wget"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
fi
BASHRC_END

  apt clean
  echo "✓ Ubuntu环境配置完成！"
  '

  printf "\033[1;36m安装完成!即将进入Ubuntu 24.04环境...\033[0m\n\n"
  sleep 2
fi

# 检查环境是否已安装
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "Ubuntu环境未正确安装，请重新运行安装脚本"
  exit 1
fi

# 启动Ubuntu环境
echo "启动Ubuntu 24.04环境..."
export TERM=xterm-256color

$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
  /bin/bash --login
