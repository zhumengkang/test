#!/bin/sh

# 检查并切换到bash（如果可用）
if [ -x /bin/bash ] && [ "$0" != "/bin/bash" ]; then
    exec /bin/bash "$0" "$@"
fi

# 作者信息
printf "\033[36m┌────────────────────────────────────────────────────────┐\033[0m\n"
printf "\033[36m│ \033[32m作者: 康康                                                  \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mGithub: https://github.com/zhumengkang/                    \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mYouTube: https://www.youtube.com/@康康的V2Ray与Clash         \033[36m│\033[0m\n"
printf "\033[36m│ \033[32mTelegram: https://t.me/+WibQp7Mww1k5MmZl                   \033[36m│\033[0m\n"
printf "\033[36m└────────────────────────────────────────────────────────┘\033[0m\n"

# 定义颜色（使用printf兼容性更好）
print_red() { printf "\033[0;31m%s\033[0m\n" "$1"; }
print_green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
print_yellow() { printf "\033[1;33m%s\033[0m\n" "$1"; }
print_blue() { printf "\033[0;34m%s\033[0m\n" "$1"; }
print_cyan() { printf "\033[0;36m%s\033[0m\n" "$1"; }
print_white() { printf "\033[1;37m%s\033[0m\n" "$1"; }

# 设置基本变量
INSTALL_DIR=$(pwd)
ROOTFS_DIR="$INSTALL_DIR/ubuntu-rootfs"
max_retries=3
timeout=30
ARCH=$(uname -m)

# 错误处理函数
handle_error() {
    print_red "安装过程中发生错误，请检查网络连接和权限"
    exit 1
}

# 进度显示函数
show_progress() {
    local current=$1
    local total=$2
    local desc=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r\033[0;36m[%s] %3d%% [" "$desc"
    i=0; while [ $i -lt $filled ]; do printf "="; i=$((i+1)); done
    i=0; while [ $i -lt $empty ]; do printf "-"; i=$((i+1)); done
    printf "] \033[0m"
    
    if [ $current -eq $total ]; then
        printf "\n"
    fi
}

# 检测系统架构
print_blue "检测系统架构..."
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
    PROOT_URL="https://raw.githubusercontent.com/zhumengkang/test/main/proot-x86_64"
    print_green "✓ 检测到 x86_64 架构"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_ALT=arm64
    PROOT_URL="https://raw.githubusercontent.com/zhumengkang/test/main/proot-aarch64"
    print_green "✓ 检测到 aarch64 架构"
else
    print_red "✗ 不支持的CPU架构: ${ARCH}"
    exit 1
fi

# 下载函数
download_with_progress() {
    local url=$1
    local output=$2
    local desc=$3
    local retries=0
    
    print_blue "正在下载: $desc"
    
    while [ $retries -lt $max_retries ]; do
        show_progress 0 1 "$desc"
        
        # 尝试使用curl
        if command -v curl >/dev/null 2>&1; then
            if curl -L --silent --show-error --retry 2 --retry-delay 1 --connect-timeout $timeout -o "$output" "$url"; then
                if [ -s "$output" ]; then
                    show_progress 1 1 "$desc"
                    print_green "✓ 下载完成: $desc"
                    return 0
                fi
            fi
        fi
        
        # 尝试使用wget
        if command -v wget >/dev/null 2>&1; then
            if wget --quiet --tries=2 --timeout=$timeout --no-hsts -O "$output" "$url"; then
                if [ -s "$output" ]; then
                    show_progress 1 1 "$desc"
                    print_green "✓ 下载完成: $desc"
                    return 0
                fi
            fi
        fi
        
        retries=$((retries + 1))
        print_yellow "⚠ 下载重试 ($retries/$max_retries): $desc"
        rm -f "$output" 2>/dev/null || true
        sleep 2
    done
    
    print_red "✗ 下载失败: $desc"
    return 1
}

# 主安装函数
install_ubuntu() {
    print_white "#####################################################################"
    print_white "#                                                                   #"
    print_white "#                    Ubuntu 环境一键安装器                           #"
    print_white "#                                                                   #"
    print_white "#####################################################################"
    printf "\n"

    # 检查是否已安装
    if [ -f "$ROOTFS_DIR/.installed" ]; then
        print_yellow "⚠ 检测到已有安装，跳过基础安装"
    else
        # 创建目录
        print_blue "创建安装目录..."
        mkdir -p "$ROOTFS_DIR" || handle_error
        
        # 下载Ubuntu基础系统
        ubuntu_url="http://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04-base-${ARCH_ALT}.tar.gz"
        if ! download_with_progress "$ubuntu_url" "/tmp/ubuntu-base.tar.gz" "Ubuntu基础系统"; then
            print_red "✗ Ubuntu基础系统下载失败"
            handle_error
        fi
        
        # 解压Ubuntu基础系统
        print_blue "解压Ubuntu基础系统..."
        if tar -xf /tmp/ubuntu-base.tar.gz -C "$ROOTFS_DIR" 2>/dev/null; then
            rm -f /tmp/ubuntu-base.tar.gz
            print_green "✓ Ubuntu基础系统解压完成"
        else
            print_red "✗ Ubuntu基础系统解压失败"
            handle_error
        fi
        
        # 下载proot
        mkdir -p "$ROOTFS_DIR/usr/local/bin" || handle_error
        if ! download_with_progress "$PROOT_URL" "$ROOTFS_DIR/usr/local/bin/proot" "proot工具"; then
            print_red "✗ proot下载失败"
            handle_error
        fi
        
        # 设置proot权限
        print_blue "设置权限..."
        if chmod +x "$ROOTFS_DIR/usr/local/bin/proot" 2>/dev/null; then
            print_green "✓ proot权限设置成功"
        else
            print_yellow "⚠ 无法在rootfs中设置权限，复制到本地..."
            mkdir -p "$HOME/.local/bin" || handle_error
            cp "$ROOTFS_DIR/usr/local/bin/proot" "$HOME/.local/bin/proot" || handle_error
            if chmod +x "$HOME/.local/bin/proot" 2>/dev/null; then
                print_green "✓ proot已复制到本地并设置权限"
            else
                print_red "✗ 无法设置proot执行权限"
                handle_error
            fi
        fi
        
        # 基础配置
        print_blue "配置基础环境..."
        mkdir -p "$ROOTFS_DIR/etc" "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/root" "$ROOTFS_DIR/home" || handle_error
        printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\n" > "$ROOTFS_DIR/etc/resolv.conf" || handle_error
        
        # 创建安装标记
        touch "$ROOTFS_DIR/.installed" || handle_error
        print_green "✓ 基础安装完成"
    fi
}

# 创建启动脚本
create_start_script() {
    print_blue "创建启动脚本..."
    
    cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/sh

# 颜色定义函数
print_green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
print_blue() { printf "\033[0;34m%s\033[0m\n" "$1"; }
print_red() { printf "\033[0;31m%s\033[0m\n" "$1"; }

ROOTFS_DIR="$(pwd)/ubuntu-rootfs"

# 检查安装
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/.installed" ]; then
    print_red "Ubuntu环境未正确安装，请重新运行安装脚本"
    exit 1
fi

# 查找proot
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

export TERM=xterm-256color
export LANG=C.UTF-8

"$PROOT_PATH" \
  --rootfs="$ROOTFS_DIR" \
  --bind=/dev \
  --bind=/sys \
  --bind=/proc \
  --bind=/tmp \
  --working-directory="/root" \
  --change-id=0:0 \
  /bin/bash --login
EOF
    
    chmod +x "$INSTALL_DIR/start.sh" || handle_error
    print_green "✓ 启动脚本创建完成"
}

# 创建软件包安装脚本
create_setup_script() {
    print_blue "创建软件包安装脚本..."
    
    cat > "$INSTALL_DIR/setup.sh" << 'EOF'
#!/bin/sh

# 颜色定义函数
print_green() { printf "\033[0;32m%s\033[0m\n" "$1"; }
print_blue() { printf "\033[0;34m%s\033[0m\n" "$1"; }
print_red() { printf "\033[0;31m%s\033[0m\n" "$1"; }

ROOTFS_DIR="$(pwd)/ubuntu-rootfs"

# 检查安装
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/.installed" ]; then
    print_red "Ubuntu环境未正确安装"
    exit 1
fi

# 查找proot
if [ -x "$ROOTFS_DIR/usr/local/bin/proot" ]; then
    PROOT_PATH="$ROOTFS_DIR/usr/local/bin/proot"
elif [ -x "$HOME/.local/bin/proot" ]; then
    PROOT_PATH="$HOME/.local/bin/proot"
else
    print_red "找不到proot工具"
    exit 1
fi

print_blue "安装软件包和配置环境..."

export TERM=xterm-256color
export LANG=C.UTF-8

"$PROOT_PATH" \
  --rootfs="$ROOTFS_DIR" \
  --bind=/dev \
  --bind=/sys \
  --bind=/proc \
  --bind=/tmp \
  --working-directory="/root" \
  --change-id=0:0 \
  /bin/bash -c '
echo "更新软件源..."
apt update -qq

echo "安装基础软件包..."
DEBIAN_FRONTEND=noninteractive apt install -y -qq \
  curl wget git vim nano htop tmux screen \
  python3 python3-pip nodejs npm \
  build-essential cmake gcc g++ make \
  net-tools iputils-ping dnsutils \
  zip unzip tar gzip bzip2 xz-utils \
  openssh-client sudo locales \
  bash-completion neofetch tree \
  less man-db ca-certificates \
  >/dev/null 2>&1

echo "配置语言环境..."
locale-gen en_US.UTF-8 zh_CN.UTF-8 >/dev/null 2>&1
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1

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
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# 自动补全
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

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

apt clean >/dev/null 2>&1
rm -rf /var/lib/apt/lists/* >/dev/null 2>&1

echo "环境配置完成！"
echo "现在可以运行 ./start.sh 启动Ubuntu环境"
'
EOF
    
    chmod +x "$INSTALL_DIR/setup.sh" || handle_error
    print_green "✓ 软件包安装脚本创建完成"
}

# 显示完成信息
show_completion() {
    clear
    print_green "╔══════════════════════════════════════════════════════════════╗"
    print_green "║                        安装完成！                            ║"
    print_green "╚══════════════════════════════════════════════════════════════╝"
    printf "\n"
    print_yellow "📁 安装位置: $INSTALL_DIR"
    print_yellow "🐧 Ubuntu目录: $ROOTFS_DIR"
    printf "\n"
    print_cyan "📋 使用步骤:"
    print_white "1. 安装软件包和配置环境:"
    print_green "   ./setup.sh"
    printf "\n"
    print_white "2. 启动Ubuntu环境:"
    print_green "   ./start.sh"
    printf "\n"
    print_white "3. 退出Ubuntu环境:"
    print_green "   exit 或按 Ctrl+D"
    printf "\n"
    print_cyan "💡 提示:"
    print_white "• 首次使用前请先运行 ./setup.sh 安装软件包"
    print_white "• 支持的命令: git, vim, python3, node, htop 等"
    print_white "• 环境是持久化的，文件修改会保存"
    printf "\n"
    
    # 自动询问是否立即设置
    print_yellow "是否现在就安装软件包？(y/n): "
    read response
    if [ "$response" = "y" ] || [ "$response" = "Y" ] || [ "$response" = "yes" ]; then
        printf "\n"
        print_blue "开始安装软件包..."
        ./setup.sh
        printf "\n"
        print_green "✓ 软件包安装完成！现在可以运行 ./start.sh 启动Ubuntu环境"
    fi
}

# 主执行流程
main() {
    # 检查权限
    if [ "$(id -u)" = "0" ]; then
        print_red "⚠ 请不要以root用户运行此脚本"
        exit 1
    fi
    
    # 检查必要工具
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        print_red "✗ 需要curl或wget工具"
        exit 1
    fi
    
    # 执行安装
    install_ubuntu || handle_error
    create_start_script || handle_error
    create_setup_script || handle_error
    show_completion
}

# 运行主程序
main
