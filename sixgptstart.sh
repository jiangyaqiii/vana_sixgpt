#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
source ~/.bashrc

# 启动节点的函数
function start_node() {
    # 更新软件包列表并升级已安装的软件包
    echo "" | bash -c "sudo apt update -y && sudo apt upgrade -y"
    # 安装所需的依赖包
   
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev \
    build-essential pkg-config ncdu tar clang bsdmainutils lsb-release \
    libssl-dev libreadline-dev libffi-dev jq gcc screen unzip lz4

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装 Docker..."
        
        # 安装 Docker
        echo '1'
        echo "" | bash -c "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common"
        echo '2'
        echo "" | bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
        echo '3'
        echo "" | bash -c 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
        echo '4'
        echo "" | bash -c 'sudo apt update -y'
        echo '5'
        echo "" | bash -c 'sudo apt install -y docker-ce'
        echo '6'
        # 启动 Docker 服务
        sudo systemctl start docker
        echo '7'
        sudo systemctl enable docker

        echo "Docker 安装完成！"
    else
        echo "Docker 已安装，跳过安装。"
    fi

    # 检查 Docker Compose 是否已安装
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose 未安装，正在安装 Docker Compose..."
        
        # 获取最新版本号并安装 Docker Compose
        echo '8'
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        echo '9'
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
    #read -p "请输入您的私钥 (your_private_key): " PRIVATE_KEY
    export VANA_PRIVATE_KEY=$PRIVATE_KEY
    export VANA_NETWORK=$VANA_NETWORK
    # # 选择网络
    # echo "请选择网络-哪个都一样 (输入数字 1 或 2):"
    # echo "1) satori"
    # echo "2) moksha"
    # read -p "请输入选择的数字: " NETWORK_CHOICE

    # case $NETWORK_CHOICE in
    #     1)
    #         export VANA_NETWORK="satori"
    #         ;;
    #     2)
    #         export VANA_NETWORK="moksha"
    #         ;;
    #     *)
    #         echo "无效选择，默认选择 satori。"
    #         export VANA_NETWORK="satori"
    #         ;;
    # esac

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
 
  sixgpt3-satori:
    image: sixgpt/miner:latest
    ports:
      - "3015:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY}
      - VANA_NETWORK=satori
    restart: always

  sixgpt3-moksha:
    image: sixgpt/miner:latest
    ports:
      - "3016:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY}
      - VANA_NETWORK=moksha
    restart: always
    
volumes:
  ollama:
EOL

    # 启动 Docker Compose
    echo "正在启动 Docker Compose..."
    docker-compose up -d
    echo "Docker Compose 启动完成！"
}
start_node

cd ~
rm -f start.sh
