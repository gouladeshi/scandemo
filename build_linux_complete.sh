#!/bin/bash

# ============================================
# Rust + Qt 扫码生产看板 Linux 完整编译脚本
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

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 未安装"
        return 1
    fi
    return 0
}

# 检查并安装系统依赖
install_system_deps() {
    log_info "检查系统依赖..."
    
    # 检查包管理器
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        UPDATE_CMD="sudo apt-get update"
        INSTALL_CMD="sudo apt-get install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        UPDATE_CMD="sudo yum update -y"
        INSTALL_CMD="sudo yum install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        UPDATE_CMD="sudo dnf update -y"
        INSTALL_CMD="sudo dnf install -y"
    else
        log_error "未找到支持的包管理器 (apt-get, yum, dnf)"
        exit 1
    fi
    
    log_info "使用包管理器: $PKG_MANAGER"
    
    # 更新包列表
    log_info "更新包列表..."
    $UPDATE_CMD
    
    # 安装基础构建工具
    log_info "安装基础构建工具..."
    $INSTALL_CMD build-essential curl wget
    
    # 安装 Rust
    if ! check_command rustc; then
        log_info "安装 Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    else
        log_success "Rust 已安装: $(rustc --version)"
    fi
    
    # 安装 Qt5 开发包
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "安装 Qt5 开发包..."
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            $INSTALL_CMD qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
        elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
            $INSTALL_CMD qt5-qtbase-devel qt5-qtbase-gui
        fi
    else
        log_success "Qt5 开发包已安装"
    fi
    
    # 安装 CMake
    if ! check_command cmake; then
        log_info "安装 CMake..."
        $INSTALL_CMD cmake
    else
        log_success "CMake 已安装: $(cmake --version | head -n1)"
    fi
    
    # 安装 pkg-config
    if ! check_command pkg-config; then
        log_info "安装 pkg-config..."
        $INSTALL_CMD pkg-config
    fi
    
    log_success "系统依赖检查完成"
}

# 编译 Rust 后端
build_rust_backend() {
    log_info "开始编译 Rust 后端..."
    
    # 确保在项目根目录
    cd "$(dirname "$0")"
    
    # 设置 Rust 环境
    if [ -f ~/.cargo/env ]; then
        source ~/.cargo/env
    fi
    
    # 检查 Cargo.toml 是否存在
    if [ ! -f "Cargo.toml" ]; then
        log_error "未找到 Cargo.toml 文件"
        exit 1
    fi
    
    # 编译 Rust 项目
    log_info "运行 cargo build --release..."
    cargo build --release
    
    # 检查编译结果
    if [ -f "target/release/scan_demo" ]; then
        log_success "Rust 后端编译成功"
        log_info "可执行文件: $(pwd)/target/release/scan_demo"
        
        # 设置执行权限
        chmod +x target/release/scan_demo
        
        # 显示文件信息
        ls -la target/release/scan_demo
    else
        log_error "Rust 后端编译失败"
        exit 1
    fi
}

# 编译 Qt 前端
build_qt_frontend() {
    log_info "开始编译 Qt 前端..."
    
    # 检查 qt_frontend 目录
    if [ ! -d "qt_frontend" ]; then
        log_error "未找到 qt_frontend 目录"
        exit 1
    fi
    
    # 进入前端目录
    cd qt_frontend
    
    # 检查 CMakeLists.txt
    if [ ! -f "CMakeLists.txt" ]; then
        log_error "未找到 CMakeLists.txt 文件"
        exit 1
    fi
    
    # 创建构建目录
    log_info "创建构建目录..."
    mkdir -p build
    cd build
    
    # 配置 CMake
    log_info "配置 CMake..."
    cmake .. -DCMAKE_BUILD_TYPE=Release
    
    # 编译
    log_info "开始编译 Qt 前端..."
    make -j$(nproc)
    
    # 检查编译结果
    if [ -f "bin/ScanDemoFrontend" ]; then
        log_success "Qt 前端编译成功"
        log_info "可执行文件: $(pwd)/bin/ScanDemoFrontend"
        
        # 设置执行权限
        chmod +x bin/ScanDemoFrontend
        
        # 显示文件信息
        ls -la bin/ScanDemoFrontend
    else
        log_error "Qt 前端编译失败"
        exit 1
    fi
    
    # 返回项目根目录
    cd ../..
}

# 创建启动脚本
create_startup_scripts() {
    log_info "创建启动脚本..."
    
    # 创建后端启动脚本
    cat > start_backend.sh << 'EOF'
#!/bin/bash
echo "启动 Rust 后端服务..."
cd "$(dirname "$0")"
./target/release/scan_demo
EOF
    
    # 创建前端启动脚本
    cat > start_frontend.sh << 'EOF'
#!/bin/bash
echo "启动 Qt 前端应用..."
cd "$(dirname "$0")"
export API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
./qt_frontend/build/bin/ScanDemoFrontend
EOF
    
    # 创建完整启动脚本
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
    
    # 设置执行权限
    chmod +x start_backend.sh start_frontend.sh start_complete.sh
    
    log_success "启动脚本创建完成"
}

# 创建部署包
create_deployment_package() {
    log_info "创建部署包..."
    
    # 创建部署目录
    DEPLOY_DIR="scan-demo-linux-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$DEPLOY_DIR"
    
    # 复制可执行文件
    cp target/release/scan_demo "$DEPLOY_DIR/"
    cp qt_frontend/build/bin/ScanDemoFrontend "$DEPLOY_DIR/"
    
    # 复制启动脚本
    cp start_backend.sh start_frontend.sh start_complete.sh "$DEPLOY_DIR/"
    
    # 复制数据库文件（如果存在）
    if [ -f "scan_demo.db" ]; then
        cp scan_demo.db "$DEPLOY_DIR/"
    fi
    
    # 复制静态文件（如果存在）
    if [ -d "static" ]; then
        cp -r static "$DEPLOY_DIR/"
    fi
    
    # 复制模板文件（如果存在）
    if [ -d "templates" ]; then
        cp -r templates "$DEPLOY_DIR/"
    fi
    
    # 创建 README
    cat > "$DEPLOY_DIR/README.md" << 'EOF'
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
EOF
    
    # 创建压缩包
    log_info "创建压缩包..."
    tar -czf "${DEPLOY_DIR}.tar.gz" "$DEPLOY_DIR"
    
    log_success "部署包创建完成: ${DEPLOY_DIR}.tar.gz"
    log_info "部署目录: $DEPLOY_DIR"
}

# 显示编译结果
show_results() {
    echo ""
    echo "============================================"
    echo "🎉 编译完成！"
    echo "============================================"
    echo ""
    echo "📁 生成的文件："
    echo "  - Rust 后端: target/release/scan_demo"
    echo "  - Qt 前端: qt_frontend/build/bin/ScanDemoFrontend"
    echo "  - 启动脚本: start_*.sh"
    echo "  - 部署包: scan-demo-linux-*.tar.gz"
    echo ""
    echo "🚀 快速启动："
    echo "  ./start_complete.sh"
    echo ""
    echo "📖 详细说明请查看部署包中的 README.md"
    echo "============================================"
}

# 主函数
main() {
    # 检查是否在正确的目录
    if [ ! -f "Cargo.toml" ]; then
        log_error "请在项目根目录运行此脚本"
        exit 1
    fi
    
    # 执行编译步骤
    install_system_deps
    build_rust_backend
    build_qt_frontend
    create_startup_scripts
    create_deployment_package
    show_results
}

# 运行主函数
main "$@"
