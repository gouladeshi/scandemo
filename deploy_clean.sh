#!/bin/bash

# 扫码生产看板 Ubuntu 部署脚本
echo "=== 扫码生产看板 Ubuntu 部署脚本 ==="

# 若未在 bash 下执行，则切换到 bash 重新执行
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# 基础安全与稳健设置
set -euo pipefail

# 简单重试工具函数
retry_times=3
try_run() {
    local cmd="$1"
    local i=0
    until [ $i -ge $retry_times ]; do
        bash -lc "$cmd" && return 0
        i=$((i+1))
        sleep 2
         done
    return 1
}

# 修复可能存在的包管理器坏状态并安装必要系统包
echo "检查系统依赖..."
sudo dpkg --configure -a || true
sudo apt-get -f install -y || sudo apt --fix-broken install -y || true
try_run "sudo apt-get update"
try_run "sudo apt-get -y dist-upgrade" || true
try_run "sudo apt-get install -y --no-install-recommends curl build-essential libsqlite3-dev pkg-config libssl-dev"

# 检查是否安装了Rust
if ! command -v cargo &> /dev/null; then
    echo "正在安装 Rust..."
    echo "注意：Rust 下载可能需要几分钟，请耐心等待..."
    
# 设置 Rust 镜像源（加速下载）
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup

# 尝试使用清华镜像源安装
if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    echo "使用清华镜像源安装成功"
else
    echo "镜像源安装失败，尝试官方源..."
    # 清除镜像源环境变量，使用官方源
    unset RUSTUP_DIST_SERVER
    unset RUSTUP_UPDATE_ROOT
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
    
    # 加载 Rust 环境
    source ~/.cargo/env
    
    # 设置 Cargo 镜像源（加速后续包下载）
    mkdir -p ~/.cargo
    cat > ~/.cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
EOF
    
    echo "Rust 安装完成"
    echo "已配置国内镜像源以加速后续编译"
else
    echo "Rust 已安装"
fi

# 编译项目
echo "正在编译项目..."
# 确保 cargo 在 PATH 中（处理非交互 shell 的环境变量）
if ! command -v cargo &> /dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1090
        source "$HOME/.cargo/env" || true
    fi
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# 检查是否已有编译好的二进制文件
if [ -f "./target/release/scan_demo" ]; then
    echo "发现已编译的二进制文件，跳过编译"
else
    echo "开始编译，这可能需要几分钟..."
    echo ""
    echo "注意：当前项目中有 Windows 预编译版本 (scan_demo.exe)，但需要 Linux 版本"
    echo "如果编译太慢，建议："
    echo "1. 在 Windows 上交叉编译 Linux 版本"
    echo "2. 或者使用 GitHub Actions 等 CI/CD 服务编译"
    echo "3. 或者耐心等待当前编译完成"
    echo ""
    
    # 设置编译优化
    export CARGO_BUILD_JOBS=2  # 限制并行编译任务数，避免内存不足
    
    # 设置 OpenSSL 环境变量，使用系统 OpenSSL
    export OPENSSL_STATIC=0
    export OPENSSL_DIR=/usr
    export OPENSSL_INCLUDE_DIR=/usr/include/openssl
    
    # 根据架构设置正确的库路径
    ARCH=$(uname -m)
    case $ARCH in
        aarch64)
            export OPENSSL_LIB_DIR=/usr/lib/aarch64-linux-gnu
            ;;
        armv7l)
            export OPENSSL_LIB_DIR=/usr/lib/arm-linux-gnueabihf
            ;;
        armv6l)
            export OPENSSL_LIB_DIR=/usr/lib/arm-linux-gnueabihf
            ;;
        *)
            export OPENSSL_LIB_DIR=/usr/lib
            ;;
    esac
    
    echo "检测到架构: $ARCH"
    echo "OpenSSL 库路径: $OPENSSL_LIB_DIR"
    
    if cargo build --release; then
        echo "编译成功"
    else
        echo "编译失败，可能的原因："
        echo "1. 内存不足（树莓派内存较小）"
        echo "2. 网络问题导致依赖下载失败"
        echo "3. 磁盘空间不足"
        echo "4. OpenSSL 构建错误"
        echo ""
        echo "诊断信息："
        echo "OpenSSL 版本: $(openssl version 2>/dev/null || echo '未安装')"
        echo "可用内存: $(free -h | grep Mem | awk '{print $7}' || echo '未知')"
        echo "磁盘空间: $(df -h . | tail -1 | awk '{print $4}' || echo '未知')"
        echo ""
        echo "建议："
        echo "1. 增加 swap 空间：sudo dphys-swapfile swapoff && sudo dphys-swapfile swapon"
        echo "2. 清理磁盘空间：sudo apt-get autoremove && sudo apt-get autoclean"
        echo "3. 检查网络连接"
        echo "4. 安装 OpenSSL 开发库：sudo apt-get install -y libssl-dev"
        echo "5. 考虑在 Windows 上交叉编译："
        echo "   rustup target add aarch64-unknown-linux-gnu  # 或 armv7-unknown-linux-gnueabihf"
        echo "   cargo build --release --target aarch64-unknown-linux-gnu"
        echo "6. 或者使用 rustls 替代 OpenSSL（推荐）"
        exit 1
    fi
fi

# 创建配置文件
if [ ! -f .env ]; then
    echo "创建配置文件..."
    cat > .env << EOF
DATABASE_URL=sqlite:scan_demo.db
EXTERNAL_API_URL=https://httpbin.org/post
RUST_LOG=info,sqlx=warn
EOF
fi

echo "=== 部署完成 ==="
echo ""

# 获取树莓派IP地址
PI_IP=$(hostname -I | awk '{print $1}')
echo "树莓派IP地址: $PI_IP"

echo ""
echo "运行方式："
echo "1. CLI模式（推荐）："
echo "   ./target/release/scan_demo --cli"
echo ""
echo "2. Web模式："
echo "   ./target/release/scan_demo"
echo "   然后浏览器访问: http://$PI_IP:3000"
echo ""
echo "3. 后台运行："
echo "   nohup ./target/release/scan_demo --cli > scan_demo.log 2>&1 &"
echo ""
echo "4. 查看日志："
echo "   tail -f scan_demo.log"
echo ""
echo "=== 网络访问配置 ==="
echo "应用已配置为监听所有网络接口 (0.0.0.0:3000)"
echo "可以从以下地址访问："
echo "- 树莓派本地: http://localhost:3000"
echo "- 局域网访问: http://$PI_IP:3000"
echo "- 其他设备访问: http://$PI_IP:3000"
echo ""
echo "如果无法从其他设备访问，请检查："
echo "1. 防火墙设置: sudo ufw allow 3000"
echo "2. 网络连接: ping $PI_IP"
echo "3. 端口监听: netstat -tlnp | grep 3000"
echo ""
echo "=== 网络配置检查 ==="
echo "检查防火墙状态..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | grep "Status:" | awk '{print $2}')
    echo "UFW 防火墙状态: $UFW_STATUS"
    if [ "$UFW_STATUS" = "active" ]; then
        if sudo ufw status | grep -q "3000"; then
            echo "✅ 端口 3000 已在防火墙中开放"
        else
            echo "⚠️  端口 3000 未在防火墙中开放，运行以下命令开放："
            echo "   sudo ufw allow 3000"
        fi
    else
        echo "✅ 防火墙未启用，无需配置"
    fi
else
    echo "UFW 防火墙未安装"
fi

echo ""
echo "检查网络接口..."
echo "可用网络接口："
ip addr show | grep -E "inet [0-9]" | grep -v "127.0.0.1" | awk '{print "  " $2}' | cut -d'/' -f1

echo ""
echo "=== 网络连接测试 ==="
echo "测试网络连接..."

# 测试网关连接
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$GATEWAY" ]; then
    echo "网关地址: $GATEWAY"
    if ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then
        echo "✅ 网关连接正常"
    else
        echo "❌ 网关连接失败"
    fi
fi

# 测试DNS解析
if nslookup google.com >/dev/null 2>&1; then
    echo "✅ DNS解析正常"
else
    echo "❌ DNS解析失败"
fi

# 测试外网连接
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ 外网连接正常"
else
    echo "❌ 外网连接失败"
fi

echo ""
echo "检查端口监听状态..."
if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo "✅ 端口 3000 正在监听"
    netstat -tlnp | grep ":3000 "
else
    echo "❌ 端口 3000 未在监听"
    echo ""
    echo "=== 应用启动诊断 ==="
    
    # 检查二进制文件是否存在
    if [ -f "./target/release/scan_demo" ]; then
        echo "✅ 找到编译好的二进制文件"
        echo "文件信息:"
        ls -la ./target/release/scan_demo
        
        # 检查文件权限
        if [ -x "./target/release/scan_demo" ]; then
            echo "✅ 文件有执行权限"
        else
            echo "❌ 文件没有执行权限，正在修复..."
            chmod +x ./target/release/scan_demo
            echo "✅ 已添加执行权限"
        fi
        
        # 检查是否有进程在运行
        if pgrep -f "scan_demo" >/dev/null; then
            echo "⚠️  发现 scan_demo 进程正在运行，但端口未监听"
            echo "进程信息:"
            ps aux | grep scan_demo | grep -v grep
            echo ""
            echo "可能原因："
            echo "1. 应用启动失败但进程未退出"
            echo "2. 应用监听其他端口"
            echo "3. 应用配置错误"
            echo ""
            echo "建议："
            echo "1. 停止现有进程: pkill -f scan_demo"
            echo "2. 重新启动应用"
        else
            echo "❌ 没有发现 scan_demo 进程"
            echo ""
            echo "=== 启动应用 ==="
            echo "正在启动应用..."
            
            # 检查配置文件
            if [ -f ".env" ]; then
                echo "✅ 找到配置文件 .env"
            else
                echo "⚠️  未找到配置文件，将创建默认配置"
            fi
            
            # 尝试启动应用
            echo "启动命令: ./target/release/scan_demo"
            echo "如果启动失败，请检查："
            echo "1. 数据库文件权限"
            echo "2. 端口是否被其他程序占用"
            echo "3. 应用日志输出"
            echo ""
            echo "手动启动命令："
            echo "  ./target/release/scan_demo --cli    # CLI模式"
            echo "  ./target/release/scan_demo          # Web模式"
            echo "  nohup ./target/release/scan_demo > scan_demo.log 2>&1 &  # 后台运行"
        fi
    else
        echo "❌ 未找到编译好的二进制文件"
        echo "请先运行编译: cargo build --release"
    fi
fi

echo ""
echo "=== 网络访问诊断 ==="
echo "如果树莓派本地可以访问，但PC无法访问，请检查："
echo ""

# 检查应用监听地址
echo "1. 检查应用监听地址："
if netstat -tlnp 2>/dev/null | grep ":3000 " | grep -q "0.0.0.0"; then
    echo "✅ 应用监听所有网络接口 (0.0.0.0:3000)"
elif netstat -tlnp 2>/dev/null | grep ":3000 " | grep -q "127.0.0.1"; then
    echo "❌ 应用只监听本地接口 (127.0.0.1:3000)"
    echo "   这是问题所在！应用需要监听 0.0.0.0:3000"
    echo "   解决方案：修改应用配置或重新编译"
else
    echo "⚠️  监听地址未知，详细信息："
    netstat -tlnp | grep ":3000 "
fi

echo ""
echo "2. 网络连接测试："
echo "   在PC上运行以下命令测试连接："
echo "   ping $PI_IP"
echo "   telnet $PI_IP 3000"
echo "   curl http://$PI_IP:3000"

echo ""
echo "3. 路由器设置检查："
echo "   - 确认PC和树莓派在同一网段"
echo "   - 检查路由器AP隔离是否开启"
echo "   - 确认防火墙规则正确"

echo ""
echo "4. 树莓派网络配置："
echo "   当前网络接口："
ip addr show | grep -E "inet [0-9]" | grep -v "127.0.0.1" | while read line; do
    IP=$(echo $line | awk '{print $2}' | cut -d'/' -f1)
    INTERFACE=$(echo $line | awk '{print $NF}')
    echo "   - $INTERFACE: $IP"
done

echo ""
echo "5. 端口转发测试："
echo "   在树莓派上测试外部访问："
echo "   curl -I http://$PI_IP:3000"
echo "   如果返回HTTP状态码，说明端口可访问"

echo ""
echo "=== 解决方案 ==="
echo "如果应用只监听127.0.0.1，需要修改为0.0.0.0："
echo "1. 检查应用配置文件"
echo "2. 修改监听地址为0.0.0.0:3000"
echo "3. 重启应用"
echo ""
echo "如果网络连接正常但无法访问："
echo "1. 检查路由器AP隔离设置"
echo "2. 尝试使用树莓派热点"
echo "3. 检查PC防火墙设置"
