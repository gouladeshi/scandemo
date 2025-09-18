#!/bin/bash

# 依赖预下载脚本 - 在项目中预下载所有安装包
echo "=== 依赖预下载脚本 - 预下载所有安装包 ==="

# 创建依赖目录
mkdir -p deps/{rust,qt5,system,packages}

echo "开始预下载依赖..."

# 1. 预下载 Rust 工具链
echo "1. 预下载 Rust 工具链..."
if [ ! -f "deps/rust/rustup-init.sh" ]; then
    echo "下载 rustup 安装脚本..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o deps/rust/rustup-init.sh
    chmod +x deps/rust/rustup-init.sh
else
    echo "✅ rustup 安装脚本已存在"
fi

# 2. 预下载 Cargo 依赖
echo "2. 预下载 Cargo 依赖..."
if [ ! -d "deps/rust/cargo-deps" ]; then
    echo "创建 Cargo 依赖缓存..."
    mkdir -p deps/rust/cargo-deps
    
    # 设置 Cargo 缓存目录
    export CARGO_HOME="$(pwd)/deps/rust/cargo-deps"
    export RUSTUP_HOME="$(pwd)/deps/rust/rustup"
    
    # 如果 Rust 已安装，下载依赖
    if command -v cargo &> /dev/null; then
        echo "使用现有 Rust 下载依赖..."
        cargo fetch
    else
        echo "⚠️  Rust 未安装，无法预下载 Cargo 依赖"
        echo "请先安装 Rust 或使用离线安装包"
    fi
else
    echo "✅ Cargo 依赖缓存已存在"
fi

# 3. 预下载系统包（Ubuntu/Debian）
echo "3. 预下载系统包..."
if command -v apt &> /dev/null; then
    echo "预下载 apt 包..."
    mkdir -p deps/system/apt
    
    # 更新包列表
    apt update
    
    # 下载包但不安装
    apt download -o Dir::Cache="$(pwd)/deps/system/apt" \
        build-essential \
        libsqlite3-dev \
        pkg-config \
        libssl-dev \
        cmake \
        qtbase5-dev \
        qt5-qmake \
        qtbase5-dev-tools \
        libqt5network5-dev \
        curl \
        musl-tools
    
    echo "✅ apt 包下载完成"
    
    # 创建 apt 安装脚本
    cat > deps/system/apt/install_packages.sh << 'EOF'
#!/bin/bash
echo "安装预下载的 apt 包..."
sudo dpkg -i *.deb
sudo apt-get install -f -y
echo "✅ apt 包安装完成"
EOF
    chmod +x deps/system/apt/install_packages.sh
fi

# 4. 预下载系统包（CentOS/RHEL/Fedora）
if command -v dnf &> /dev/null; then
    echo "预下载 dnf 包..."
    mkdir -p deps/system/dnf
    
    # 下载 RPM 包
    dnf download --downloaddir="$(pwd)/deps/system/dnf" \
        gcc \
        gcc-c++ \
        make \
        sqlite-devel \
        openssl-devel \
        cmake \
        qt5-qtbase-devel \
        qt5-qtnetwork-devel \
        curl \
        musl-gcc
    
    echo "✅ dnf 包下载完成"
    
    # 创建 dnf 安装脚本
    cat > deps/system/dnf/install_packages.sh << 'EOF'
#!/bin/bash
echo "安装预下载的 dnf 包..."
sudo rpm -ivh *.rpm
echo "✅ dnf 包安装完成"
EOF
    chmod +x deps/system/dnf/install_packages.sh
fi

# 5. 创建依赖清单
echo "4. 创建依赖清单..."
cat > deps/dependencies.txt << EOF
# 依赖清单
生成时间: $(date)

## Rust 依赖
- rustup-init.sh: Rust 安装脚本
- cargo-deps/: Cargo 依赖缓存

## 系统依赖
- apt/: Ubuntu/Debian 包
- dnf/: CentOS/RHEL/Fedora 包

## 使用说明
1. 将整个 deps/ 目录复制到目标机器
2. 运行 offline_install.sh 进行离线安装
EOF

echo ""
echo "✅ 依赖预下载完成！"
echo ""
echo "依赖目录结构："
tree deps/ 2>/dev/null || find deps/ -type f | head -20

echo ""
echo "下一步："
echo "1. 将 deps/ 目录复制到目标机器"
echo "2. 运行 offline_install.sh 进行离线安装"
