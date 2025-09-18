#!/bin/bash

echo "============================================"
echo "🔍 脚本诊断工具"
echo "============================================"

# 检查当前目录
echo "当前目录: $(pwd)"
echo ""

# 检查文件是否存在
if [ -f "build_linux_final.sh" ]; then
    echo "✅ build_linux_final.sh 文件存在"
else
    echo "❌ build_linux_final.sh 文件不存在"
    exit 1
fi

# 检查文件权限
echo "文件权限: $(ls -la build_linux_final.sh)"
echo ""

# 检查文件类型
echo "文件类型: $(file build_linux_final.sh)"
echo ""

# 检查文件编码
echo "文件编码检查:"
hexdump -C build_linux_final.sh | head -5
echo ""

# 检查换行符类型
echo "换行符检查:"
if grep -q $'\r' build_linux_final.sh; then
    echo "❌ 文件包含CR字符"
else
    echo "✅ 文件不包含CR字符"
fi

# 检查shebang
echo "Shebang检查:"
head -1 build_linux_final.sh
echo ""

# 尝试设置权限
echo "设置执行权限..."
chmod +x build_linux_final.sh

# 检查权限是否设置成功
echo "权限设置后: $(ls -la build_linux_final.sh)"
echo ""

echo "============================================"
echo "📋 解决方案"
echo "============================================"

echo "如果仍然无法运行，请尝试以下方法："
echo ""
echo "1. 检查文件路径:"
echo "   pwd"
echo "   ls -la build_linux_final.sh"
echo ""
echo "2. 使用完整路径运行:"
echo "   /full/path/to/build_linux_final.sh"
echo ""
echo "3. 使用bash直接运行:"
echo "   bash build_linux_final.sh"
echo ""
echo "4. 检查文件格式:"
echo "   file build_linux_final.sh"
echo "   hexdump -C build_linux_final.sh | head -5"
echo ""
echo "5. 转换文件格式:"
echo "   dos2unix build_linux_final.sh"
echo ""
echo "============================================"
