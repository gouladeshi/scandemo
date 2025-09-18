#!/bin/bash

# 创建完整离线部署包脚本
echo "=== 创建完整离线部署包 ==="

PACKAGE_NAME="scan-demo-offline-$(date +%Y%m%d-%H%M%S)"
PACKAGE_DIR="packages/$PACKAGE_NAME"

echo "创建离线包: $PACKAGE_NAME"
mkdir -p "$PACKAGE_DIR"

# 1. 复制项目文件
echo "1. 复制项目文件..."
cp -r src "$PACKAGE_DIR/"
cp -r qt_frontend "$PACKAGE_DIR/"
cp Cargo.toml Cargo.lock "$PACKAGE_DIR/"
cp *.sh "$PACKAGE_DIR/"
cp *.md "$PACKAGE_DIR/"
cp .env* "$PACKAGE_DIR/" 2>/dev/null || true

# 2. 预下载依赖
echo "2. 预下载依赖..."
cd "$PACKAGE_DIR"
bash download_deps.sh
cd - > /dev/null

# 3. 创建安装脚本
echo "3. 创建安装脚本..."
cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash
echo "=== 离线安装 Scan Demo ==="

# 检查系统
echo "系统信息："
echo "OS: $(uname -s)"
echo "Arch: $(uname -m)"
echo "Kernel: $(uname -r)"

# 运行离线安装
if [ -f "offline_install.sh" ]; then
    chmod +x offline_install.sh
    ./offline_install.sh
else
    echo "❌ 未找到 offline_install.sh"
    exit 1
fi

echo ""
echo "🎉 安装完成！"
echo "启动命令: ./start_offline.sh"
EOF

chmod +x "$PACKAGE_DIR/install.sh"

# 4. 创建 README
echo "4. 创建 README..."
cat > "$PACKAGE_DIR/README_OFFLINE.md" << EOF
# Scan Demo 离线安装包

## 包信息
- 创建时间: $(date)
- 系统要求: Linux x86_64
- 包含内容: 完整应用 + 所有依赖

## 安装步骤

1. **解压包**
   \`\`\`bash
   tar -xzf $PACKAGE_NAME.tar.gz
   cd $PACKAGE_NAME
   \`\`\`

2. **运行安装**
   \`\`\`bash
   chmod +x install.sh
   ./install.sh
   \`\`\`

3. **启动应用**
   \`\`\`bash
   ./start_offline.sh
   \`\`\`

## 访问地址
- 本地: http://localhost:3000
- 网络: http://服务器IP:3000

## 文件说明
- \`install.sh\`: 主安装脚本
- \`offline_install.sh\`: 离线安装脚本
- \`start_offline.sh\`: 启动脚本
- \`deps/\`: 预下载的依赖文件
- \`src/\`: Rust 后端源码
- \`qt_frontend/\`: QT5 前端源码

## 故障排除
如果安装失败，请检查：
1. 系统权限
2. 磁盘空间
3. 系统兼容性

## 技术支持
如有问题，请查看日志文件或联系技术支持。
EOF

# 5. 创建压缩包
echo "5. 创建压缩包..."
cd packages
tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"
cd - > /dev/null

# 6. 显示包信息
echo ""
echo "✅ 离线包创建完成！"
echo ""
echo "包信息："
echo "- 包名: $PACKAGE_NAME"
echo "- 位置: packages/$PACKAGE_NAME.tar.gz"
echo "- 大小: $(du -h packages/$PACKAGE_NAME.tar.gz | cut -f1)"
echo ""
echo "包内容："
echo "- 完整应用源码"
echo "- 预下载的依赖"
echo "- 安装脚本"
echo "- 使用说明"
echo ""
echo "使用方法："
echo "1. 将 $PACKAGE_NAME.tar.gz 复制到目标机器"
echo "2. 解压: tar -xzf $PACKAGE_NAME.tar.gz"
echo "3. 安装: cd $PACKAGE_NAME && ./install.sh"
echo "4. 启动: ./start_offline.sh"
