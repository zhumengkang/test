#!/bin/bash

# 设置错误处理
set -e

# 作者信息
echo "\033[36m┌────────────────────────────────────────────────────────┐\033[0m"
echo "\033[36m│ \033[32m作者: 康康                                                  \033[36m│\033[0m"
echo "\033[36m│ \033[32mGithub: https://github.com/zhumengkang/                    \033[36m│\033[0m"
echo "\033[36m│ \033[32mYouTube: https://www.youtube.com/@康康的V2Ray与Clash         \033[36m│\033[0m"
echo "\033[36m│ \033[32mTelegram: https://t.me/+WibQp7Mww1k5MmZl                   \033[36m│\033[0m"
echo "\033[36m└────────────────────────────────────────────────────────┘\033[0m"

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 设置基本变量
INSTALL_DIR=$(pwd)
ROOTFS_DIR="$INSTALL_DIR/ubuntu-rootfs"
max_retries=3
timeout=30
ARCH=$(uname -m)

# 进度显示函数
show_progress() {
    local current=$1
    local total=$2
    local desc=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}[%s] %3d%% [" "$desc"
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $empty | tr ' ' '-'
    printf "] ${NC}"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# 检测系统架构
echo -e "${BLUE}检测系统架构...${NC}"
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
    PROOT_URL="https://raw.githubusercontent.com/zhumengkang/test/main/proot-x86_64"
    echo -e "${GREEN}✓ 检测到 x86_64 架构${NC}"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_ALT=arm64
    PROOT_URL="https://raw.githubusercontent.com/zhumengkang/test/main/proot-aarch64"
    echo -e "${GREEN}✓ 检测到 aarch64 架构${NC}"
else
    echo -e "${RED}✗ 不支持的CPU架构: ${ARCH}${NC}"
    exit 1
fi

# 下载函数
download_with_progress() {
    local url=$1
    local output=$2
    local desc=$3
    local retries=0
    
    echo -e "${BLUE}正在下载: $desc${NC}"
    
    while [ $retries -lt $max_retries ]; do
        show_progress 0 1 "$desc"
        
        # 尝试使用curl
        if command -v curl >/dev/null 2>&1; then
            if curl -L --progress-bar --retry 2 --retry-delay 1 --connect-timeout $timeout -o "$output" "$url" 2>/dev/null; then
                if [ -s "$output" ]; then
                    show_progress 1 1 "$desc"
                    echo -e "${GREEN}✓ 下载完成: $desc${NC}"
                    return 0
                fi
            fi
        fi
        
        # 尝试使用wget
        if command -v wget >/dev/null 2>&1; then
            if wget --progress=bar:force --tries=2 --timeout=$timeout --no-hsts -O "$output" "$url" 2>/dev/null; then
                if [ -s "$output" ]; then
                    show_progress 1 1 "$desc"
                    echo -e "${GREEN}✓ 下载完成: $desc${NC}"
                    return 0
                fi
            fi
        fi
        
        retries=$((retries + 1))
        echo -e "${YELLOW}⚠ 下载重试 ($retries/$max_retries): $desc${NC}"
        rm -f "$output" 2>/dev/null || true
        sleep 2
    done
    
    echo -e "${RED}✗ 下载失败: $desc${NC}"
    return 1
}

# 主安装函数
install_ubuntu() {
    echo -e "${WHITE}#####################################################################${NC}"
    echo -e "${WHITE}#                                                                   #${NC}"
    echo -e "${WHITE}#                    Ubuntu 环境一键安装器                           #${NC}"
    echo -e "${WHITE}#                                                                   #${NC}"
    echo -e "${WHITE}#####################################################################${NC}"
    echo ""

    # 检查是否已安装
    if [ -f "$ROOTFS_DIR/.installed" ]; then
        echo -e "${YELLOW}⚠ 检测到已有安装，跳过基础安装${NC}"
    else
        # 创建目录
        echo -e "${BLUE}创建安装目录...${NC}"
        mkdir -p "$ROOTFS_DIR"
        
        # 下载Ubuntu基础系统
        local ubuntu_url="http://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04-base-${ARCH_ALT}.tar.gz"
        if ! download_with_progress "$ubuntu_url" "/tmp/ubuntu-base.tar.gz" "Ubuntu基础系统"; then
            echo -e "${RED}✗ Ubuntu基础系统下载失败${NC}"
            exit 1
        fi
        
        # 解压Ubuntu基础系统
        echo -e "${BLUE}解压Ubuntu基础系统...${NC}"
        tar -xf /tmp/ubuntu-base.tar.gz -C "$ROOTFS_DIR" 2>/dev/null
        rm -f /tmp/ubuntu-base.tar.gz
        echo -e "${GREEN}✓ Ubuntu基础系统解压完成${NC}"
        
        # 下载proot
        mkdir -p "$ROOTFS_DIR/usr/local/bin"
        if ! download_with_progress "$PROOT_URL" "$ROOTFS_DIR/usr/local/bin/proot" "proot工具"; then
            echo -e "${RED}✗ proot下载失败${NC}"
            exit 1
        fi
        
        # 设置proot权限
        echo -e "${BLUE}设置权限...${NC}"
        chmod +x "$ROOTFS_DIR/usr/local/bin/proot" 2>/dev/null || {
            echo -e "${YELLOW}⚠ 无法在rootfs中设置权限，复制到本地...${NC}"
            mkdir -p "$HOME/.local/bin"
            cp "$ROOTFS_DIR/usr/local/bin/proot" "$HOME/.local/bin/proot"
            chmod +x "$HOME/.local/bin/proot" 2>/dev/null || {
                echo -e "${RED}✗ 无法设置proot执行权限${NC}"
                exit 1
            }
        }
        
        # 基础配置
        echo -e "${BLUE}配置基础环境...${NC}"
        mkdir -p "$ROOTFS_DIR/etc" "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/root" "$ROOTFS_DIR/home"
        echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
        
        # 创建安装标记
        touch "$ROOTFS_DIR/.installed"
        echo -e "${GREEN}✓ 基础安装完成${NC}"
    fi
}

# 创建启动脚本
create_start_script() {
    echo -e "${BLUE}创建启动脚本...${NC}"
    
    cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

ROOTFS_DIR="$(pwd)/ubuntu-rootfs"

# 检查安装
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/.installed" ]; then
    echo -e "${RED}Ubuntu环境未正确安装，请重新运行安装脚本${NC}"
    exit 1
fi

# 查找proot
if [ -x "$ROOTFS_DIR/usr/local/bin/proot" ]; then
    PROOT_PATH="$ROOTFS_DIR/usr/local/bin/proot"
elif [ -x "$HOME/.local/bin/proot" ]; then
    PROOT_PATH="$HOME/.local/bin/proot"
else
    echo -e "${RED}找不到proot工具${NC}"
    exit 1
fi

echo -e "${BLUE}启动Ubuntu环境...${NC}"
echo -e "${GREEN}proot路径: $PROOT_PATH${NC}"

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
    
    chmod +x "$INSTALL_DIR/start.sh"
    echo -e "${GREEN}✓ 启动脚本创建完成${NC}"
}

# 创建软件包安装脚本
create_setup_script() {
    echo -e "${BLUE}创建软件包安装脚本...${NC}"
    
    cat > "$INSTALL_DIR/setup.sh" << 'EOF'
#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROOTFS_DIR="$(pwd)/ubuntu-rootfs"

# 检查安装
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/.installed" ]; then
    echo -e "${RED}Ubuntu环境未正确安装${NC}"
    exit 1
fi

# 查找proot
if [ -x "$ROOTFS_DIR/usr/local/bin/proot" ]; then
    PROOT_PATH="$ROOTFS_DIR/usr/local/bin/proot"
elif [ -x "$HOME/.local/bin/proot" ]; then
    PROOT_PATH="$HOME/.local/bin/proot"
else
    echo -e "${RED}找不到proot工具${NC}"
    exit 1
fi

echo -e "${BLUE}安装软件包和配置环境...${NC}"

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
    echo -e "\033[1;32m╔════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;32m║                    欢迎使用 Ubuntu 环境                     ║\033[0m"
    echo -e "\033[1;32m╚════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[1;34m系统信息:\033[0m"
    uname -a
    echo ""
    echo -e "\033[1;34m可用工具:\033[0m git, vim, htop, python3, node, npm, neofetch"
    echo -e "\033[1;34m常用命令:\033[0m ll, la, .., tree, htop"
    echo -e "\033[1;34m退出环境:\033[0m exit 或 Ctrl+D"
    echo ""
}

# 只在交互式shell中显示欢迎信息
if [[ $- == *i* ]]; then
    show_welcome
fi
BASHRC_EOF

apt clean >/dev/null 2>&1
rm -rf /var/lib/apt/lists/* >/dev/null 2>&1

echo "环境配置完成！"
echo "现在可以运行 ./start.sh 启动Ubuntu环境"
'
EOF
    
    chmod +x "$INSTALL_DIR/setup.sh"
    echo -e "${GREEN}✓ 软件包安装脚本创建完成${NC}"
}

# 显示完成信息
show_completion() {
    clear
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                        安装完成！                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📁 安装位置: $INSTALL_DIR${NC}"
    echo -e "${YELLOW}🐧 Ubuntu目录: $ROOTFS_DIR${NC}"
    echo ""
    echo -e "${CYAN}📋 使用步骤:${NC}"
    echo -e "${WHITE}1. 安装软件包和配置环境:${NC}"
    echo -e "   ${GREEN}./setup.sh${NC}"
    echo ""
    echo -e "${WHITE}2. 启动Ubuntu环境:${NC}"
    echo -e "   ${GREEN}./start.sh${NC}"
    echo ""
    echo -e "${WHITE}3. 退出Ubuntu环境:${NC}"
    echo -e "   ${GREEN}exit${NC} 或按 ${GREEN}Ctrl+D${NC}"
    echo ""
    echo -e "${CYAN}💡 提示:${NC}"
    echo -e "${WHITE}• 首次使用前请先运行 ./setup.sh 安装软件包${NC}"
    echo -e "${WHITE}• 支持的命令: git, vim, python3, node, htop 等${NC}"
    echo -e "${WHITE}• 环境是持久化的，文件修改会保存${NC}"
    echo ""
    
    # 自动询问是否立即设置
    echo -e "${YELLOW}是否现在就安装软件包？(y/n): ${NC}"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ] || [ "$response" = "yes" ]; then
        echo ""
        echo -e "${BLUE}开始安装软件包...${NC}"
        ./setup.sh
        echo ""
        echo -e "${GREEN}✓ 软件包安装完成！现在可以运行 ./start.sh 启动Ubuntu环境${NC}"
    fi
}

# 主执行流程
main() {
    # 检查权限
    if [ "$(id -u)" = "0" ]; then
        echo -e "${RED}⚠ 请不要以root用户运行此脚本${NC}"
        exit 1
    fi
    
    # 检查必要工具
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo -e "${RED}✗ 需要curl或wget工具${NC}"
        exit 1
    fi
    
    # 执行安装
    install_ubuntu
    create_start_script
    create_setup_script
    show_completion
}

# 错误处理
trap 'echo -e "${RED}安装过程中发生错误，请检查网络连接和权限${NC}"; exit 1' ERR

# 运行主程序
main
