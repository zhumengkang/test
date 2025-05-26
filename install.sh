#!/bin/sh

# 作者信息
printf "\033[36m┌────────────────────────────────────────────────────────┐\033[0m\n"
printf "\033[36m│ \033[32m作者: 康康                                                  \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mGithub: https://github.com/zhumengkang/                    \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mYouTube: https://www.youtube.com/@康康的V2Ray与Clash         \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mTelegram: https://t.me/+WibQp7Mww1k5MmZl                   \033[36m│\033[0m\n"
printf "\033[36m└────────────────────────────────────────────────────────┘\033[0m\n"

# 设置基本变量
ROOTFS_DIR=$(pwd)/ubuntu-rootfs
export PATH=$PATH:~/.local/usr/bin:~/.local/bin
max_retries=50
timeout=30
ARCH=$(uname -m)

# 定义颜色函数
print_red() { printf "\033[0;31m%s\033[0m\n" "$1"; }
print_green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
print_yellow() { printf "\033[1;33m%s\033[0m\n" "$1"; }
print_blue() { printf "\033[0;34m%s\033[0m\n" "$1"; }
print_cyan() { printf "\033[0;36m%s\033[0m\n" "$1"; }
print_white() { printf "\033[1;37m%s\033[0m\n" "$1"; }

# 检测系统架构
print_blue "检测系统架构..."
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
    PROOT_ARCH=x86_64
    print_green "✓ 检测到 x86_64 架构"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_ALT=arm64
    PROOT_ARCH=aarch64
    print_green "✓ 检测到 aarch64 架构"
else
    print_red "✗ 不支持的CPU架构: ${ARCH}"
    exit 1
fi

# 安装确认
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    print_white "#######################################################################################"
    print_white "#"
    print_white "#                           Ubuntu 环境一键安装器"
    print_white "#"
    print_white "#                          免root权限 - 基于proot技术"
    print_white "#"
    print_white "#######################################################################################"
    printf "\n"
    
    printf "是否要安装Ubuntu环境？(YES/no): "
    read install_ubuntu
    
    case $install_ubuntu in
        [nN][oO]|[nN])
            print_yellow "取消安装"
            exit 0
            ;;
    esac
fi

# 安装Ubuntu基础系统
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    print_blue "创建安装目录..."
    mkdir -p "$ROOTFS_DIR"
    
    print_blue "下载Ubuntu基础系统..."
    # 使用Ubuntu 20.04 LTS（更稳定）
    ubuntu_url="http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz "$ubuntu_url"
    
    if [ ! -s "/tmp/rootfs.tar.gz" ]; then
        print_red "✗ Ubuntu基础系统下载失败"
        exit 1
    fi
    
    print_blue "解压Ubuntu基础系统..."
    tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
    
    if [ $? -ne 0 ]; then
        print_red "✗ Ubuntu基础系统解压失败"
        exit 1
    fi
    
    rm -f /tmp/rootfs.tar.gz
    print_green "✓ Ubuntu基础系统安装完成"
fi

# 安装proot
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    print_blue "下载proot工具..."
    mkdir -p "$ROOTFS_DIR/usr/local/bin"
    
    # 尝试多个proot源
    proot_urls=(
        "https://raw.githubusercontent.com/zhumengkang/test/main/proot-${PROOT_ARCH}"
        "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${PROOT_ARCH}"
        "https://github.com/proot-me/proot/releases/latest/download/proot-${PROOT_ARCH}"
    )
    
    proot_downloaded=0
    for url in "${proot_urls[@]}"; do
        print_yellow "尝试从: $url"
        wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" "$url"
        
        if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
            chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
            proot_downloaded=1
            print_green "✓ proot下载成功"
            break
        else
            rm -f "$ROOTFS_DIR/usr/local/bin/proot"
            print_yellow "⚠ 当前源下载失败，尝试下一个源..."
        fi
    done
    
    if [ $proot_downloaded -eq 0 ]; then
        print_red "✗ 所有proot源都下载失败"
        exit 1
    fi
    
    # 额外的权限设置和备份
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
    
    # 创建本地备份
    mkdir -p "$HOME/.local/bin"
    cp "$ROOTFS_DIR/usr/local/bin/proot" "$HOME/.local/bin/proot" 2>/dev/null || true
    chmod 755 "$HOME/.local/bin/proot" 2>/dev/null || true
fi

# 基础配置
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    print_blue "配置基础环境..."
    
    # 配置DNS
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 8.8.8.8\n" > "${ROOTFS_DIR}/etc/resolv.conf"
    
    # 创建必要目录
    mkdir -p "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/root" "$ROOTFS_DIR/home"
    
    # 清理临时文件
    rm -rf /tmp/rootfs.tar.gz /tmp/sbin 2>/dev/null || true
    
    # 创建安装标记
    touch "$ROOTFS_DIR/.installed"
    print_green "✓ 基础配置完成"
fi

# 创建启动脚本
print_blue "创建启动脚本..."
cat > "start-ubuntu.sh" << 'EOF'
#!/bin/sh

ROOTFS_DIR=$(pwd)/ubuntu-rootfs

# 颜色函数
print_green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
print_blue() { printf "\033[0;34m%s\033[0m\n" "$1"; }
print_red() { printf "\033[0;31m%s\033[0m\n" "$1"; }

# 检查安装
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/.installed" ]; then
    print_red "Ubuntu环境未正确安装"
    exit 1
fi

# 查找proot
PROOT_PATH=""
if [ -x "$ROOTFS_DIR/usr/local/bin/proot" ]; then
    PROOT_PATH="$ROOTFS_DIR/usr/local/bin/proot"
elif [ -x "$HOME/.local/bin/proot" ]; then
    PROOT_PATH="$HOME/.local/bin/proot"
else
    print_red "找不到proot工具"
    exit 1
fi

print_blue "启动Ubuntu环境..."
print_green "proot路径: $PROOT_PATH"

# 设置环境变量
export TERM=xterm-256color
export LANG=C.UTF-8

# 启动proot环境
"$PROOT_PATH" \
  --rootfs="$ROOTFS_DIR" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc \
  -b /etc/resolv.conf \
  --kill-on-exit \
  /bin/bash --login
EOF

chmod +x "start-ubuntu.sh"

# 创建软件包安装脚本
print_blue "创建软件包安装脚本..."
cat > "setup-ubuntu.sh" << 'EOF'
#!/bin/sh

ROOTFS_DIR=$(pwd)/ubuntu-rootfs

# 颜色函数
print_green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
print_blue() { printf "\033[0;34m%s\033[0m\n" "$1"; }
print_red() { printf "\033[0;31m%s\033[0m\n" "$1"; }

# 检查安装
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/.installed" ]; then
    print_red "Ubuntu环境未正确安装"
    exit 1
fi

# 查找proot
PROOT_PATH=""
if [ -x "$ROOTFS_DIR/usr/local/bin/proot" ]; then
    PROOT_PATH="$ROOTFS_DIR/usr/local/bin/proot"
elif [ -x "$HOME/.local/bin/proot" ]; then
    PROOT_PATH="$HOME/.local/bin/proot"
else
    print_red "找不到proot工具"
    exit 1
fi

print_blue "配置Ubuntu环境和安装软件包..."

"$PROOT_PATH" \
  --rootfs="$ROOTFS_DIR" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc \
  -b /etc/resolv.conf \
  --kill-on-exit \
  /bin/bash -c '
# 更新软件源
echo "更新软件源..."
apt update

# 安装基础软件包
echo "安装基础软件包..."
DEBIAN_FRONTEND=noninteractive apt install -y \
  curl wget git vim nano htop tmux \
  python3 python3-pip nodejs npm \
  build-essential gcc g++ make \
  net-tools iputils-ping \
  zip unzip tar sudo locales \
  bash-completion neofetch tree

# 配置语言环境
echo "配置语言环境..."
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# 配置bash环境
echo "配置bash环境..."
cat >> /root/.bashrc << "BASHRC_EOF"

# 历史记录配置
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth
shopt -s histappend

# 命令提示符
PS1="\[\033[01;32m\]\u@ubuntu\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

# 别名
alias ll="ls -la --color=auto"
alias la="ls -a --color=auto"
alias l="ls -l --color=auto"
alias ls="ls --color=auto"
alias ..="cd .."
alias ...="cd ../.."

# 欢迎信息
show_welcome() {
    clear
    printf "\033[1;32m╔════════════════════════════════════════════════════════════╗\033[0m\n"
    printf "\033[1;32m║                    欢迎使用 Ubuntu 环境                     ║\033[0m\n"
    printf "\033[1;32m╚════════════════════════════════════════════════════════════╝\033[0m\n"
    printf "\n"
    printf "\033[1;34m系统信息:\033[0m\n"
    uname -a
    printf "\n"
    printf "\033[1;34m可用工具:\033[0m git, vim, htop, python3, node, npm, neofetch\n"
    printf "\033[1;34m常用命令:\033[0m ll, la, .., tree, htop\n"
    printf "\033[1;34m退出环境:\033[0m exit 或 Ctrl+D\n"
    printf "\n"
}

# 只在交互式shell中显示欢迎信息
if [ -t 0 ]; then
    show_welcome
fi
BASHRC_EOF

# 清理
apt clean
rm -rf /var/lib/apt/lists/*

echo "Ubuntu环境配置完成！"
'
EOF

chmod +x "setup-ubuntu.sh"

# 显示完成信息
print_white "═══════════════════════════════════════════════════════════════"
print_green "                        安装完成！"
print_white "═══════════════════════════════════════════════════════════════"
printf "\n"
print_cyan "📋 使用步骤:"
print_white "1. 首次配置环境（安装软件包）:"
print_green "   ./setup-ubuntu.sh"
printf "\n"
print_white "2. 启动Ubuntu环境:"
print_green "   ./start-ubuntu.sh"
printf "\n"
print_white "3. 退出Ubuntu环境:"
print_green "   exit 或按 Ctrl+D"
printf "\n"
print_cyan "💡 提示:"
print_white "• 首次使用前请先运行 ./setup-ubuntu.sh"
print_white "• 环境是持久化的，文件修改会保存"
print_white "• 支持完整的Ubuntu命令和工具"
printf "\n"

# 询问是否立即配置
printf "是否现在就配置Ubuntu环境？(y/n): "
read response
if [ "$response" = "y" ] || [ "$response" = "Y" ] || [ "$response" = "yes" ]; then
    printf "\n"
    print_blue "开始配置Ubuntu环境..."
    ./setup-ubuntu.sh
    printf "\n"
    print_green "✓ 配置完成！现在可以运行 ./start-ubuntu.sh 启动Ubuntu环境"
fi
