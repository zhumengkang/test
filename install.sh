#!/bin/sh

# 作者信息
printf "\033[36m┌────────────────────────────────────────────────────────┐\033[0m\n"
printf "\033[36m│ \033[32m作者: 康康                                                  \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mGithub: https://github.com/zhumengkang/                    \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mYouTube: https://www.youtube.com/@康康的V2Ray与Clash         \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mTelegram: https://t.me/+WibQp7Mww1k5MmZl                   \033[36m│\033[0m\n"
printf "\033[36m└────────────────────────────────────────────────────────┘\033[0m\n"

# 关键：使用与freeroot相同的目录结构
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin:~/.local/bin
max_retries=50
timeout=30
ARCH=$(uname -m)

# 架构检测（完全按照freeroot的方式）
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# 显示安装信息并询问
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                           Ubuntu 环境一键安装器"
  echo "#"
  echo "#                      Copyright (C) 2024, 康康修改版"
  echo "#"
  echo "#######################################################################################"
  
  read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu
fi

# 安装Ubuntu基础系统（完全按照freeroot的逻辑）
case $install_ubuntu in
  [yY][eE][sS]|"")
    echo "开始下载Ubuntu基础系统..."
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    
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
    ;;
esac

# 安装proot（按照freeroot的方式，但支持多源）
if [ ! -e $ROOTFS_DIR/.installed ]; then
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
fi

# 基础配置（按照freeroot的方式）
if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 8.8.8.8" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.gz /tmp/sbin
  touch $ROOTFS_DIR/.installed
  echo "✓ 基础配置完成"
fi

# 创建启动脚本（简化版）
cat > start-ubuntu.sh << 'EOF'
#!/bin/sh
ROOTFS_DIR=$(pwd)

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "Ubuntu环境未正确安装"
  exit 1
fi

echo "启动Ubuntu环境..."
export TERM=xterm-256color

$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
  /bin/bash --login
EOF

chmod +x start-ubuntu.sh

# 创建软件包安装脚本
cat > setup-ubuntu.sh << 'EOF'
#!/bin/sh
ROOTFS_DIR=$(pwd)

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "Ubuntu环境未正确安装"
  exit 1
fi

echo "配置Ubuntu环境..."

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
  zip unzip sudo locales tree

echo "配置语言环境..."
locale-gen en_US.UTF-8

echo "配置bash环境..."
cat >> /root/.bashrc << "BASHRC_END"

# 自定义配置
export LANG=en_US.UTF-8
PS1="\[\033[01;32m\]\u@ubuntu\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

# 别名
alias ll="ls -la --color=auto"
alias la="ls -a --color=auto"
alias ls="ls --color=auto"
alias ..="cd .."

# 欢迎信息
if [ -t 0 ]; then
  clear
  echo "════════════════════════════════════════"
  echo "       欢迎使用 Ubuntu 环境"
  echo "════════════════════════════════════════"
  echo "系统信息:"
  uname -a
  echo ""
  echo "可用工具: git, vim, htop, python3, node"
  echo "退出环境: exit 或 Ctrl+D"
  echo "════════════════════════════════════════"
fi
BASHRC_END

apt clean
echo "✓ Ubuntu环境配置完成！"
'
EOF

chmod +x setup-ubuntu.sh

# 显示完成信息
echo "════════════════════════════════════════════════════════════════"
echo "                        安装完成！"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "使用步骤:"
echo "1. 首次配置环境: ./setup-ubuntu.sh"
echo "2. 启动Ubuntu环境: ./start-ubuntu.sh"
echo "3. 退出Ubuntu环境: exit 或 Ctrl+D"
echo ""
echo "提示: 首次使用前请先运行 ./setup-ubuntu.sh"
echo ""

# 询问是否立即配置
read -p "是否现在就配置Ubuntu环境？(y/n): " response
case $response in
  [yY]|[yY][eE][sS])
    echo ""
    echo "开始配置Ubuntu环境..."
    ./setup-ubuntu.sh
    echo ""
    echo "✓ 配置完成！现在可以运行 ./start-ubuntu.sh 启动Ubuntu环境"
    ;;
  *)
    echo "配置已跳过，稍后可手动运行 ./setup-ubuntu.sh"
    ;;
esac
