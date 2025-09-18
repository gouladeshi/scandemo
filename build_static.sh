#!/bin/bash

# 静态链接构建脚本
echo "=== 静态链接构建脚本 ==="

# 设置静态链接环境变量
export RUSTFLAGS="-C target-feature=+crt-static"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS="-C target-feature=+crt-static"

# 安装 musl 工具链（用于静态链接）
echo "安装 musl 工具链..."
if command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y musl-tools
elif command -v dnf &> /dev/null; then
    sudo dnf install -y musl-gcc
elif command -v yum &> /dev/null; then
    sudo yum install -y musl-gcc
fi

# 添加 musl 目标
echo "添加 musl 目标..."
rustup target add x86_64-unknown-linux-musl

# 创建静态链接配置
echo "创建静态链接配置..."
mkdir -p .cargo
cat > .cargo/config.toml << 'EOF'
[target.x86_64-unknown-linux-musl]
linker = "musl-gcc"
rustflags = ["-C", "target-feature=+crt-static"]

[build]
target = "x86_64-unknown-linux-musl"
EOF

# 编译静态链接版本
echo "编译静态链接版本..."
cargo build --release --target x86_64-unknown-linux-musl

# 检查编译结果
if [ -f "target/x86_64-unknown-linux-musl/release/scan_demo" ]; then
    echo "✅ 静态链接版本编译成功"
    
    # 复制到项目根目录
    cp target/x86_64-unknown-linux-musl/release/scan_demo ./scan_demo_static
    chmod +x ./scan_demo_static
    
    # 显示文件信息
    echo "静态链接文件信息："
    ls -lh ./scan_demo_static
    file ./scan_demo_static
    
    echo ""
    echo "✅ 静态链接版本已创建: ./scan_demo_static"
    echo "此文件可以在任何 Linux x86_64 系统上运行，无需安装任何依赖"
else
    echo "❌ 静态链接版本编译失败"
    exit 1
fi
