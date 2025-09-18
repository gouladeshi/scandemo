#!/bin/bash

# 离线安装脚本
echo "=== 离线安装脚本 ==="

# 检查依赖目录
if [ ! -d "deps" ]; then
    echo "❌ 未找到 deps/ 目录"
    echo "请先运行 download_deps.sh 下载依赖"
    exit 1
fi

echo "开始离线安装..."

# 1. 离线安装 Rust
echo "1. 安装 Rust..."
if [ -f "deps/rust/rustup-init.sh" ]; then
    echo "使用预下载的 Rust 安装脚本..."
    chmod +x deps/rust/rustup-init.sh
    
    # 设置环境变量
    export RUSTUP_HOME="$(pwd)/deps/rust/rustup"
    export CARGO_HOME="$(pwd)/deps/rust/cargo-deps"
    
    # 安装 Rust
    ./deps/rust/rustup-init.sh -y --no-modify-path
    
    # 添加到 PATH
    export PATH="$CARGO_HOME/bin:$PATH"
    
    echo "✅ Rust 安装完成"
else
    echo "❌ 未找到 Rust 安装脚本"
    exit 1
fi

# 2. 离线安装系统包
echo "2. 安装系统包..."

# Ubuntu/Debian
if [ -d "deps/system/apt" ] && command -v dpkg &> /dev/null; then
    echo "安装 Ubuntu/Debian 包..."
    sudo dpkg -i deps/system/apt/*.deb
    sudo apt-get install -f -y  # 修复依赖
    echo "✅ Ubuntu/Debian 包安装完成"
fi

# CentOS/RHEL/Fedora
if [ -d "deps/system/dnf" ] && command -v rpm &> /dev/null; then
    echo "安装 CentOS/RHEL/Fedora 包..."
    sudo rpm -ivh deps/system/dnf/*.rpm
    echo "✅ CentOS/RHEL/Fedora 包安装完成"
fi

# 3. 编译项目
echo "3. 编译项目..."

# 设置环境变量
export PATH="$CARGO_HOME/bin:$PATH"
export CARGO_HOME="$(pwd)/deps/rust/cargo-deps"

# 编译 Rust 后端
echo "编译 Rust 后端..."
if cargo build --release; then
    echo "✅ Rust 后端编译完成"
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
        echo "✅ QT5 前端编译完成"
    else
        echo "❌ QT5 前端编译失败"
        exit 1
    fi
    
    cd ../..
else
    echo "❌ 未找到 qt_frontend 目录"
    exit 1
fi

# 4. 创建配置文件
if [ ! -f .env ]; then
    echo "创建配置文件..."
    cat > .env << EOF
DATABASE_URL=sqlite:scan_demo.db
EXTERNAL_API_URL=https://httpbin.org/post
RUST_LOG=info,sqlx=warn
EOF
fi

# 5. 创建启动脚本
echo "创建启动脚本..."
cat > start_offline.sh << 'EOF'
#!/bin/bash
echo "启动离线安装的应用..."

# 设置环境变量
export PATH="$(pwd)/deps/rust/cargo-deps/bin:$PATH"
export CARGO_HOME="$(pwd)/deps/rust/cargo-deps"

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

chmod +x start_offline.sh

echo ""
echo "🎉 离线安装完成！"
echo ""
echo "启动方式："
echo "./start_offline.sh"
echo ""
echo "访问地址："
echo "- 本地: http://localhost:3000"
echo "- 网络: http://$(hostname -I | awk '{print $1}'):3000"
