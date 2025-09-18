#!/bin/bash

# 创建包含所有依赖的完整项目包
echo "=== 创建包含所有依赖的完整项目包 ==="

PACKAGE_NAME="scan-demo-with-deps-$(date +%Y%m%d-%H%M%S)"
PACKAGE_DIR="packages/$PACKAGE_NAME"

echo "创建完整包: $PACKAGE_NAME"
mkdir -p "$PACKAGE_DIR"

# 1. 复制项目文件
echo "1. 复制项目文件..."
cp -r src "$PACKAGE_DIR/"
cp -r qt_frontend "$PACKAGE_DIR/"
cp Cargo.toml Cargo.lock "$PACKAGE_DIR/"
cp *.sh "$PACKAGE_DIR/"
cp *.md "$PACKAGE_DIR/"
cp .env* "$PACKAGE_DIR/" 2>/dev/null || true

# 2. 复制预下载的包
echo "2. 复制预下载的包..."
if [ -d "packages" ]; then
    cp -r packages "$PACKAGE_DIR/"
else
    echo "⚠️  未找到预下载的包，请先运行 prepare_packages.sh"
fi

# 3. 创建安装脚本
echo "3. 创建安装脚本..."
cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash
echo "=== 安装 Scan Demo (包含预下载包) ==="

# 检查系统
echo "系统信息："
echo "OS: $(uname -s)"
echo "Arch: $(uname -m)"
echo "Kernel: $(uname -r)"

# 检查是否有预下载的包
if [ -d "packages" ]; then
    echo "发现预下载的包，开始安装..."
    
    # 安装系统包
    if [ -f "install_packages.sh" ]; then
        chmod +x install_packages.sh
        ./install_packages.sh
    else
        echo "❌ 未找到 install_packages.sh"
        exit 1
    fi
else
    echo "❌ 未找到预下载的包"
    echo "请使用在线部署脚本: ./deploy_linux.sh"
    exit 1
fi

# 设置 Rust 环境
echo "设置 Rust 环境..."
if [ -d "$HOME/.cargo" ]; then
    echo "✅ Rust 已安装"
    export PATH="$HOME/.cargo/bin:$PATH"
else
    echo "❌ Rust 未安装，请检查安装过程"
    exit 1
fi

# 编译项目
echo "编译项目..."
export PATH="$HOME/.cargo/bin:$PATH"
export CARGO_BUILD_JOBS=$(nproc)

# 设置 OpenSSL 环境变量
export OPENSSL_STATIC=0
export OPENSSL_DIR=/usr
export OPENSSL_INCLUDE_DIR=/usr/include/openssl

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        export OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu
        ;;
    aarch64)
        export OPENSSL_LIB_DIR=/usr/lib/aarch64-linux-gnu
        ;;
    *)
        export OPENSSL_LIB_DIR=/usr/lib
        ;;
esac

# 编译 Rust 后端
echo "编译 Rust 后端..."
if cargo build --release; then
    echo "✅ Rust 后端编译成功"
else
    echo "❌ Rust 后端编译失败"
    exit 1
fi

# 编译 QT5 前端
echo "编译 QT5 前端..."
if [ -d "qt_frontend" ]; then
    cd qt_frontend
    mkdir -p build
    cd build
    
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    
    if [ -f "bin/ScanDemoFrontend" ]; then
        chmod +x bin/ScanDemoFrontend
        echo "✅ QT5 前端编译成功"
    else
        echo "❌ QT5 前端编译失败"
        exit 1
    fi
    
    cd ../..
else
    echo "❌ 未找到 qt_frontend 目录"
    exit 1
fi

# 创建配置文件
if [ ! -f .env ]; then
    echo "创建配置文件..."
    cat > .env << 'ENVEOF'
DATABASE_URL=sqlite:scan_demo.db
EXTERNAL_API_URL=https://httpbin.org/post
RUST_LOG=info,sqlx=warn
ENVEOF
fi

# 创建启动脚本
echo "创建启动脚本..."
cat > start.sh << 'STARTEOF'
#!/bin/bash
echo "启动 Scan Demo..."

# 设置环境变量
export PATH="$HOME/.cargo/bin:$PATH"

# 启动后端
echo "启动 Rust 后端..."
nohup ./target/release/scan_demo > scan_demo.log 2>&1 &
BACKEND_PID=$!
echo "后端进程ID: $BACKEND_PID"

# 等待后端启动
sleep 3

# 启动前端
echo "启动 QT5 前端..."
./qt_frontend/build/bin/ScanDemoFrontend

# 前端退出时停止后端
echo "前端已退出，停止后端..."
kill $BACKEND_PID
STARTEOF

chmod +x start.sh

echo ""
echo "🎉 安装完成！"
echo ""
echo "启动命令: ./start.sh"
echo "访问地址: http://localhost:3000"
EOF

chmod +x "$PACKAGE_DIR/install.sh"

# 4. 创建 README
echo "4. 创建 README..."
cat > "$PACKAGE_DIR/README.md" << EOF
# Scan Demo - 包含预下载依赖的完整包

## 包信息
- 创建时间: $(date)
- 包含内容: 完整应用 + 所有系统依赖包
- 系统要求: Linux x86_64

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
   ./start.sh
   \`\`\`

## 访问地址
- 本地: http://localhost:3000
- 网络: http://服务器IP:3000

## 文件说明
- \`install.sh\`: 主安装脚本
- \`start.sh\`: 启动脚本
- \`packages/\`: 预下载的系统包
- \`src/\`: Rust 后端源码
- \`qt_frontend/\`: QT5 前端源码

## 预下载的包
EOF

# 添加包信息到 README
if [ -d "$PACKAGE_DIR/packages" ]; then
    echo "### 系统包" >> "$PACKAGE_DIR/README.md"
    find "$PACKAGE_DIR/packages" -name "*.deb" -o -name "*.rpm" | head -10 >> "$PACKAGE_DIR/README.md"
    echo "" >> "$PACKAGE_DIR/README.md"
    echo "### 包大小" >> "$PACKAGE_DIR/README.md"
    du -sh "$PACKAGE_DIR/packages"/* >> "$PACKAGE_DIR/README.md" 2>/dev/null || echo "无法统计包大小" >> "$PACKAGE_DIR/README.md"
fi

# 5. 创建压缩包
echo "5. 创建压缩包..."
cd packages
tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"
cd - > /dev/null

# 6. 显示包信息
echo ""
echo "✅ 完整包创建完成！"
echo ""
echo "包信息："
echo "- 包名: $PACKAGE_NAME"
echo "- 位置: packages/$PACKAGE_NAME.tar.gz"
echo "- 大小: $(du -h packages/$PACKAGE_NAME.tar.gz | cut -f1)"
echo ""
echo "包内容："
echo "- 完整应用源码"
echo "- 预下载的系统包"
echo "- 安装脚本"
echo "- 使用说明"
echo ""
echo "使用方法："
echo "1. 将 $PACKAGE_NAME.tar.gz 复制到目标机器"
echo "2. 解压: tar -xzf $PACKAGE_NAME.tar.gz"
echo "3. 安装: cd $PACKAGE_NAME && ./install.sh"
echo "4. 启动: ./start.sh"
echo ""
echo "优势："
echo "- ✅ 无需网络连接"
echo "- ✅ 包含所有依赖"
echo "- ✅ 一键安装部署"
echo "- ✅ 适合离线环境"
