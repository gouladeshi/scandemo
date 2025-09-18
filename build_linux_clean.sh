#!/bin/bash

# ============================================
# Rust + Qt Scan Demo Linux Build Script
# ============================================

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if in project root directory
if [ ! -f "Cargo.toml" ]; then
    log_error "Please run this script in the project root directory"
    exit 1
fi

# Check and install system dependencies
log_info "Checking system dependencies..."

# Detect system type and try to install package manager
detect_and_install_package_manager() {
    log_info "Detecting system type and package manager..."
    
    # Detect system type
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
    
    log_info "Detected system: $OS"
    
    # Check if any package manager is available
    if command -v apt-get &> /dev/null || command -v yum &> /dev/null || command -v dnf &> /dev/null || command -v pacman &> /dev/null || command -v zypper &> /dev/null; then
        log_success "Found available package manager"
        return 0
    fi
    
    log_warning "No package manager found, trying to install..."
    
    # Try to install package manager based on system type
    case $OS in
        "ubuntu"|"debian")
            log_info "Trying to install apt-get..."
            if command -v wget &> /dev/null; then
                log_info "Using wget to download apt package..."
                wget -qO- http://archive.ubuntu.com/ubuntu/pool/main/a/apt/apt_2.0.9_amd64.deb -o /tmp/apt.deb
                sudo dpkg -i /tmp/apt.deb || sudo apt-get install -f
            elif command -v curl &> /dev/null; then
                log_info "Using curl to download apt package..."
                curl -L http://archive.ubuntu.com/ubuntu/pool/main/a/apt/apt_2.0.9_amd64.deb -o /tmp/apt.deb
                sudo dpkg -i /tmp/apt.deb || sudo apt-get install -f
            else
                log_error "Need wget or curl to install apt-get"
                return 1
            fi
            ;;
        "centos"|"rhel"|"fedora")
            log_info "Trying to install yum/dnf..."
            if command -v curl &> /dev/null; then
                log_info "Downloading yum package..."
                curl -L http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/yum-4.7.0-4.el8.noarch.rpm -o /tmp/yum.rpm
                sudo rpm -ivh /tmp/yum.rpm
            elif command -v wget &> /dev/null; then
                log_info "Downloading yum package..."
                wget http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/yum-4.7.0-4.el8.noarch.rpm -O /tmp/yum.rpm
                sudo rpm -ivh /tmp/yum.rpm
            else
                log_error "Need curl or wget to install yum"
                return 1
            fi
            ;;
        "arch"|"manjaro")
            log_error "Arch Linux needs complete pacman package manager"
            log_info "Please ensure complete system installation or use other Linux distribution"
            return 1
            ;;
        *)
            log_warning "Unknown system type: $OS"
            log_info "Trying to compile and install basic tools from source..."
            install_from_source
            ;;
    esac
}

# Install dependencies from source (fallback)
install_from_source() {
    log_info "Trying to compile and install basic tools from source..."
    
    if ! command -v gcc &> /dev/null; then
        log_info "Downloading and compiling gcc..."
        log_warning "Compiling gcc from source takes a long time, recommend using package manager"
    fi
    
    if ! command -v make &> /dev/null; then
        log_info "Downloading and compiling make..."
    fi
    
    log_warning "Compiling and installing from source may take a long time"
    log_info "Recommend using complete Linux distribution or ensure package manager is available"
}

# Install dependency packages
install_dependencies() {
    log_info "Installing system dependencies..."
    
    if command -v apt-get &> /dev/null; then
        log_info "Using apt-get to install dependencies..."
        sudo apt-get update
        sudo apt-get install -y build-essential cmake pkg-config curl wget
        
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "Installing Qt5 development packages..."
            sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
        fi
        
    elif command -v yum &> /dev/null; then
        log_info "Using yum to install dependencies..."
        sudo yum update -y
        sudo yum install -y gcc gcc-c++ make cmake pkgconfig curl wget
        
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "Installing Qt5 development packages..."
            sudo yum install -y qt5-qtbase-devel qt5-qtbase-gui
        fi
        
    elif command -v dnf &> /dev/null; then
        log_info "Using dnf to install dependencies..."
        sudo dnf update -y
        sudo dnf install -y gcc gcc-c++ make cmake pkgconfig curl wget
        
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "Installing Qt5 development packages..."
            sudo dnf install -y qt5-qtbase-devel qt5-qtbase-gui
        fi
        
    elif command -v pacman &> /dev/null; then
        log_info "Using pacman to install dependencies..."
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm base-devel cmake pkg-config curl wget
        
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "Installing Qt5 development packages..."
            sudo pacman -S --noconfirm qt5-base qt5-tools
        fi
        
    elif command -v zypper &> /dev/null; then
        log_info "Using zypper to install dependencies..."
        sudo zypper refresh
        sudo zypper install -y gcc gcc-c++ make cmake pkg-config curl wget
        
        if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
            log_info "Installing Qt5 development packages..."
            sudo zypper install -y libQt5Core-devel libQt5Widgets-devel libQt5Network-devel
        fi
        
    else
        log_error "No supported package manager found"
        show_manual_install_guide
        exit 1
    fi
}

# Show manual installation guide
show_manual_install_guide() {
    log_info "Supported package managers: apt-get, yum, dnf, pacman, zypper"
    echo ""
    echo "============================================"
    echo "Manual Installation Guide"
    echo "============================================"
    echo ""
    echo "Basic build tools:"
    echo "  Ubuntu/Debian: sudo apt-get install build-essential"
    echo "  CentOS/RHEL:   sudo yum groupinstall 'Development Tools'"
    echo "  Fedora:        sudo dnf groupinstall 'Development Tools'"
    echo "  Arch:          sudo pacman -S base-devel"
    echo "  openSUSE:      sudo zypper install -t pattern devel_C_C++"
    echo ""
    echo "Other required tools:"
    echo "  Ubuntu/Debian: sudo apt-get install cmake pkg-config curl wget"
    echo "  CentOS/RHEL:   sudo yum install cmake pkgconfig curl wget"
    echo "  Fedora:        sudo dnf install cmake pkgconfig curl wget"
    echo "  Arch:          sudo pacman -S cmake pkg-config curl wget"
    echo "  openSUSE:      sudo zypper install cmake pkg-config curl wget"
    echo ""
    echo "Qt5 development packages:"
    echo "  Ubuntu/Debian: sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools"
    echo "  CentOS/RHEL:   sudo yum install qt5-qtbase-devel qt5-qtbase-gui"
    echo "  Fedora:        sudo dnf install qt5-qtbase-devel qt5-qtbase-gui"
    echo "  Arch:          sudo pacman -S qt5-base qt5-tools"
    echo "  openSUSE:      sudo zypper install libQt5Core-devel libQt5Widgets-devel libQt5Network-devel"
    echo ""
    echo "After installation, run this script again"
    echo "============================================"
}

# Detect and install package manager
detect_and_install_package_manager

# Install dependencies
install_dependencies

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
