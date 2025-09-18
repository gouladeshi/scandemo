#!/bin/bash

# QT5 + Rust 完整部署脚本 - Linux 5.15 优化版
echo "=== QT5 + Rust 完整部署脚本 - Linux 5.15 优化版 ==="

# 基础安全与稳健设置
set -euo pipefail

# 简单重试工具函数
retry_times=3
try_run() {
    local cmd="$1"
    local i=0
    until [ $i -ge $retry_times ]; do
        bash -lc "$cmd" && return 0
        i=$((i+1))
        sleep 2
    done
    return 1
}

# 检测 Linux 发行版并安装依赖
echo "检测 Linux 发行版..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "检测到系统: $NAME $VERSION"
    
    case $ID in
        ubuntu|debian)
            echo "使用 apt 包管理器..."
            sudo dpkg --configure -a || true
            sudo apt-get -f install -y || sudo apt --fix-broken install -y || true
            try_run "sudo apt-get update"
            try_run "sudo apt-get -y dist-upgrade" || true
            try_run "sudo apt-get install -y --no-install-recommends curl build-essential libsqlite3-dev pkg-config libssl-dev cmake qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5network5-dev"
            ;;
        centos|rhel|fedora)
            echo "使用 yum/dnf 包管理器..."
            if command -v dnf &> /dev/null; then
                try_run "sudo dnf update -y"
                try_run "sudo dnf install -y curl gcc gcc-c++ make sqlite-devel openssl-devel cmake qt5-qtbase-devel qt5-qtnetwork-devel"
            else
                try_run "sudo yum update -y"
                try_run "sudo yum install -y curl gcc gcc-c++ make sqlite-devel openssl-devel cmake qt5-qtbase-devel qt5-qtnetwork-devel"
            fi
            ;;
        arch|manjaro)
            echo "使用 pacman 包管理器..."
            try_run "sudo pacman -Syu --noconfirm"
            try_run "sudo pacman -S --noconfirm curl base-devel sqlite openssl cmake qt5-base qt5-network"
            ;;
        *)
            echo "未知发行版，尝试使用 apt..."
            sudo dpkg --configure -a || true
            sudo apt-get -f install -y || sudo apt --fix-broken install -y || true
            try_run "sudo apt-get update"
            try_run "sudo apt-get install -y --no-install-recommends curl build-essential libsqlite3-dev pkg-config libssl-dev cmake qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5network5-dev"
            ;;
    esac
else
    echo "无法检测发行版，使用默认 apt 安装..."
    sudo dpkg --configure -a || true
    sudo apt-get -f install -y || sudo apt --fix-broken install -y || true
    try_run "sudo apt-get update"
    try_run "sudo apt-get install -y --no-install-recommends curl build-essential libsqlite3-dev pkg-config libssl-dev cmake qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5network5-dev"
fi

# 检查是否安装了Rust
if ! command -v cargo &> /dev/null; then
    echo "正在安装 Rust..."
    echo "注意：Rust 下载可能需要几分钟，请耐心等待..."
    
    # 设置 Rust 镜像源（加速下载）
    export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
    export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
    
    # 尝试使用清华镜像源安装
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        echo "使用清华镜像源安装成功"
    else
        echo "镜像源安装失败，尝试官方源..."
        # 清除镜像源环境变量，使用官方源
        unset RUSTUP_DIST_SERVER
        unset RUSTUP_UPDATE_ROOT
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    
    # 加载 Rust 环境
    source ~/.cargo/env
    
    # 设置 Cargo 镜像源（加速后续包下载）
    mkdir -p ~/.cargo
    cat > ~/.cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
EOF
    
    echo "Rust 安装完成"
    echo "已配置国内镜像源以加速后续编译"
else
    echo "Rust 已安装"
fi

# 编译 Rust 后端
echo "正在编译 Rust 后端..."
# 确保 cargo 在 PATH 中（处理非交互 shell 的环境变量）
if ! command -v cargo &> /dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1090
        source "$HOME/.cargo/env" || true
    fi
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# 检查是否已有编译好的二进制文件
if [ -f "./target/release/scan_demo" ]; then
    echo "发现已编译的二进制文件，跳过编译"
else
    echo "开始编译，这可能需要几分钟..."
    echo ""
    echo "注意：当前项目中有 Windows 预编译版本 (scan_demo.exe)，但需要 Linux 版本"
    echo "如果编译太慢，建议："
    echo "1. 在 Windows 上交叉编译 Linux 版本"
    echo "2. 或者使用 GitHub Actions 等 CI/CD 服务编译"
    echo "3. 或者耐心等待当前编译完成"
    echo ""
    
    # 设置编译优化 - Linux 5.15 系统可以使用更多并行任务
    export CARGO_BUILD_JOBS=$(nproc)  # 使用所有可用CPU核心
    
    # 设置 OpenSSL 环境变量，使用系统 OpenSSL
    export OPENSSL_STATIC=0
    export OPENSSL_DIR=/usr
    export OPENSSL_INCLUDE_DIR=/usr/include/openssl
    
    # 根据架构设置正确的库路径 - Linux 5.15 系统优化
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            export OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu
            ;;
        aarch64)
            export OPENSSL_LIB_DIR=/usr/lib/aarch64-linux-gnu
            ;;
        armv7l)
            export OPENSSL_LIB_DIR=/usr/lib/arm-linux-gnueabihf
            ;;
        armv6l)
            export OPENSSL_LIB_DIR=/usr/lib/arm-linux-gnueabihf
            ;;
        *)
            export OPENSSL_LIB_DIR=/usr/lib
            ;;
    esac
    
    echo "检测到架构: $ARCH"
    echo "OpenSSL 库路径: $OPENSSL_LIB_DIR"
    
    if cargo build --release; then
        echo "编译成功"
    else
        echo "编译失败，可能的原因："
        echo "1. 内存不足（树莓派内存较小）"
        echo "2. 网络问题导致依赖下载失败"
        echo "3. 磁盘空间不足"
        echo "4. OpenSSL 构建错误"
        echo ""
        echo "诊断信息："
        echo "OpenSSL 版本: $(openssl version 2>/dev/null || echo '未安装')"
        echo "可用内存: $(free -h | grep Mem | awk '{print $7}' || echo '未知')"
        echo "磁盘空间: $(df -h . | tail -1 | awk '{print $4}' || echo '未知')"
        echo ""
        echo "建议："
        echo "1. 增加 swap 空间：sudo dphys-swapfile swapoff && sudo dphys-swapfile swapon"
        echo "2. 清理磁盘空间：sudo apt-get autoremove && sudo apt-get autoclean"
        echo "3. 检查网络连接"
        echo "4. 安装 OpenSSL 开发库：sudo apt-get install -y libssl-dev"
        echo "5. 考虑在 Windows 上交叉编译："
        echo "   rustup target add aarch64-unknown-linux-gnu  # 或 armv7-unknown-linux-gnueabihf"
        echo "   cargo build --release --target aarch64-unknown-linux-gnu"
        echo "6. 或者使用 rustls 替代 OpenSSL（推荐）"
        exit 1
    fi
fi

# 编译 QT5 前端
echo "正在编译 QT5 前端..."
if [ -d "qt_frontend" ]; then
    cd qt_frontend
    
    # 创建构建目录
    mkdir -p build
    cd build
    
    # 配置 CMake
    echo "配置 CMake..."
    cmake .. -DCMAKE_BUILD_TYPE=Release
    
    # 编译 - Linux 5.15 系统优化
    echo "开始编译 QT5 前端..."
    make -j$(nproc)
    
    # 检查编译结果
    if [ -f "bin/ScanDemoFrontend" ]; then
        echo "✅ QT5 前端编译成功！"
        chmod +x bin/ScanDemoFrontend
    else
        echo "❌ QT5 前端编译失败！"
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

echo "=== 部署完成 ==="
echo ""

# 获取服务器IP地址
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "服务器IP地址: $SERVER_IP"

echo ""
echo "运行方式："
echo "1. 启动 Rust 后端："
echo "   ./target/release/scan_demo"
echo ""
echo "2. 启动 QT5 前端："
echo "   ./qt_frontend/build/bin/ScanDemoFrontend"
echo ""
echo "3. 后台运行后端："
echo "   nohup ./target/release/scan_demo > scan_demo.log 2>&1 &"
echo ""
echo "4. 查看后端日志："
echo "   tail -f scan_demo.log"
echo ""
echo "=== 网络访问配置 ==="
echo "应用已配置为监听所有网络接口 (0.0.0.0:3000)"
echo "可以从以下地址访问："
echo "- 服务器本地: http://localhost:3000"
echo "- 局域网访问: http://$SERVER_IP:3000"
echo "- 其他设备访问: http://$SERVER_IP:3000"
echo ""
echo "如果无法从其他设备访问，请检查："
echo "1. 防火墙设置: sudo ufw allow 3000"
echo "2. 网络连接: ping $SERVER_IP"
echo "3. 端口监听: netstat -tlnp | grep 3000"
echo ""
echo "=== 网络配置检查 ==="
echo "检查防火墙状态..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | grep "Status:" | awk '{print $2}')
    echo "UFW 防火墙状态: $UFW_STATUS"
    if [ "$UFW_STATUS" = "active" ]; then
        if sudo ufw status | grep -q "3000"; then
            echo "✅ 端口 3000 已在防火墙中开放"
        else
            echo "⚠️  端口 3000 未在防火墙中开放，运行以下命令开放："
            echo "   sudo ufw allow 3000"
        fi
    else
        echo "✅ 防火墙未启用，无需配置"
    fi
else
    echo "UFW 防火墙未安装"
fi

echo ""
echo "=== 快速启动脚本 ==="
echo "创建快速启动脚本..."

# 创建启动脚本
cat > start_backend.sh << 'EOF'
#!/bin/bash
echo "启动 Rust 后端..."
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

echo "✅ 启动脚本已创建："
echo "   ./start_backend.sh  - 只启动后端"
echo "   ./start_frontend.sh - 只启动前端"
echo "   ./start_all.sh      - 启动完整应用"
