#!/bin/bash

if [[ $(docker ps -qf name=ocean-node) ]]; then
    echo "ocean正在运行"
else
    echo "停止"
fi
