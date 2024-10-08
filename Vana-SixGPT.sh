#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Vana-SixGPT.sh"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 启动节点"
        echo "2) 查看日志"
        echo "3) 删除节点"
        echo "4) 退出"
        
        read -p "请输入选择的数字: " choice
        
        case $choice in
            1)
                start_node
                ;;
            2)
                view_logs
                ;;
            3)
                delete_node
                ;;
            3)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选择，请重试。"
                read -p "按任意键继续..."
                ;;
        esac
    done
}

# 启动节点的函数
function start_node() {
    # 更新软件包列表并升级已安装的软件包
    sudo apt update -y && sudo apt upgrade -y

    # 安装所需的依赖包
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev \
    build-essential pkg-config ncdu tar clang bsdmainutils lsb-release \
    libssl-dev libreadline-dev libffi-dev jq gcc screen unzip lz4

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装 Docker..."
        
        # 安装 Docker
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update -y
        sudo apt install -y docker-ce

        # 启动 Docker 服务
        sudo systemctl start docker
        sudo systemctl enable docker

        echo "Docker 安装完成！"
    else
        echo "Docker 已安装，跳过安装。"
    fi

    # 检查 Docker Compose 是否已安装
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose 未安装，正在安装 Docker Compose..."
        
        # 获取最新版本号并安装 Docker Compose
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo "Docker Compose 安装完成！"
    else
        echo "Docker Compose 已安装，跳过安装。"
    fi

    # 显示 Docker Compose 版本
    docker-compose --version

    # 添加当前用户到 Docker 组
    if ! getent group docker > /dev/null; then
        echo "正在创建 Docker 组..."
        sudo groupadd docker
    fi

    echo "正在将用户 $USER 添加到 Docker 组..."
    sudo usermod -aG docker $USER

    # 创建目录并设置环境变量
    mkdir -p ~/sixgpt
    cd ~/sixgpt

    # 提示用户输入私钥和选择网络
    read -p "请输入您的私钥 (your_private_key): " PRIVATE_KEY
    export VANA_PRIVATE_KEY=$PRIVATE_KEY

    # 选择网络
    echo "请选择网络 (输入数字 1 或 2):"
    echo "1) satori"
    echo "2) moksha"
    read -p "请输入选择的数字: " NETWORK_CHOICE

    case $NETWORK_CHOICE in
        1)
            export VANA_NETWORK="satori"
            ;;
        2)
            export VANA_NETWORK="moksha"
            ;;
        *)
            echo "无效选择，默认选择 satori。"
            export VANA_NETWORK="satori"
            ;;
    esac

    echo "已选择网络: $VANA_NETWORK"

    # 创建 docker-compose.yml 文件
    cat <<EOL > docker-compose.yml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11435:11434"
    volumes:
      - ollama:/root/.ollama
    restart: unless-stopped
 
  sixgpt3:
    image: sixgpt/miner:latest
    ports:
      - "3015:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=\${VANA_PRIVATE_KEY}
      - VANA_NETWORK=\${VANA_NETWORK}
    restart: always

volumes:
  ollama:
EOL

    # 启动 Docker Compose
    echo "正在启动 Docker Compose..."
    docker-compose up -d
    echo "Docker Compose 启动完成！"
    echo "所有操作完成！请重新登录以应用组更改。"

    read -p "按任意键返回主菜单..."
}

# 查看日志的函数
function view_logs() {
    echo "正在查看 Docker Compose 日志..."
    docker-compose logs -fn 100
    read -p "按任意键返回主菜单..."
}

# 删除节点的函数
function delete_node() {
    echo "正在进入 /root/sixgpt 目录..."
    cd /root/sixgpt || { echo "目录不存在！"; return; }

    echo "正在停止所有 Docker Compose 服务..."
    docker-compose down
    echo "所有 Docker Compose 服务已停止！"
    
    read -p "按任意键返回主菜单..."
}

# 调用主菜单函数
main_menu
