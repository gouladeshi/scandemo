#!/bin/bash

# 使用Docker编译Linux可执行文件
echo "=== 使用Docker编译Linux可执行文件 ==="

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

echo "✅ Docker环境检查通过"

# 创建临时Dockerfile用于编译
cat > Dockerfile.build << 'EOF'
FROM rust:1.89

# 设置工作目录
WORKDIR /app

# 安装必要的系统依赖
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY Cargo.toml Cargo.lock ./
COPY src ./src

# 编译Release版本
RUN cargo build --release

# 复制编译好的可执行文件到输出目录
RUN mkdir -p /output
RUN cp target/release/scan_demo /output/
EOF

echo "构建Docker镜像..."
docker build -f Dockerfile.build -t scan-demo-builder .

if [ $? -eq 0 ]; then
    echo "✅ Docker镜像构建成功"
    
    # 从容器中复制可执行文件
    echo "提取Linux可执行文件..."
    docker create --name temp-container scan-demo-builder
    docker cp temp-container:/output/scan_demo ./scan_demo_linux
    docker rm temp-container
    
    # 设置执行权限
    chmod +x ./scan_demo_linux
    
    # 显示文件信息
    echo "✅ Linux可执行文件编译成功！"
    echo "文件位置: ./scan_demo_linux"
    echo "文件大小: $(ls -lh ./scan_demo_linux | awk '{print $5}')"
    echo "文件类型: $(file ./scan_demo_linux)"
    
    # 清理临时文件
    rm -f Dockerfile.build
    
    echo ""
    echo "使用方法："
    echo "1. 将 scan_demo_linux 传输到Linux服务器"
    echo "2. 在Linux服务器上设置执行权限: chmod +x scan_demo_linux"
    echo "3. 运行: ./scan_demo_linux"
    echo "4. 或者CLI模式: ./scan_demo_linux --cli"
    
else
    echo "❌ Docker镜像构建失败"
    rm -f Dockerfile.build
    exit 1
fi
