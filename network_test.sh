#!/bin/bash

# 网络连接诊断脚本
echo "=== 网络连接诊断脚本 ==="

# 获取树莓派IP
PI_IP=$(hostname -I | awk '{print $1}')
echo "树莓派IP地址: $PI_IP"

# 检查应用监听状态
echo ""
echo "=== 应用监听状态 ==="
if netstat -tlnp 2>/dev/null | grep ":3000 " | grep -q "0.0.0.0"; then
    echo "✅ 应用正确监听 0.0.0.0:3000"
    netstat -tlnp | grep ":3000 "
else
    echo "❌ 应用监听配置有问题"
    netstat -tlnp | grep ":3000 " || echo "端口3000未监听"
fi

# 检查防火墙
echo ""
echo "=== 防火墙状态 ==="
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | grep "Status:" | awk '{print $2}')
    echo "UFW状态: $UFW_STATUS"
    if [ "$UFW_STATUS" = "active" ]; then
        if sudo ufw status | grep -q "3000"; then
            echo "✅ 端口3000已开放"
        else
            echo "❌ 端口3000未开放"
            echo "运行: sudo ufw allow 3000"
        fi
    fi
else
    echo "UFW未安装"
fi

# 检查网络接口
echo ""
echo "=== 网络接口信息 ==="
ip addr show | grep -E "inet [0-9]" | grep -v "127.0.0.1" | while read line; do
    IP=$(echo $line | awk '{print $2}' | cut -d'/' -f1)
    INTERFACE=$(echo $line | awk '{print $NF}')
    echo "接口: $INTERFACE, IP: $IP"
done

# 检查路由表
echo ""
echo "=== 路由表 ==="
ip route | head -5

# 测试本地连接
echo ""
echo "=== 本地连接测试 ==="
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null | grep -q "200"; then
    echo "✅ 本地连接正常"
else
    echo "❌ 本地连接失败"
fi

# 测试外部连接
echo ""
echo "=== 外部连接测试 ==="
if curl -s -o /dev/null -w "%{http_code}" http://$PI_IP:3000 2>/dev/null | grep -q "200"; then
    echo "✅ 外部连接正常"
else
    echo "❌ 外部连接失败"
fi

# 生成PC端测试命令
echo ""
echo "=== PC端测试命令 ==="
echo "在PC上运行以下命令测试连接："
echo ""
echo "1. 测试网络连通性："
echo "   ping $PI_IP"
echo ""
echo "2. 测试端口连接："
echo "   telnet $PI_IP 3000"
echo "   或"
echo "   nc -zv $PI_IP 3000"
echo ""
echo "3. 测试HTTP访问："
echo "   curl http://$PI_IP:3000"
echo ""
echo "4. 浏览器访问："
echo "   http://$PI_IP:3000"
echo ""

# 常见问题解决
echo "=== 常见问题解决 ==="
echo "如果PC无法访问，请检查："
echo ""
echo "1. 路由器AP隔离设置："
echo "   - 登录路由器管理界面"
echo "   - 查找 'AP隔离' 或 '客户端隔离' 设置"
echo "   - 关闭该功能"
echo ""
echo "2. 网络段检查："
echo "   - 确认PC和树莓派在同一网段"
echo "   - 例如：192.168.1.x 或 192.168.0.x"
echo ""
echo "3. PC防火墙："
echo "   - 检查Windows防火墙设置"
echo "   - 临时关闭防火墙测试"
echo ""
echo "4. 尝试树莓派热点："
echo "   - 在树莓派上创建热点"
echo "   - PC连接树莓派热点"
echo "   - 测试访问"
echo ""

# 提供快速解决方案
echo "=== 快速解决方案 ==="
echo "如果以上都正常但仍无法访问，尝试："
echo ""
echo "1. 重启网络服务："
echo "   sudo systemctl restart networking"
echo ""
echo "2. 重启应用："
echo "   pkill -f scan_demo"
echo "   ./target/release/scan_demo"
echo ""
echo "3. 使用不同端口："
echo "   - 修改应用监听端口"
echo "   - 或使用端口转发"

