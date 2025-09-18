#!/bin/bash 
 
# Rust + Qt Scan Demo Linux Build Script 
 
set -e 
 
echo "Starting build..." 
 
# Check if in project root 
if [ ! -f "Cargo.toml" ]; then 
    echo "Please run in project root directory" 
    exit 1 
fi 
 
# Install dependencies 
if command -v apt-get &> /dev/null; then 
    sudo apt-get update 
    sudo apt-get install -y build-essential cmake pkg-config curl 
    sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools 
elif command -v yum &> /dev/null; then 
    sudo yum update -y 
    sudo yum install -y gcc gcc-c++ make cmake pkgconfig curl 
    sudo yum install -y qt5-qtbase-devel qt5-qtbase-gui 
elif command -v dnf &> /dev/null; then 
    sudo dnf update -y 
    sudo dnf install -y gcc gcc-c++ make cmake pkgconfig curl 
    sudo dnf install -y qt5-qtbase-devel qt5-qtbase-gui 
fi 
 
# Install Rust 
if ! command -v rustc &> /dev/null; then 
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 
    source ~/.cargo/env 
    export PATH="$HOME/.cargo/bin:$PATH" 
fi 
 
# Build Rust backend 
cargo build --release 
 
# Build Qt frontend 
cd qt_frontend 
mkdir -p build 
cd build 
cmake .. -DCMAKE_BUILD_TYPE=Release 
make -j$(nproc) 
cd ../.. 
 
echo "Build completed!" 
