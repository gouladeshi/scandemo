#!/bin/bash

# Linux 5.15 系统快速部署脚本
echo "=== Linux 5.15 系统快速部署脚本 ==="

# 基础设置
set -euo pipefail

# 检测系统信息
echo "系统信息："
echo "内核版本: $(uname -r)"
echo "架构: $(uname -m)"
echo "发行版: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo ""

# 检查是否为 root 用户
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  检测到以 root 用户运行，建议使用普通用户 + sudo"
fi

# 检查系统资源
echo "系统资源："
echo "CPU 核心数: $(nproc)"
echo "内存: $(free -h | grep Mem | awk '{print $2}')"
echo "可用内存: $(free -h | grep Mem | awk '{print $7}')"
echo "磁盘空间: $(df -h . | tail -1 | awk '{print $4}')"
echo ""

# 快速安装依赖
echo "安装系统依赖..."
if command -v apt &> /dev/null; then
    echo "使用 apt 安装依赖..."
    sudo apt update
    sudo apt install -y curl build-essential libsqlite3-dev pkg-config libssl-dev cmake qtbase5-dev qt5-qmake qtbase5-dev-tools libqt5network5-dev
elif command -v dnf &> /dev/null; then
    echo "使用 dnf 安装依赖..."
    sudo dnf install -y curl gcc gcc-c++ make sqlite-devel openssl-devel cmake qt5-qtbase-devel qt5-qtnetwork-devel
elif command -v yum &> /dev/null; then
    echo "使用 yum 安装依赖..."
    sudo yum install -y curl gcc gcc-c++ make sqlite-devel openssl-devel cmake qt5-qtbase-devel qt5-qtnetwork-devel
elif command -v pacman &> /dev/null; then
    echo "使用 pacman 安装依赖..."
    sudo pacman -S --noconfirm curl base-devel sqlite openssl cmake qt5-base qt5-network
else
    echo "❌ 未识别的包管理器，请手动安装依赖"
    exit 1
fi

# 安装 Rust
if ! command -v cargo &> /dev/null; then
    echo "安装 Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    
    # 配置 Cargo 镜像源（可选）
    mkdir -p ~/.cargo
    cat > ~/.cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
EOF
    echo "✅ Rust 安装完成"
else
    echo "✅ Rust 已安装"
fi

# 编译 Rust 后端
echo "编译 Rust 后端..."
export PATH="$HOME/.cargo/bin:$PATH"
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
cat > start_backend.sh << 'EOF'
#!/bin/bash
echo "启动 Rust 后端..."
export PATH="$HOME/.cargo/bin:$PATH"
./target/release/scan_demo
EOF

cat > start_frontend.sh << 'EOF'
#!/bin/bash
echo "启动 QT5 前端..."
./qt_frontend/build/bin/ScanDemoFrontend
EOF

cat > start_all.sh << 'EOF'
#!/bin/bash
echo "启动完整应用..."

# 启动后端
echo "启动 Rust 后端..."
export PATH="$HOME/.cargo/bin:$PATH"
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

chmod +x start_backend.sh start_frontend.sh start_all.sh

# 获取服务器信息
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🎉 部署完成！"
echo ""
echo "系统信息："
echo "- 内核版本: $(uname -r)"
echo "- 架构: $(uname -m)"
echo "- 服务器IP: $SERVER_IP"
echo ""
echo "启动方式："
echo "1. 完整应用: ./start_all.sh"
echo "2. 仅后端: ./start_backend.sh"
echo "3. 仅前端: ./start_frontend.sh"
echo ""
echo "访问地址："
echo "- 本地: http://localhost:3000"
echo "- 网络: http://$SERVER_IP:3000"
echo ""
echo "日志查看："
echo "- 后端日志: tail -f scan_demo.log"
echo "- 系统日志: journalctl -f"
echo ""
echo "防火墙配置（如需要）："
echo "sudo ufw allow 3000"
echo ""
echo "✅ 部署完成，可以开始使用了！"
