#!/bin/bash

# 扫码应用启动脚本
echo "=== 扫码应用启动脚本 ==="

# 检查二进制文件
if [ ! -f "./target/release/scan_demo" ]; then
    echo "❌ 未找到编译好的二进制文件"
    echo "请先运行: bash deploy_clean.sh"
    exit 1
fi

# 检查执行权限
if [ ! -x "./target/release/scan_demo" ]; then
    echo "添加执行权限..."
    chmod +x ./target/release/scan_demo
fi

# 停止现有进程
echo "检查现有进程..."
if pgrep -f "scan_demo" >/dev/null; then
    echo "发现现有进程，正在停止..."
    pkill -f scan_demo
    sleep 2
fi

# 检查端口占用
echo "检查端口3000..."
if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo "⚠️  端口3000被占用："
    netstat -tlnp | grep ":3000 "
    echo "请停止占用端口的程序或修改应用端口"
    exit 1
fi

# 检查配置文件
if [ ! -f ".env" ]; then
    echo "创建默认配置文件..."
    cat > .env << EOF
DATABASE_URL=sqlite:scan_demo.db
EXTERNAL_API_URL=https://httpbin.org/post
RUST_LOG=info,sqlx=warn
EOF
fi

# 获取IP地址
PI_IP=$(hostname -I | awk '{print $1}')
echo "树莓派IP地址: $PI_IP"

# 启动选项
echo ""
echo "选择启动模式："
echo "1) Web模式（推荐）- 可通过浏览器访问"
echo "2) CLI模式 - 命令行交互"
echo "3) 后台运行 - 后台服务模式"

read -p "请选择 (1-3): " choice

case $choice in
    1)
        echo "启动Web模式..."
        echo "应用将在 http://$PI_IP:3000 启动"
        echo "按 Ctrl+C 停止应用"
        echo ""
        ./target/release/scan_demo
        ;;
    2)
        echo "启动CLI模式..."
        ./target/release/scan_demo --cli
        ;;
    3)
        echo "启动后台模式..."
        nohup ./target/release/scan_demo > scan_demo.log 2>&1 &
        PID=$!
        echo "应用已在后台启动，PID: $PID"
        echo "日志文件: scan_demo.log"
        echo "访问地址: http://$PI_IP:3000"
        echo ""
        echo "管理命令："
        echo "  查看日志: tail -f scan_demo.log"
        echo "  停止应用: kill $PID"
        echo "  查看进程: ps aux | grep scan_demo"
        ;;
    *)
        echo "无效选择，使用Web模式启动..."
        ./target/release/scan_demo
        ;;
esac

