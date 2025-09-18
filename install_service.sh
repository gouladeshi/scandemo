#!/bin/bash

# Linux 5.15 系统服务安装脚本
echo "=== 安装 Scan Demo 系统服务 ==="

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 此脚本需要 root 权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 设置安装路径
INSTALL_DIR="/opt/scan-demo"
SERVICE_USER="scanuser"
SERVICE_GROUP="scanuser"

echo "安装路径: $INSTALL_DIR"
echo "服务用户: $SERVICE_USER"

# 创建服务用户
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "创建服务用户: $SERVICE_USER"
    useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
else
    echo "服务用户已存在: $SERVICE_USER"
fi

# 创建安装目录
echo "创建安装目录: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"

# 复制文件
echo "复制应用程序文件..."
cp -r . "$INSTALL_DIR/"
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"

# 设置权限
chmod +x "$INSTALL_DIR/target/release/scan_demo"
chmod +x "$INSTALL_DIR/qt_frontend/build/bin/ScanDemoFrontend"

# 安装系统服务
echo "安装系统服务..."
cp scan-demo-qt.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable scan-demo-qt.service

echo ""
echo "✅ 系统服务安装完成！"
echo ""
echo "服务管理命令："
echo "启动服务: sudo systemctl start scan-demo-qt"
echo "停止服务: sudo systemctl stop scan-demo-qt"
echo "重启服务: sudo systemctl restart scan-demo-qt"
echo "查看状态: sudo systemctl status scan-demo-qt"
echo "查看日志: sudo journalctl -u scan-demo-qt -f"
echo ""
echo "开机自启: sudo systemctl enable scan-demo-qt"
echo "禁用自启: sudo systemctl disable scan-demo-qt"
echo ""
echo "启动服务..."
sudo systemctl start scan-demo-qt
sudo systemctl status scan-demo-qt

echo ""
echo "服务已启动，可以通过以下方式访问："
echo "- 本地: http://localhost:3000"
echo "- 网络: http://$(hostname -I | awk '{print $1}'):3000"
