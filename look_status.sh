#!/bin/bash

if [[ $(docker ps -qf name=sixgpt-ollama-1) ]]; then
    echo "vana-sixgpt正在运行"
else
    echo "停止"
fi
