@echo off
echo ============================================
echo 🔍 Windows脚本诊断工具
echo ============================================

echo 当前目录: %CD%
echo.

if exist "build_linux_final.sh" (
    echo ✅ build_linux_final.sh 文件存在
) else (
    echo ❌ build_linux_final.sh 文件不存在
    pause
    exit /b 1
)

echo 文件信息:
dir build_linux_final.sh
echo.

echo 文件大小: 
for %%A in (build_linux_final.sh) do echo %%~zA 字节
echo.

echo 检查文件内容前几行:
powershell -Command "Get-Content 'build_linux_final.sh' -Head 5"
echo.

echo 检查换行符类型:
powershell -Command "$content = Get-Content 'build_linux_final.sh' -Raw; if ($content -match \"`r`n\") { Write-Host '包含CRLF' } else { Write-Host '不包含CRLF' }"
echo.

echo ============================================
echo 📋 解决方案
echo ============================================
echo.
echo 如果Linux上仍然无法运行，请尝试：
echo.
echo 1. 在Linux上检查文件:
echo    ls -la build_linux_final.sh
echo    file build_linux_final.sh
echo.
echo 2. 使用bash直接运行:
echo    bash build_linux_final.sh
echo.
echo 3. 转换文件格式:
echo    dos2unix build_linux_final.sh
echo.
echo 4. 检查文件编码:
echo    hexdump -C build_linux_final.sh ^| head -5
echo.
echo 5. 使用完整路径:
echo    /full/path/to/build_linux_final.sh
echo.
echo ============================================
pause
