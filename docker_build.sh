#!/bin/bash

# Docker 构建和部署脚本
echo "=== Docker 构建和部署脚本 ==="

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装"
    echo "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker 环境检查通过"

# 创建必要的目录
mkdir -p logs

# 构建 Docker 镜像
echo "构建 Docker 镜像..."
docker-compose build

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "✅ Docker 镜像构建成功"
else
    echo "❌ Docker 镜像构建失败"
    exit 1
fi

# 显示镜像信息
echo "Docker 镜像信息："
docker images | grep scan-demo

echo ""
echo "=== 部署选项 ==="
echo "1. 启动服务: docker-compose up -d"
echo "2. 查看日志: docker-compose logs -f"
echo "3. 停止服务: docker-compose down"
echo "4. 重启服务: docker-compose restart"
echo ""
echo "访问地址: http://localhost:3000"
echo ""

# 询问是否立即启动
read -p "是否立即启动服务？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "启动服务..."
    docker-compose up -d
    
    echo "等待服务启动..."
    sleep 5
    
    echo "检查服务状态..."
    docker-compose ps
    
    echo ""
    echo "✅ 服务已启动！"
    echo "访问地址: http://localhost:3000"
    echo "查看日志: docker-compose logs -f"
fi
