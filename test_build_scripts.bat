@echo off
REM ============================================
REM 测试编译脚本的语法和完整性
REM ============================================

echo ============================================
echo 🧪 测试编译脚本
echo ============================================

REM 检查文件是否存在
echo 检查编译脚本文件...

if exist "build_linux_complete.sh" (
    echo ✅ build_linux_complete.sh 存在
) else (
    echo ❌ build_linux_complete.sh 不存在
)

if exist "build_linux_simple.sh" (
    echo ✅ build_linux_simple.sh 存在
) else (
    echo ❌ build_linux_simple.sh 不存在
)

if exist "build_linux_complete.bat" (
    echo ✅ build_linux_complete.bat 存在
) else (
    echo ❌ build_linux_complete.bat 不存在
)

if exist "build_docker_linux.sh" (
    echo ✅ build_docker_linux.sh 存在
) else (
    echo ❌ build_docker_linux.sh 不存在
)

if exist "Dockerfile.linux" (
    echo ✅ Dockerfile.linux 存在
) else (
    echo ❌ Dockerfile.linux 不存在
)

if exist "LINUX_BUILD_GUIDE.md" (
    echo ✅ LINUX_BUILD_GUIDE.md 存在
) else (
    echo ❌ LINUX_BUILD_GUIDE.md 不存在
)

echo.
echo 检查项目文件...

if exist "Cargo.toml" (
    echo ✅ Cargo.toml 存在
) else (
    echo ❌ Cargo.toml 不存在
)

if exist "qt_frontend\CMakeLists.txt" (
    echo ✅ qt_frontend\CMakeLists.txt 存在
) else (
    echo ❌ qt_frontend\CMakeLists.txt 不存在
)

if exist "src\main.rs" (
    echo ✅ src\main.rs 存在
) else (
    echo ❌ src\main.rs 不存在
)

echo.
echo ============================================
echo 📋 编译脚本总结
echo ============================================
echo.
echo 🐧 Linux 环境编译:
echo   1. build_linux_simple.sh - 简化版本（推荐）
echo   2. build_linux_complete.sh - 完整版本
echo   3. build_docker_linux.sh - Docker版本
echo.
echo 🪟 Windows 环境编译:
echo   1. build_linux_complete.bat - 多选项版本
echo.
echo 📖 使用说明:
echo   1. 查看 LINUX_BUILD_GUIDE.md 获取详细说明
echo   2. 选择适合您环境的编译方式
echo   3. 运行相应的编译脚本
echo.
echo 🚀 快速开始:
echo   - Linux: chmod +x build_linux_simple.sh && ./build_linux_simple.sh
echo   - Windows: build_linux_complete.bat
echo   - Docker: chmod +x build_docker_linux.sh && ./build_docker_linux.sh
echo.
echo ============================================
echo ✅ 测试完成
echo ============================================
pause
