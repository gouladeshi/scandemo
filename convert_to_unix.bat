@echo off
echo Converting to Unix format...

REM Create a simple Unix format script
echo #!/bin/bash > build_linux_working.sh
echo. >> build_linux_working.sh
echo # Rust + Qt Scan Demo Linux Build Script >> build_linux_working.sh
echo. >> build_linux_working.sh
echo set -e >> build_linux_working.sh
echo. >> build_linux_working.sh
echo echo "Starting build..." >> build_linux_working.sh
echo. >> build_linux_working.sh
echo # Check if in project root >> build_linux_working.sh
echo if [ ! -f "Cargo.toml" ]; then >> build_linux_working.sh
echo     echo "Please run in project root directory" >> build_linux_working.sh
echo     exit 1 >> build_linux_working.sh
echo fi >> build_linux_working.sh
echo. >> build_linux_working.sh
echo # Install dependencies >> build_linux_working.sh
echo if command -v apt-get ^&^> /dev/null; then >> build_linux_working.sh
echo     sudo apt-get update >> build_linux_working.sh
echo     sudo apt-get install -y build-essential cmake pkg-config curl >> build_linux_working.sh
echo     sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools >> build_linux_working.sh
echo elif command -v yum ^&^> /dev/null; then >> build_linux_working.sh
echo     sudo yum update -y >> build_linux_working.sh
echo     sudo yum install -y gcc gcc-c++ make cmake pkgconfig curl >> build_linux_working.sh
echo     sudo yum install -y qt5-qtbase-devel qt5-qtbase-gui >> build_linux_working.sh
echo elif command -v dnf ^&^> /dev/null; then >> build_linux_working.sh
echo     sudo dnf update -y >> build_linux_working.sh
echo     sudo dnf install -y gcc gcc-c++ make cmake pkgconfig curl >> build_linux_working.sh
echo     sudo dnf install -y qt5-qtbase-devel qt5-qtbase-gui >> build_linux_working.sh
echo fi >> build_linux_working.sh
echo. >> build_linux_working.sh
echo # Install Rust >> build_linux_working.sh
echo if ! command -v rustc ^&^> /dev/null; then >> build_linux_working.sh
echo     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs ^| sh -s -- -y >> build_linux_working.sh
echo     source ~/.cargo/env >> build_linux_working.sh
echo     export PATH="$HOME/.cargo/bin:$PATH" >> build_linux_working.sh
echo fi >> build_linux_working.sh
echo. >> build_linux_working.sh
echo # Build Rust backend >> build_linux_working.sh
echo cargo build --release >> build_linux_working.sh
echo. >> build_linux_working.sh
echo # Build Qt frontend >> build_linux_working.sh
echo cd qt_frontend >> build_linux_working.sh
echo mkdir -p build >> build_linux_working.sh
echo cd build >> build_linux_working.sh
echo cmake .. -DCMAKE_BUILD_TYPE=Release >> build_linux_working.sh
echo make -j$(nproc) >> build_linux_working.sh
echo cd ../.. >> build_linux_working.sh
echo. >> build_linux_working.sh
echo echo "Build completed!" >> build_linux_working.sh

echo Conversion completed!
echo Created: build_linux_working.sh
echo.
echo Now copy this file to Linux and run:
echo   chmod +x build_linux_working.sh
echo   ./build_linux_working.sh
pause