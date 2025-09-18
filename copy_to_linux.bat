@echo off
REM ============================================
REM 准备复制到Linux的文件清单
REM ============================================

echo ============================================
echo 📋 准备复制到Linux的文件
echo ============================================

REM 创建临时目录
set TEMP_DIR=linux_copy_temp
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

echo 复制必需文件...

REM 复制项目配置文件
copy "Cargo.toml" "%TEMP_DIR%\"
copy "Cargo.lock" "%TEMP_DIR%\"

REM 复制源代码目录
xcopy "src" "%TEMP_DIR%\src\" /E /I

REM 复制Qt前端目录
xcopy "qt_frontend" "%TEMP_DIR%\qt_frontend\" /E /I

REM 复制编译脚本
copy "build_linux_simple.sh" "%TEMP_DIR%\"

REM 复制静态文件（如果存在）
if exist "static" xcopy "static" "%TEMP_DIR%\static\" /E /I

REM 复制模板文件（如果存在）
if exist "templates" xcopy "templates" "%TEMP_DIR%\templates\" /E /I

REM 复制SQL文件（如果存在）
if exist "sql" xcopy "sql" "%TEMP_DIR%\sql\" /E /I

REM 复制README文件
if exist "README.md" copy "README.md" "%TEMP_DIR%\"

echo.
echo ============================================
echo ✅ 文件准备完成
echo ============================================
echo.
echo 📁 准备复制的文件在目录: %TEMP_DIR%
echo.
echo 📋 文件清单:
dir /b "%TEMP_DIR%"
echo.
echo 📊 目录大小:
for /f "tokens=3" %%a in ('dir "%TEMP_DIR%" /-c ^| find "个文件"') do echo 总计: %%a 字节
echo.
echo 🚀 下一步操作:
echo 1. 将 %TEMP_DIR% 目录复制到Linux系统
echo 2. 在Linux上运行: chmod +x build_linux_simple.sh
echo 3. 在Linux上运行: ./build_linux_simple.sh
echo.
echo ============================================
pause
