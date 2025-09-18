#!/bin/bash

# Windows 交叉编译脚本 - 为树莓派编译 Linux 版本
echo "=== 交叉编译脚本 - 为树莓派编译 Linux 版本 ==="

# 检查是否在 Windows 环境
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo "检测到 Windows 环境"
else
    echo "此脚本需要在 Windows 环境下运行"
    echo "请使用 Git Bash 或 WSL 运行此脚本"
    exit 1
fi

# 检查 Rust 是否已安装
if ! command -v cargo &> /dev/null; then
    echo "错误：未找到 cargo 命令"
    echo "请先安装 Rust：https://rustup.rs/"
    exit 1
fi

echo "当前 Rust 版本："
rustc --version
cargo --version

# 添加 Linux 目标
echo ""
echo "添加 Linux 目标..."

# 根据树莓派型号选择目标
echo "请选择树莓派型号："
echo "1) 树莓派 4B/5 (64位) - aarch64-unknown-linux-gnu"
echo "2) 树莓派 3B/3B+ (32位) - armv7-unknown-linux-gnueabihf"
echo "3) 树莓派 Zero/1 (32位) - arm-unknown-linux-gnueabihf"
echo "4) 通用 x86_64 Linux - x86_64-unknown-linux-gnu"

read -p "请输入选择 (1-4): " choice

case $choice in
    1)
        TARGET="aarch64-unknown-linux-gnu"
        echo "选择目标：$TARGET"
        ;;
    2)
        TARGET="armv7-unknown-linux-gnueabihf"
        echo "选择目标：$TARGET"
        ;;
    3)
        TARGET="arm-unknown-linux-gnueabihf"
        echo "选择目标：$TARGET"
        ;;
    4)
        TARGET="x86_64-unknown-linux-gnu"
        echo "选择目标：$TARGET"
        ;;
    *)
        echo "无效选择，使用默认目标：aarch64-unknown-linux-gnu"
        TARGET="aarch64-unknown-linux-gnu"
        ;;
esac

# 添加目标
echo "添加目标：$TARGET"
rustup target add $TARGET

# 设置交叉编译环境变量
export CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc
export CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++
export CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
export CXX_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++
export CC_arm_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
export CXX_arm_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++

# 开始编译
echo ""
echo "开始交叉编译..."
echo "目标：$TARGET"
echo "这可能需要几分钟..."

if cargo build --release --target $TARGET; then
    echo ""
    echo "编译成功！"
    echo "二进制文件位置：target/$TARGET/release/scan_demo"
    echo ""
    echo "传输到树莓派的方法："
    echo "1. 使用 SCP："
    echo "   scp target/$TARGET/release/scan_demo user@raspberry-pi-ip:/path/to/project/"
    echo ""
    echo "2. 使用 USB 存储设备"
    echo ""
    echo "3. 在树莓派上设置执行权限："
    echo "   chmod +x scan_demo"
    echo ""
    echo "4. 运行："
    echo "   ./scan_demo --cli"
else
    echo ""
    echo "编译失败！"
    echo ""
    echo "可能的解决方案："
    echo "1. 安装交叉编译工具链："
    if [[ "$TARGET" == *"aarch64"* ]]; then
        echo "   sudo apt-get install gcc-aarch64-linux-gnu"
    elif [[ "$TARGET" == *"armv7"* ]]; then
        echo "   sudo apt-get install gcc-arm-linux-gnueabihf"
    elif [[ "$TARGET" == *"arm-"* ]]; then
        echo "   sudo apt-get install gcc-arm-linux-gnueabihf"
    fi
    echo ""
    echo "2. 或者直接在树莓派上编译"
    echo ""
    echo "3. 检查网络连接和依赖下载"
    exit 1
fi

