#!/bin/bash

# 使用预下载包进行部署
echo "=== 使用预下载包进行部署 ==="

# 检查是否有预下载的包
if [ ! -d "packages" ]; then
    echo "❌ 未找到预下载的包目录"
    echo "请先运行: ./prepare_packages.sh"
    exit 1
fi

echo "发现预下载的包，开始安装..."

# 安装系统包
echo "1. 安装系统包..."
if [ -f "install_packages.sh" ]; then
    chmod +x install_packages.sh
    ./install_packages.sh
else
    echo "❌ 未找到 install_packages.sh"
    exit 1
fi

# 设置 Rust 环境
echo "2. 设置 Rust 环境..."
if [ -d "$HOME/.cargo" ]; then
    echo "✅ Rust 已安装"
    export PATH="$HOME/.cargo/bin:$PATH"
else
    echo "❌ Rust 未安装，请检查安装过程"
    exit 1
fi

# 编译项目
echo "3. 编译项目..."

# 设置编译环境
export CARGO_BUILD_JOBS=$(nproc)

# 设置 OpenSSL 环境变量
export OPENSSL_STATIC=0
export OPENSSL_DIR=/usr
export OPENSSL_INCLUDE_DIR=/usr/include/openssl

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        export OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu
        ;;
    aarch64)
        export OPENSSL_LIB_DIR=/usr/lib/aarch64-linux-gnu
        ;;
    *)
        export OPENSSL_LIB_DIR=/usr/lib
        ;;
esac

echo "架构: $ARCH, OpenSSL 库路径: $OPENSSL_LIB_DIR"

# 编译 Rust 后端
echo "编译 Rust 后端..."
if cargo build --release; then
    echo "✅ Rust 后端编译成功"
else
    echo "❌ Rust 后端编译失败"
    exit 1
fi

# 编译 QT5 前端
echo "编译 QT5 前端..."
if [ -d "qt_frontend" ]; then
    cd qt_frontend
    mkdir -p build
    cd build
    
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    
    if [ -f "bin/ScanDemoFrontend" ]; then
        chmod +x bin/ScanDemoFrontend
        echo "✅ QT5 前端编译成功"
    else
        echo "❌ QT5 前端编译失败"
        exit 1
    fi
    
    cd ../..
else
    echo "❌ 未找到 qt_frontend 目录"
    exit 1
fi

# 创建配置文件
if [ ! -f .env ]; then
    echo "创建配置文件..."
    cat > .env << EOF
DATABASE_URL=sqlite:scan_demo.db
EXTERNAL_API_URL=https://httpbin.org/post
RUST_LOG=info,sqlx=warn
EOF
fi

# 创建启动脚本
echo "创建启动脚本..."
cat > start_with_packages.sh << 'EOF'
#!/bin/bash
echo "启动使用预下载包部署的应用..."

# 设置环境变量
export PATH="$HOME/.cargo/bin:$PATH"

# 启动后端
echo "启动 Rust 后端..."
nohup ./target/release/scan_demo > scan_demo.log 2>&1 &
BACKEND_PID=$!
echo "后端进程ID: $BACKEND_PID"

# 等待后端启动
sleep 3

# 启动前端
echo "启动 QT5 前端..."
./qt_frontend/build/bin/ScanDemoFrontend

# 前端退出时停止后端
echo "前端已退出，停止后端..."
kill $BACKEND_PID
EOF

chmod +x start_with_packages.sh

# 获取服务器信息
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🎉 使用预下载包部署完成！"
echo ""
echo "系统信息："
echo "- 内核版本: $(uname -r)"
echo "- 架构: $(uname -m)"
echo "- 服务器IP: $SERVER_IP"
echo ""
echo "启动方式："
echo "./start_with_packages.sh"
echo ""
echo "访问地址："
echo "- 本地: http://localhost:3000"
echo "- 网络: http://$SERVER_IP:3000"
echo ""
echo "日志查看："
echo "- 后端日志: tail -f scan_demo.log"
echo ""
echo "✅ 部署完成，可以开始使用了！"
