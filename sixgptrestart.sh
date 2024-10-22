#!/bin/bash
cd ~/sixgpt

# 提示用户输入私钥和选择网络
#read -p "请输入您的私钥 (your_private_key): " PRIVATE_KEY
export VANA_PRIVATE_KEY=$PRIVATE_KEY
export VANA_NETWORK=$VANA_NETWORK

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

cd ~
rm -f sixgptrestart.sh
