#!/bin/bash

# ============================================
# Rust + Qt 扫码生产看板 Linux 简化编译脚本
# ============================================

set -e  # 遇到错误立即退出

echo "============================================"
echo "🚀 开始编译 Rust + Qt 扫码生产看板"
echo "============================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在项目根目录
if [ ! -f "Cargo.toml" ]; then
    log_error "请在项目根目录运行此脚本"
    exit 1
fi

# 检查并安装系统依赖
log_info "检查系统依赖..."

# 检测系统类型并尝试安装包管理器
detect_and_install_package_manager() {
    log_info "检测系统类型和包管理器..."
    
    # 检测系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS="unknown"
    fi
    
    log_info "检测到系统: $OS"
    
    # 检查是否有任何包管理器可用
    if command -v apt-get &> /dev/null || command -v yum &> /dev/null || command -v dnf &> /dev/null || command -v pacman &> /dev/null || command -v zypper &> /dev/null; then
        log_success "找到可用的包管理器"
        return 0
    fi
    
    log_warning "未找到包管理器，尝试安装..."
    
    # 根据系统类型尝试安装包管理器
    case $OS in
        "ubuntu"|"debian")
            log_info "尝试安装 apt-get..."
            # 对于最小化安装的Ubuntu/Debian系统
            if command -v wget &> /dev/null; then
                log_info "使用 wget 下载 apt 包..."
                wget -qO- http://archive.ubuntu.com/ubuntu/pool/main/a/apt/apt_2.0.9_amd64.deb -o /tmp/apt.deb
                sudo dpkg -i /tmp/apt.deb || sudo apt-get install -f
            elif command -v curl &> /dev/null; then
                log_info "使用 curl 下载 apt 包..."
                curl -L http://archive.ubuntu.com/ubuntu/pool/main/a/apt/apt_2.0.9_amd64.deb -o /tmp/apt.deb
                sudo dpkg -i /tmp/apt.deb || sudo apt-get install -f
            else
                log_error "需要 wget 或 curl 来安装 apt-get"
                return 1
            fi
            ;;
        "centos"|"rhel"|"fedora")
            log_info "尝试安装 yum/dnf..."
            # 对于最小化安装的CentOS/RHEL系统
            if command -v curl &> /dev/null; then
                log_info "下载 yum 安装包..."
                curl -L http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/yum-4.7.0-4.el8.noarch.rpm -o /tmp/yum.rpm
                sudo rpm -ivh /tmp/yum.rpm
            elif command -v wget &> /dev/null; then
                log_info "下载 yum 安装包..."
                wget http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/yum-4.7.0-4.el8.noarch.rpm -O /tmp/yum.rpm
                sudo rpm -ivh /tmp/yum.rpm
            else
                log_error "需要 curl 或 wget 来安装 yum"
                return 1
            fi
            ;;
        "arch"|"manjaro")
            log_error "Arch Linux 需要完整的 pacman 包管理器"
            log_info "请确保系统完整安装或使用其他Linux发行版"
            return 1
            ;;
        *)
            log_warning "未知系统类型: $OS"
            log_info "尝试从源码编译安装基础工具..."
            install_from_source
            ;;
    esac
}

# 从源码编译安装基础工具（备用方案）
install_from_source() {
    log_info "尝试从源码编译安装基础工具..."
    
    # 检查是否有基础编译工具
    if ! command -v gcc &> /dev/null; then
        log_info "下载并编译 gcc..."
        # 这里可以添加从源码编译gcc的逻辑
        log_warning "从源码编译 gcc 需要很长时间，建议使用包管理器"
    fi
    
    if ! command -v make &> /dev/null; then
        log_info "下载并编译 make..."
        # 这里可以添加从源码编译make的逻辑
    fi
    
    log_warning "从源码编译安装可能需要很长时间"
    log_info "建议使用完整的Linux发行版或确保包管理器可用"
}

# 安装依赖包
install_dependencies() {
    log_info "安装系统依赖..."
    
    if command -v apt-get &> /dev/null; then
        log_info "使用 apt-get 安装依赖..."
        sudo apt-get update
        sudo apt-get install -y build-essential cmake pkg-config curl wget
        
        # 安装 Qt5 开发包
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "安装 Qt5 开发包..."
            sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
        fi
        
    elif command -v yum &> /dev/null; then
        log_info "使用 yum 安装依赖..."
        sudo yum update -y
        sudo yum install -y gcc gcc-c++ make cmake pkgconfig curl wget
        
        # 安装 Qt5 开发包
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "安装 Qt5 开发包..."
            sudo yum install -y qt5-qtbase-devel qt5-qtbase-gui
        fi
        
    elif command -v dnf &> /dev/null; then
        log_info "使用 dnf 安装依赖..."
        sudo dnf update -y
        sudo dnf install -y gcc gcc-c++ make cmake pkgconfig curl wget
        
        # 安装 Qt5 开发包
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "安装 Qt5 开发包..."
            sudo dnf install -y qt5-qtbase-devel qt5-qtbase-gui
        fi
        
    elif command -v pacman &> /dev/null; then
        log_info "使用 pacman 安装依赖..."
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm base-devel cmake pkg-config curl wget
        
        # 安装 Qt5 开发包
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "安装 Qt5 开发包..."
            sudo pacman -S --noconfirm qt5-base qt5-tools
        fi
        
    elif command -v zypper &> /dev/null; then
        log_info "使用 zypper 安装依赖..."
        sudo zypper refresh
        sudo zypper install -y gcc gcc-c++ make cmake pkg-config curl wget
        
        # 安装 Qt5 开发包
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "安装 Qt5 开发包..."
            sudo zypper install -y libQt5Core-devel libQt5Widgets-devel libQt5Network-devel
        fi
        
    else
        log_error "未找到支持的包管理器"
        show_manual_install_guide
        exit 1
    fi
}

# 显示手动安装指导
show_manual_install_guide() {
    log_info "支持的包管理器: apt-get, yum, dnf, pacman, zypper"
    echo ""
    echo "============================================"
    echo "📋 手动安装指导"
    echo "============================================"
    echo ""
    echo "🔧 基础编译工具:"
    echo "  Ubuntu/Debian: sudo apt-get install build-essential"
    echo "  CentOS/RHEL:   sudo yum groupinstall 'Development Tools'"
    echo "  Fedora:        sudo dnf groupinstall 'Development Tools'"
    echo "  Arch:          sudo pacman -S base-devel"
    echo "  openSUSE:      sudo zypper install -t pattern devel_C_C++"
    echo ""
    echo "📦 其他必需工具:"
    echo "  Ubuntu/Debian: sudo apt-get install cmake pkg-config curl wget"
    echo "  CentOS/RHEL:   sudo yum install cmake pkgconfig curl wget"
    echo "  Fedora:        sudo dnf install cmake pkgconfig curl wget"
    echo "  Arch:          sudo pacman -S cmake pkg-config curl wget"
    echo "  openSUSE:      sudo zypper install cmake pkg-config curl wget"
    echo ""
    echo "🎨 Qt5 开发包:"
    echo "  Ubuntu/Debian: sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools"
    echo "  CentOS/RHEL:   sudo yum install qt5-qtbase-devel qt5-qtbase-gui"
    echo "  Fedora:        sudo dnf install qt5-qtbase-devel qt5-qtbase-gui"
    echo "  Arch:          sudo pacman -S qt5-base qt5-tools"
    echo "  openSUSE:      sudo zypper install libQt5Core-devel libQt5Widgets-devel libQt5Network-devel"
    echo ""
    echo "🚀 安装完成后，重新运行此脚本"
    echo "============================================"
}

# 检测并安装包管理器
detect_and_install_package_manager

# 安装依赖
install_dependencies

# 安装 Rust
if ! command -v rustc &> /dev/null; then
    log_info "安装 Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    export PATH="$HOME/.cargo/bin:$PATH"
else
    log_success "Rust 已安装: $(rustc --version)"
fi

log_success "系统依赖检查完成"

# 编译 Rust 后端
log_info "编译 Rust 后端..."
cargo build --release

if [ -f "target/release/scan_demo" ]; then
    log_success "Rust 后端编译成功"
    chmod +x target/release/scan_demo
    ls -la target/release/scan_demo
else
    log_error "Rust 后端编译失败"
    exit 1
fi

# 编译 Qt 前端
log_info "编译 Qt 前端..."

if [ ! -d "qt_frontend" ]; then
    log_error "未找到 qt_frontend 目录"
    exit 1
fi

cd qt_frontend

if [ ! -f "CMakeLists.txt" ]; then
    log_error "未找到 CMakeLists.txt 文件"
    exit 1
fi

# 创建构建目录
mkdir -p build
cd build

# 配置和编译
log_info "配置 CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

log_info "开始编译..."
make -j$(nproc)

if [ -f "bin/ScanDemoFrontend" ]; then
    log_success "Qt 前端编译成功"
    chmod +x bin/ScanDemoFrontend
    ls -la bin/ScanDemoFrontend
else
    log_error "Qt 前端编译失败"
    exit 1
fi

# 返回项目根目录
cd ../..

# 创建启动脚本
log_info "创建启动脚本..."

cat > start_backend.sh << 'EOF'
#!/bin/bash
echo "启动 Rust 后端服务..."
cd "$(dirname "$0")"
./target/release/scan_demo
EOF

cat > start_frontend.sh << 'EOF'
#!/bin/bash
echo "启动 Qt 前端应用..."
cd "$(dirname "$0")"
export API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
./qt_frontend/build/bin/ScanDemoFrontend
EOF

cat > start_complete.sh << 'EOF'
#!/bin/bash
echo "启动完整的扫码生产看板应用..."

# 检查后端是否已运行
if pgrep -f "scan_demo" > /dev/null; then
    echo "后端服务已在运行"
else
    echo "启动后端服务..."
    cd "$(dirname "$0")"
    nohup ./target/release/scan_demo > backend.log 2>&1 &
    sleep 2
fi

# 启动前端
echo "启动前端应用..."
export API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
./qt_frontend/build/bin/ScanDemoFrontend
EOF

chmod +x start_backend.sh start_frontend.sh start_complete.sh

# 显示结果
echo ""
echo "============================================"
echo "🎉 编译完成！"
echo "============================================"
echo ""
echo "📁 生成的文件："
echo "  - Rust 后端: target/release/scan_demo"
echo "  - Qt 前端: qt_frontend/build/bin/ScanDemoFrontend"
echo "  - 启动脚本: start_*.sh"
echo ""
echo "🚀 快速启动："
echo "  ./start_complete.sh"
echo ""
echo "📖 详细说明："
echo "  1. 后端服务默认监听端口 3000"
echo "  2. 前端会自动连接到 http://localhost:3000"
echo "  3. 可通过环境变量 API_BASE_URL 修改后端地址"
echo "  4. 数据库文件: scan_demo.db"
echo "============================================"
