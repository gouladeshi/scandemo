#!/bin/bash

# ============================================
# Rust + Qt 鎵爜鐢熶骇鐪嬫澘 Linux 绠€鍖栫紪璇戣剼鏈?# ============================================

set -e  # 閬囧埌閿欒绔嬪嵆閫€鍑?
echo "============================================"
echo "馃殌 寮€濮嬬紪璇?Rust + Qt 鎵爜鐢熶骇鐪嬫澘"
echo "============================================"

# 棰滆壊瀹氫箟
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

# 妫€鏌ユ槸鍚﹀湪椤圭洰鏍圭洰褰?
if [ ! -f "Cargo.toml" ]; then
    log_error "璇峰湪椤圭洰鏍圭洰褰曡繍琛屾鑴氭湰"
    exit 1
fi

# 妫€鏌ュ苟瀹夎绯荤粺渚濊禆
log_info "妫€鏌ョ郴缁熶緷璧?.."

# 妫€鏌ュ寘绠＄悊鍣ㄥ苟瀹夎渚濊禆
if command -v apt-get &> /dev/null; then
    log_info "浣跨敤 apt-get 瀹夎渚濊禆..."
    sudo apt-get update
    sudo apt-get install -y build-essential cmake pkg-config curl
    
    # 瀹夎 Qt5 寮€鍙戝寘
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "瀹夎 Qt5 寮€鍙戝寘..."
        sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
    fi
    
elif command -v yum &> /dev/null; then
    log_info "浣跨敤 yum 瀹夎渚濊禆..."
    sudo yum update -y
    sudo yum install -y gcc gcc-c++ make cmake pkgconfig curl
    
    # 瀹夎 Qt5 寮€鍙戝寘
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "瀹夎 Qt5 寮€鍙戝寘..."
        sudo yum install -y qt5-qtbase-devel qt5-qtbase-gui
    fi
    
elif command -v dnf &> /dev/null; then
    log_info "浣跨敤 dnf 瀹夎渚濊禆..."
    sudo dnf update -y
    sudo dnf install -y gcc gcc-c++ make cmake pkgconfig curl
    
    # 瀹夎 Qt5 寮€鍙戝寘
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "瀹夎 Qt5 寮€鍙戝寘..."
        sudo dnf install -y qt5-qtbase-devel qt5-qtbase-gui
    fi
    
else
    log_error "鏈壘鍒版敮鎸佺殑鍖呯鐞嗗櫒 (apt-get, yum, dnf)"
    log_info "璇锋墜鍔ㄥ畨瑁呬互涓嬩緷璧?"
    log_info "  - build-essential (gcc, make)"
    log_info "  - cmake"
    log_info "  - pkg-config"
    log_info "  - qt5 寮€鍙戝寘"
    exit 1
fi

# 瀹夎 Rust
if ! command -v rustc &> /dev/null; then
    log_info "瀹夎 Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    export PATH="$HOME/.cargo/bin:$PATH"
else
    log_success "Rust 宸插畨瑁? $(rustc --version)"
fi

log_success "绯荤粺渚濊禆妫€鏌ュ畬鎴?

# 缂栬瘧 Rust 鍚庣
log_info "缂栬瘧 Rust 鍚庣..."
cargo build --release

if [ -f "target/release/scan_demo" ]; then
    log_success "Rust 鍚庣缂栬瘧鎴愬姛"
    chmod +x target/release/scan_demo
    ls -la target/release/scan_demo
else
    log_error "Rust 鍚庣缂栬瘧澶辫触"
    exit 1
fi

# 缂栬瘧 Qt 鍓嶇
log_info "缂栬瘧 Qt 鍓嶇..."

if [ ! -d "qt_frontend" ]; then
    log_error "鏈壘鍒?qt_frontend 鐩綍"
    exit 1
fi

cd qt_frontend

if [ ! -f "CMakeLists.txt" ]; then
    log_error "鏈壘鍒?CMakeLists.txt 鏂囦欢"
    exit 1
fi

# 鍒涘缓鏋勫缓鐩綍
mkdir -p build
cd build

# 閰嶇疆鍜岀紪璇?log_info "閰嶇疆 CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

log_info "寮€濮嬬紪璇?.."
make -j$(nproc)

if [ -f "bin/ScanDemoFrontend" ]; then
    log_success "Qt 鍓嶇缂栬瘧鎴愬姛"
    chmod +x bin/ScanDemoFrontend
    ls -la bin/ScanDemoFrontend
else
    log_error "Qt 鍓嶇缂栬瘧澶辫触"
    exit 1
fi

# 杩斿洖椤圭洰鏍圭洰褰?cd ../..

# 鍒涘缓鍚姩鑴氭湰
log_info "鍒涘缓鍚姩鑴氭湰..."

cat > start_backend.sh << 'EOF'
#!/bin/bash
echo "鍚姩 Rust 鍚庣鏈嶅姟..."
cd "$(dirname "$0")"
./target/release/scan_demo
EOF

cat > start_frontend.sh << 'EOF'
#!/bin/bash
echo "鍚姩 Qt 鍓嶇搴旂敤..."
cd "$(dirname "$0")"
export API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
./qt_frontend/build/bin/ScanDemoFrontend
EOF

cat > start_complete.sh << 'EOF'
#!/bin/bash
echo "鍚姩瀹屾暣鐨勬壂鐮佺敓浜х湅鏉垮簲鐢?.."

# 妫€鏌ュ悗绔槸鍚﹀凡杩愯
if pgrep -f "scan_demo" > /dev/null; then
    echo "鍚庣鏈嶅姟宸插湪杩愯"
else
    echo "鍚姩鍚庣鏈嶅姟..."
    cd "$(dirname "$0")"
    nohup ./target/release/scan_demo > backend.log 2>&1 &
    sleep 2
fi

# 鍚姩鍓嶇
echo "鍚姩鍓嶇搴旂敤..."
export API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
./qt_frontend/build/bin/ScanDemoFrontend
EOF

chmod +x start_backend.sh start_frontend.sh start_complete.sh

# 鏄剧ず缁撴灉
echo ""
echo "============================================"
echo "馃帀 缂栬瘧瀹屾垚锛?
echo "============================================"
echo ""
echo "馃搧 鐢熸垚鐨勬枃浠讹細"
echo "  - Rust 鍚庣: target/release/scan_demo"
echo "  - Qt 鍓嶇: qt_frontend/build/bin/ScanDemoFrontend"
echo "  - 鍚姩鑴氭湰: start_*.sh"
echo ""
echo "馃殌 蹇€熷惎鍔細"
echo "  ./start_complete.sh"
echo ""
echo "馃摉 璇︾粏璇存槑锛?
echo "  1. 鍚庣鏈嶅姟榛樿鐩戝惉绔彛 3000"
echo "  2. 鍓嶇浼氳嚜鍔ㄨ繛鎺ュ埌 http://localhost:3000"
echo "  3. 鍙€氳繃鐜鍙橀噺 API_BASE_URL 淇敼鍚庣鍦板潃"
echo "  4. 鏁版嵁搴撴枃浠? scan_demo.db"
echo "============================================"
