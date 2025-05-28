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
max_retries=5
timeout=30
ARCH=$(uname -m)

# 架构检测
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

# 检查wget版本并设置合适的参数
WGET_OPTS="--tries=$max_retries --timeout=$timeout"
if wget --help | grep -q -- '--no-hsts'; then
    WGET_OPTS="$WGET_OPTS --no-hsts"
fi

# 检查是否是首次安装
if [ ! -e $ROOTFS_DIR/.installed ]; then
  show_banner
  
  echo "##############################################################################"
  echo "#"
  echo "#                         Ubuntu 20.04 环境一键安装器"
  echo "#"
  echo "#                        Copyright (C) 2024, 康康修改版"
  echo "#"
  echo "##############################################################################"
  
  read -p "Do you want to install Ubuntu 20.04? (YES/no): " install_ubuntu
  
  # 安装Ubuntu基础系统
  case $install_ubuntu in
    [yY][eE][sS]|"")
      echo "开始下载Ubuntu 20.04基础系统..."
      
      # Ubuntu 20.04 下载源
      UBUNTU_URLS="
      https://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz
      https://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.3-base-${ARCH_ALT}.tar.gz
      https://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.2-base-${ARCH_ALT}.tar.gz
      "
      
      DOWNLOAD_SUCCESS=0
      for url in $UBUNTU_URLS; do
        echo "尝试下载: $url"
        if wget $WGET_OPTS -O /tmp/rootfs.tar.gz "$url"; then
          if [ -s /tmp/rootfs.tar.gz ] && file /tmp/rootfs.tar.gz | grep -q "gzip compressed"; then
            echo "✓ Ubuntu 20.04基础系统下载成功"
            DOWNLOAD_SUCCESS=1
            break
          else
            echo "下载的文件无效，尝试下一个源..."
            rm -f /tmp/rootfs.tar.gz
          fi
        else
          echo "下载失败，尝试下一个源..."
          rm -f /tmp/rootfs.tar.gz
        fi
      done
      
      if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
        echo "✗ 所有Ubuntu基础系统下载源都失败了"
        exit 1
      fi
      
      echo "解压Ubuntu基础系统..."
      if tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR; then
        echo "✓ Ubuntu基础系统安装完成"
      else
        echo "✗ Ubuntu基础系统解压失败"
        exit 1
      fi
      ;;
    *)
      echo "跳过Ubuntu安装."
      exit 0
      ;;
  esac

  # 安装proot
  mkdir -p $ROOTFS_DIR/usr/local/bin
  
  echo "下载proot工具..."
  
  # proot下载源列表
  PROOT_URLS="
  https://raw.githubusercontent.com/zhumengkang/test/main/proot-${ARCH}
  https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}
  https://github.com/proot-me/proot/releases/download/v5.3.0/proot-v5.3.0-${ARCH}
  "
  
  PROOT_SUCCESS=0
  for url in $PROOT_URLS; do
    echo "尝试下载proot: $url"
    if wget $WGET_OPTS -O $ROOTFS_DIR/usr/local/bin/proot "$url"; then
      if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
        chmod 755 $ROOTFS_DIR/usr/local/bin/proot
        echo "✓ proot下载成功"
        PROOT_SUCCESS=1
        break
      else
        echo "proot下载失败，尝试下一个源..."
        rm -f $ROOTFS_DIR/usr/local/bin/proot
      fi
    else
      echo "下载失败，尝试下一个源..."
      rm -f $ROOTFS_DIR/usr/local/bin/proot
    fi
  done
  
  if [ $PROOT_SUCCESS -eq 0 ]; then
    echo "✗ 所有proot下载源都失败了"
    exit 1
  fi

  # 基础配置
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 8.8.8.8\n" > ${ROOTFS_DIR}/etc/resolv.conf
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

  apt clean
  echo "✓ Ubuntu环境配置完成！"
  '

  printf "\033[1;36m✓ 安装完成!\033[0m\n\n"
fi

# 检查环境是否已安装
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "Ubuntu环境未正确安装，请重新运行安装脚本"
  exit 1
fi

# 检查proot是否存在
if [ ! -f "$ROOTFS_DIR/usr/local/bin/proot" ]; then
  echo "✗ proot文件不存在，请重新安装"
  exit 1
fi

# 检查proot是否可执行
if ! chmod +x "$ROOTFS_DIR/usr/local/bin/proot" 2>/dev/null; then
  echo "✗ 无法设置proot执行权限"
  exit 1
fi

# 启动Ubuntu环境并显示欢迎信息
echo "启动Ubuntu 20.04环境..."
export TERM=xterm-256color

# 测试proot是否工作
echo "正在测试proot..."
if ! "$ROOTFS_DIR/usr/local/bin/proot" --help >/dev/null 2>&1; then
  echo "✗ proot无法正常运行，可能需要重新下载"
  exit 1
fi

echo "✓ proot测试通过，正在进入环境..."

exec "$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
  /bin/bash -c '
# 设置语言环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 自定义PS1
export PS1="\[\033[01;32m\]\u@ubuntu-20.04\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

# 设置别名
alias ll="ls -la --color=auto"
alias la="ls -a --color=auto" 
alias ls="ls --color=auto"
alias ..="cd .."
alias ...="cd ../.."
alias grep="grep --color=auto"
alias h="history"
alias c="clear"

# 清屏并显示欢迎信息
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
printf "\033[1;36m欢迎进入Ubuntu 20.04环境!\033[0m\n\n"

echo "════════════════════════════════════════════════════════════════"
echo "                        使用说明"
echo "════════════════════════════════════════════════════════════════"
printf "\033[1;32m重新进入环境:\033[0m 再次运行此脚本\n"
printf "\033[1;31m退出环境:\033[0m exit 或按 Ctrl+D\n"
echo "════════════════════════════════════════════════════════════════"
echo "系统信息:"
if [ -f /etc/os-release ]; then
  cat /etc/os-release | grep PRETTY_NAME
else
  echo "Ubuntu 20.04 LTS (PRoot Environment)"
fi
echo "架构: $(uname -m)"
echo "当前目录: $(pwd)"
echo "可用工具: git, vim, htop, python3, node, curl, wget"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 进入交互式bash
exec /bin/bash --login
'
