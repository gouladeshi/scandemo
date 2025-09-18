#!/bin/bash

# Rust + Qt Scan Demo Linux Build Script

set -e

echo "============================================"
echo "Starting Rust + Qt Scan Demo Build"
echo "============================================"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if in project root directory
if [ ! -f "Cargo.toml" ]; then
    log_error "Please run this script in the project root directory"
    exit 1
fi

# Check and install system dependencies
log_info "Checking system dependencies..."

# Install dependencies based on package manager
if command -v apt-get &> /dev/null; then
    log_info "Using apt-get to install dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential cmake pkg-config curl
    
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "Installing Qt5 development packages..."
        sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
    fi
    
elif command -v yum &> /dev/null; then
    log_info "Using yum to install dependencies..."
    sudo yum update -y
    sudo yum install -y gcc gcc-c++ make cmake pkgconfig curl
    
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "Installing Qt5 development packages..."
        sudo yum install -y qt5-qtbase-devel qt5-qtbase-gui
    fi
    
elif command -v dnf &> /dev/null; then
    log_info "Using dnf to install dependencies..."
    sudo dnf update -y
    sudo dnf install -y gcc gcc-c++ make cmake pkgconfig curl
    
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "Installing Qt5 development packages..."
        sudo dnf install -y qt5-qtbase-devel qt5-qtbase-gui
    fi
    
elif command -v pacman &> /dev/null; then
    log_info "Using pacman to install dependencies..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm base-devel cmake pkg-config curl
    
    if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
        log_info "Installing Qt5 development packages..."
        sudo pacman -S --noconfirm qt5-base qt5-tools
    fi
    
else
    log_error "No supported package manager found"
    echo "Please install the following manually:"
    echo "  - build-essential (gcc, make)"
    echo "  - cmake"
    echo "  - pkg-config"
    echo "  - qt5 development packages"
    echo "  - curl"
    exit 1
fi

# Install Rust
if ! command -v rustc &> /dev/null; then
    log_info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    export PATH="$HOME/.cargo/bin:$PATH"
else
    log_success "Rust already installed: $(rustc --version)"
fi

log_success "System dependency check completed"

# Build Rust backend
log_info "Building Rust backend..."
cargo build --release

if [ -f "target/release/scan_demo" ]; then
    log_success "Rust backend build successful"
    chmod +x target/release/scan_demo
    ls -la target/release/scan_demo
else
    log_error "Rust backend build failed"
    exit 1
fi

# Build Qt frontend
log_info "Building Qt frontend..."

if [ ! -d "qt_frontend" ]; then
    log_error "qt_frontend directory not found"
    exit 1
fi

cd qt_frontend

if [ ! -f "CMakeLists.txt" ]; then
    log_error "CMakeLists.txt file not found"
    exit 1
fi

# Create build directory
mkdir -p build
cd build

# Configure and build
log_info "Configuring CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

log_info "Starting build..."
make -j$(nproc)

if [ -f "bin/ScanDemoFrontend" ]; then
    log_success "Qt frontend build successful"
    chmod +x bin/ScanDemoFrontend
    ls -la bin/ScanDemoFrontend
else
    log_error "Qt frontend build failed"
    exit 1
fi

# Return to project root directory
cd ../..

# Create startup scripts
log_info "Creating startup scripts..."

cat > start_backend.sh << 'EOF'
#!/bin/bash
echo "Starting Rust backend service..."
cd "$(dirname "$0")"
./target/release/scan_demo
EOF

cat > start_frontend.sh << 'EOF'
#!/bin/bash
echo "Starting Qt frontend application..."
cd "$(dirname "$0")"
export API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
./qt_frontend/build/bin/ScanDemoFrontend
EOF

cat > start_complete.sh << 'EOF'
#!/bin/bash
echo "Starting complete scan demo application..."

# Check if backend is already running
if pgrep -f "scan_demo" > /dev/null; then
    echo "Backend service is already running"
else
    echo "Starting backend service..."
    cd "$(dirname "$0")"
    nohup ./target/release/scan_demo > backend.log 2>&1 &
    sleep 2
fi

# Start frontend
echo "Starting frontend application..."
export API_BASE_URL=${API_BASE_URL:-"http://localhost:3000"}
./qt_frontend/build/bin/ScanDemoFrontend
EOF

chmod +x start_backend.sh start_frontend.sh start_complete.sh

# Show results
echo ""
echo "============================================"
echo "Build completed!"
echo "============================================"
echo ""
echo "Generated files:"
echo "  - Rust backend: target/release/scan_demo"
echo "  - Qt frontend: qt_frontend/build/bin/ScanDemoFrontend"
echo "  - Startup scripts: start_*.sh"
echo ""
echo "Quick start:"
echo "  ./start_complete.sh"
echo ""
echo "Detailed instructions:"
echo "  1. Backend service listens on port 3000 by default"
echo "  2. Frontend will automatically connect to http://localhost:3000"
echo "  3. You can modify backend address via API_BASE_URL environment variable"
echo "  4. Database file: scan_demo.db"
echo "============================================"