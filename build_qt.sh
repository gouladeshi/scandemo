#!/bin/bash

# QT5 前端构建脚本
echo "=== QT5 前端构建脚本 ==="

# 检查是否安装了必要的依赖
echo "检查构建依赖..."

# 检查 cmake
if ! command -v cmake &> /dev/null; then
    echo "❌ cmake 未安装，正在安装..."
    sudo apt-get update
    sudo apt-get install -y cmake
fi

# 检查 Qt5 开发包
if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
    echo "❌ Qt5 开发包未安装，正在安装..."
    sudo apt-get update
    sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
fi

# 检查构建工具
if ! command -v make &> /dev/null; then
    echo "❌ make 未安装，正在安装..."
    sudo apt-get install -y build-essential
fi

echo "✅ 构建依赖检查完成"

# 进入前端目录
cd qt_frontend

# 创建构建目录
echo "创建构建目录..."
mkdir -p build
cd build

# 配置 CMake
echo "配置 CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# 编译
echo "开始编译..."
make -j$(nproc)

# 检查编译结果
if [ -f "bin/ScanDemoFrontend" ]; then
    echo "✅ 编译成功！"
    echo "可执行文件位置: $(pwd)/bin/ScanDemoFrontend"
    
    # 设置执行权限
    chmod +x bin/ScanDemoFrontend
    
    # 显示文件信息
    ls -la bin/ScanDemoFrontend
    
    echo ""
    echo "=== 运行说明 ==="
    echo "1. 确保 Rust 后端已启动："
    echo "   ./target/release/scan_demo"
    echo ""
    echo "2. 运行 QT5 前端："
    echo "   ./bin/ScanDemoFrontend"
    echo ""
    echo "3. 如果后端运行在不同地址，可以设置环境变量："
    echo "   export API_BASE_URL=http://your-server:3000"
    echo "   ./bin/ScanDemoFrontend"
    
else
    echo "❌ 编译失败！"
    echo "请检查错误信息并修复问题"
    exit 1
fi
