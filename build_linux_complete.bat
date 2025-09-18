@echo off
REM ============================================
REM Rust + Qt 扫码生产看板 Linux 编译脚本 (Windows版本)
REM 此脚本用于在Windows环境下准备Linux编译环境
REM ============================================

setlocal enabledelayedexpansion

echo ============================================
echo 🚀 准备 Rust + Qt 扫码生产看板 Linux 编译环境
echo ============================================

REM 检查是否安装了WSL
wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未检测到WSL，请先安装WSL2
    echo 安装命令: wsl --install
    pause
    exit /b 1
)

echo ✅ 检测到WSL环境

REM 检查是否安装了Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未检测到Docker，请先安装Docker Desktop
    echo 下载地址: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo ✅ 检测到Docker环境

echo.
echo 选择编译方式:
echo 1. 使用Docker编译 (推荐)
echo 2. 使用WSL编译
echo 3. 生成Linux编译脚本
set /p choice="请选择 (1-3): "

if "%choice%"=="1" goto docker_build
if "%choice%"=="2" goto wsl_build
if "%choice%"=="3" goto generate_script
goto invalid_choice

:docker_build
echo.
echo 🐳 使用Docker编译...
echo 正在构建Docker镜像...

REM 检查Dockerfile是否存在
if not exist "Dockerfile" (
    echo ❌ 未找到Dockerfile
    pause
    exit /b 1
)

REM 构建Docker镜像
docker build -t scan-demo-linux .

if %errorlevel% neq 0 (
    echo ❌ Docker镜像构建失败
    pause
    exit /b 1
)

echo ✅ Docker镜像构建成功

REM 运行容器并编译
echo 正在编译项目...
docker run --rm -v "%cd%":/workspace -w /workspace scan-demo-linux /bin/bash -c "
    echo '开始编译...'
    cd /workspace
    
    # 编译Rust后端
    echo '编译Rust后端...'
    cargo build --release
    
    # 编译Qt前端
    echo '编译Qt前端...'
    cd qt_frontend
    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    cd ../..
    
    echo '编译完成!'
    ls -la target/release/scan_demo
    ls -la qt_frontend/build/bin/ScanDemoFrontend
"

if %errorlevel% neq 0 (
    echo ❌ 编译失败
    pause
    exit /b 1
)

echo ✅ 编译成功！
echo.
echo 📁 生成的文件:
echo   - target/release/scan_demo
echo   - qt_frontend/build/bin/ScanDemoFrontend
goto end

:wsl_build
echo.
echo 🐧 使用WSL编译...
echo 正在启动WSL编译...

REM 复制编译脚本到WSL
wsl cp build_linux_complete.sh /tmp/build_linux_complete.sh
wsl chmod +x /tmp/build_linux_complete.sh

REM 在WSL中运行编译脚本
wsl /tmp/build_linux_complete.sh

if %errorlevel% neq 0 (
    echo ❌ WSL编译失败
    pause
    exit /b 1
)

echo ✅ WSL编译成功！
goto end

:generate_script
echo.
echo 📝 生成Linux编译脚本...

REM 创建简化的Linux编译脚本
(
echo #!/bin/bash
echo set -e
echo echo "开始编译 Rust + Qt 扫码生产看板..."
echo.
echo # 检查依赖
echo echo "检查系统依赖..."
echo if ! command -v rustc ^&^> /dev/null; then
echo     echo "安装 Rust..."
echo     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs ^| sh -s -- -y
echo     source ~/.cargo/env
echo fi
echo.
echo if ! pkg-config --exists Qt5Core Qt5Widgets Qt5Network; then
echo     echo "安装 Qt5 开发包..."
echo     sudo apt-get update
echo     sudo apt-get install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools build-essential cmake
echo fi
echo.
echo # 编译Rust后端
echo echo "编译 Rust 后端..."
echo cargo build --release
echo.
echo # 编译Qt前端
echo echo "编译 Qt 前端..."
echo cd qt_frontend
echo mkdir -p build
echo cd build
echo cmake .. -DCMAKE_BUILD_TYPE=Release
echo make -j$(nproc^)
echo cd ../..
echo.
echo echo "编译完成!"
echo echo "Rust 后端: target/release/scan_demo"
echo echo "Qt 前端: qt_frontend/build/bin/ScanDemoFrontend"
) > build_linux_simple.sh

echo ✅ Linux编译脚本已生成: build_linux_simple.sh
echo.
echo 使用方法:
echo 1. 将此脚本复制到Linux系统
echo 2. 运行: chmod +x build_linux_simple.sh
echo 3. 运行: ./build_linux_simple.sh
goto end

:invalid_choice
echo ❌ 无效选择，请重新运行脚本
pause
exit /b 1

:end
echo.
echo ============================================
echo 🎉 操作完成！
echo ============================================
echo.
echo 📖 使用说明:
echo 1. Rust后端: ./target/release/scan_demo
echo 2. Qt前端: ./qt_frontend/build/bin/ScanDemoFrontend
echo 3. 确保后端先启动，再启动前端
echo.
pause
