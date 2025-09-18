#!/bin/bash

# 预下载所有安装包脚本
echo "=== 预下载所有安装包到项目中 ==="

# 创建包目录
mkdir -p packages/{ubuntu,centos,fedora,arch,rust,qt5}

echo "开始预下载安装包..."

# 检测当前系统并下载对应包
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "检测到系统: $NAME $VERSION"
    
    case $ID in
        ubuntu|debian)
            echo "预下载 Ubuntu/Debian 包..."
            mkdir -p packages/ubuntu
            
            # 更新包列表
            sudo apt update
            
            # 下载包到项目目录
            cd packages/ubuntu
            apt download \
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
                musl-tools \
                libc6-dev
            
            # 创建安装脚本
            cat > install.sh << 'EOF'
#!/bin/bash
echo "安装预下载的 Ubuntu/Debian 包..."
sudo dpkg -i *.deb
sudo apt-get install -f -y
echo "✅ 包安装完成"
EOF
            chmod +x install.sh
            cd ../..
            ;;
            
        centos|rhel)
            echo "预下载 CentOS/RHEL 包..."
            mkdir -p packages/centos
            
            cd packages/centos
            if command -v dnf &> /dev/null; then
                dnf download \
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
            else
                yumdownloader \
                    gcc \
                    gcc-c++ \
                    make \
                    sqlite-devel \
                    openssl-devel \
                    cmake \
                    qt5-qtbase-devel \
                    qt5-qtnetwork-devel \
                    curl
            fi
            
            # 创建安装脚本
            cat > install.sh << 'EOF'
#!/bin/bash
echo "安装预下载的 CentOS/RHEL 包..."
sudo rpm -ivh *.rpm
echo "✅ 包安装完成"
EOF
            chmod +x install.sh
            cd ../..
            ;;
            
        fedora)
            echo "预下载 Fedora 包..."
            mkdir -p packages/fedora
            
            cd packages/fedora
            dnf download \
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
            
            # 创建安装脚本
            cat > install.sh << 'EOF'
#!/bin/bash
echo "安装预下载的 Fedora 包..."
sudo rpm -ivh *.rpm
echo "✅ 包安装完成"
EOF
            chmod +x install.sh
            cd ../..
            ;;
            
        arch|manjaro)
            echo "预下载 Arch Linux 包..."
            mkdir -p packages/arch
            
            cd packages/arch
            # Arch Linux 使用 pacman，需要特殊处理
            echo "Arch Linux 包需要手动下载，请运行："
            echo "sudo pacman -Sw base-devel sqlite openssl cmake qt5-base qt5-network"
            echo "然后从 /var/cache/pacman/pkg/ 复制到 packages/arch/"
            
            # 创建安装脚本
            cat > install.sh << 'EOF'
#!/bin/bash
echo "安装预下载的 Arch Linux 包..."
sudo pacman -U *.pkg.tar.*
echo "✅ 包安装完成"
EOF
            chmod +x install.sh
            cd ../..
            ;;
    esac
fi

# 预下载 Rust 工具链
echo "预下载 Rust 工具链..."
mkdir -p packages/rust

# 下载 rustup 安装脚本
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o packages/rust/rustup-init.sh
chmod +x packages/rust/rustup-init.sh

# 创建 Rust 安装脚本
cat > packages/rust/install.sh << 'EOF'
#!/bin/bash
echo "安装 Rust..."
chmod +x rustup-init.sh
./rustup-init.sh -y --no-modify-path
echo "✅ Rust 安装完成"
EOF
chmod +x packages/rust/install.sh

# 预下载 Qt5 源码（可选）
echo "预下载 Qt5 源码（可选）..."
mkdir -p packages/qt5
echo "Qt5 源码下载需要 Qt 账户，请手动下载或使用系统包管理器"

# 创建通用安装脚本
cat > install_packages.sh << 'EOF'
#!/bin/bash
echo "=== 安装预下载的包 ==="

# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    
    case $ID in
        ubuntu|debian)
            if [ -d "packages/ubuntu" ]; then
                echo "安装 Ubuntu/Debian 包..."
                cd packages/ubuntu
                ./install.sh
                cd ../..
            fi
            ;;
        centos|rhel)
            if [ -d "packages/centos" ]; then
                echo "安装 CentOS/RHEL 包..."
                cd packages/centos
                ./install.sh
                cd ../..
            fi
            ;;
        fedora)
            if [ -d "packages/fedora" ]; then
                echo "安装 Fedora 包..."
                cd packages/fedora
                ./install.sh
                cd ../..
            fi
            ;;
        arch|manjaro)
            if [ -d "packages/arch" ]; then
                echo "安装 Arch Linux 包..."
                cd packages/arch
                ./install.sh
                cd ../..
            fi
            ;;
    esac
fi

# 安装 Rust
if [ -d "packages/rust" ]; then
    echo "安装 Rust..."
    cd packages/rust
    ./install.sh
    cd ../..
fi

echo "✅ 所有包安装完成"
EOF
chmod +x install_packages.sh

# 创建包清单
cat > packages/README.md << EOF
# 预下载的安装包

## 目录结构
- \`ubuntu/\` - Ubuntu/Debian 包 (.deb)
- \`centos/\` - CentOS/RHEL 包 (.rpm)
- \`fedora/\` - Fedora 包 (.rpm)
- \`arch/\` - Arch Linux 包 (.pkg.tar.*)
- \`rust/\` - Rust 工具链
- \`qt5/\` - Qt5 源码（可选）

## 使用方法

### 自动安装
\`\`\`bash
./install_packages.sh
\`\`\`

### 手动安装
\`\`\`bash
# 根据系统类型选择对应目录
cd packages/ubuntu  # 或 centos, fedora, arch
./install.sh
\`\`\`

## 包列表
EOF

# 添加包列表到 README
if [ -d "packages/ubuntu" ]; then
    echo "### Ubuntu/Debian 包" >> packages/README.md
    ls -la packages/ubuntu/*.deb >> packages/README.md 2>/dev/null || echo "无 .deb 文件" >> packages/README.md
fi

if [ -d "packages/centos" ]; then
    echo "### CentOS/RHEL 包" >> packages/README.md
    ls -la packages/centos/*.rpm >> packages/README.md 2>/dev/null || echo "无 .rpm 文件" >> packages/README.md
fi

if [ -d "packages/fedora" ]; then
    echo "### Fedora 包" >> packages/README.md
    ls -la packages/fedora/*.rpm >> packages/README.md 2>/dev/null || echo "无 .rpm 文件" >> packages/README.md
fi

echo ""
echo "✅ 安装包预下载完成！"
echo ""
echo "包目录结构："
tree packages/ 2>/dev/null || find packages/ -type f | head -20

echo ""
echo "使用方法："
echo "1. 将整个项目复制到目标机器"
echo "2. 运行: ./install_packages.sh"
echo "3. 或手动安装: cd packages/系统类型 && ./install.sh"
echo ""
echo "包大小统计："
du -sh packages/* 2>/dev/null || echo "无法统计包大小"
