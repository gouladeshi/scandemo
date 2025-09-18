#!/bin/bash

# ============================================
# 使用 Docker 编译 Linux 版本的脚本
# ============================================

set -e

echo "============================================"
echo "🐳 使用 Docker 编译 Linux 版本"
echo "============================================"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

echo "✅ Docker 已安装: $(docker --version)"

# 检查是否在项目根目录
if [ ! -f "Cargo.toml" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 构建 Docker 镜像
echo "🔨 构建 Docker 镜像..."
docker build -f Dockerfile.linux -t scan-demo-linux .

if [ $? -ne 0 ]; then
    echo "❌ Docker 镜像构建失败"
    exit 1
fi

echo "✅ Docker 镜像构建成功"

# 创建输出目录
OUTPUT_DIR="linux-build-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# 运行容器并复制编译结果
echo "📦 提取编译结果..."
docker run --rm -v "$(pwd)/$OUTPUT_DIR":/output scan-demo-linux /bin/bash -c "
    cp target/release/scan_demo /output/
    cp qt_frontend/build/bin/ScanDemoFrontend /output/
    cp start_*.sh /output/
    chmod +x /output/*
    echo '编译结果已复制到输出目录'
"

# 复制其他必要文件
if [ -f "scan_demo.db" ]; then
    cp scan_demo.db "$OUTPUT_DIR/"
fi

if [ -d "static" ]; then
    cp -r static "$OUTPUT_DIR/"
fi

if [ -d "templates" ]; then
    cp -r templates "$OUTPUT_DIR/"
fi

# 创建 README
cat > "$OUTPUT_DIR/README.md" << 'EOF'
# 扫码生产看板 Linux 版本

## 文件说明
- `scan_demo`: Rust 后端服务
- `ScanDemoFrontend`: Qt 前端应用
- `start_backend.sh`: 启动后端服务
- `start_frontend.sh`: 启动前端应用
- `start_complete.sh`: 启动完整应用（推荐）

## 使用方法

### 方法一：使用完整启动脚本（推荐）
```bash
./start_complete.sh
```

### 方法二：分别启动
```bash
# 启动后端服务
./start_backend.sh

# 在另一个终端启动前端
./start_frontend.sh
```

### 方法三：直接运行
```bash
# 启动后端
./scan_demo

# 启动前端
./ScanDemoFrontend
```

## 配置说明
- 后端默认监听端口：3000
- 可通过环境变量 API_BASE_URL 修改前端连接的后端地址
- 数据库文件：scan_demo.db

## 系统要求
- Linux 系统
- Qt5 运行时库
- 网络连接（用于外部API调用）

## 安装 Qt5 运行时库
### Ubuntu/Debian:
```bash
sudo apt-get install qt5-default qtbase5-dev
```

### CentOS/RHEL:
```bash
sudo yum install qt5-qtbase
```

### Fedora:
```bash
sudo dnf install qt5-qtbase
```
EOF

# 创建压缩包
echo "📦 创建压缩包..."
tar -czf "${OUTPUT_DIR}.tar.gz" "$OUTPUT_DIR"

echo ""
echo "============================================"
echo "🎉 编译完成！"
echo "============================================"
echo ""
echo "📁 输出目录: $OUTPUT_DIR"
echo "📦 压缩包: ${OUTPUT_DIR}.tar.gz"
echo ""
echo "🚀 使用方法:"
echo "1. 解压: tar -xzf ${OUTPUT_DIR}.tar.gz"
echo "2. 进入目录: cd $OUTPUT_DIR"
echo "3. 运行: ./start_complete.sh"
echo ""
echo "📖 详细说明请查看 README.md"
echo "============================================"
