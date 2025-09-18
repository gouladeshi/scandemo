@echo off
REM Windows 部署脚本
echo === Windows 部署脚本 ===

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% == 0 (
    echo 检测到管理员权限
) else (
    echo 警告: 建议以管理员身份运行此脚本
    pause
)

REM 检查系统信息
echo 系统信息:
echo OS: %OS%
echo 架构: %PROCESSOR_ARCHITECTURE%
echo 用户: %USERNAME%

REM 检查必要的工具
echo.
echo 检查必要工具...

REM 检查 Chocolatey
where choco >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Chocolatey 已安装
) else (
    echo ❌ Chocolatey 未安装，正在安装...
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorLevel% == 0 (
        echo ✅ Chocolatey 安装成功
    ) else (
        echo ❌ Chocolatey 安装失败
        pause
        exit /b 1
    )
)

REM 安装必要软件
echo.
echo 安装必要软件...

REM 安装 Git
choco install git -y
if %errorLevel% == 0 (
    echo ✅ Git 安装成功
) else (
    echo ❌ Git 安装失败
)

REM 安装 Rust
where cargo >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Rust 已安装
) else (
    echo 安装 Rust...
    choco install rust -y
    if %errorLevel% == 0 (
        echo ✅ Rust 安装成功
        call refreshenv
    ) else (
        echo ❌ Rust 安装失败
        pause
        exit /b 1
    )
)

REM 安装 CMake
where cmake >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ CMake 已安装
) else (
    echo 安装 CMake...
    choco install cmake -y
    if %errorLevel% == 0 (
        echo ✅ CMake 安装成功
        call refreshenv
    ) else (
        echo ❌ CMake 安装失败
    )
)

REM 安装 Qt5
where qmake >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Qt5 已安装
) else (
    echo 安装 Qt5...
    choco install qt5 -y
    if %errorLevel% == 0 (
        echo ✅ Qt5 安装成功
        call refreshenv
    ) else (
        echo ❌ Qt5 安装失败
    )
)

REM 安装 Visual Studio Build Tools
echo 检查 Visual Studio Build Tools...
where cl >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Visual Studio Build Tools 已安装
) else (
    echo 安装 Visual Studio Build Tools...
    choco install visualstudio2022buildtools -y
    if %errorLevel% == 0 (
        echo ✅ Visual Studio Build Tools 安装成功
        call refreshenv
    ) else (
        echo ❌ Visual Studio Build Tools 安装失败
    )
)

REM 编译 Rust 后端
echo.
echo 编译 Rust 后端...
call cargo build --release
if %errorLevel% == 0 (
    echo ✅ Rust 后端编译成功
) else (
    echo ❌ Rust 后端编译失败
    pause
    exit /b 1
)

REM 编译 Qt5 前端
echo.
echo 编译 Qt5 前端...
if exist qt_frontend (
    cd qt_frontend
    if not exist build mkdir build
    cd build
    
    REM 设置 Qt5 路径
    set "CMAKE_PREFIX_PATH=C:\Qt\5.15.2\msvc2019_64"
    
    cmake .. -G "Visual Studio 16 2019" -A x64
    if %errorLevel% == 0 (
        cmake --build . --config Release
        if %errorLevel% == 0 (
            echo ✅ Qt5 前端编译成功
        ) else (
            echo ❌ Qt5 前端编译失败
        )
    ) else (
        echo ❌ CMake 配置失败
    )
    
    cd ..\..
) else (
    echo ❌ 未找到 qt_frontend 目录
)

REM 创建配置文件
if not exist .env (
    echo 创建配置文件...
    echo DATABASE_URL=sqlite:scan_demo.db > .env
    echo EXTERNAL_API_URL=https://httpbin.org/post >> .env
    echo RUST_LOG=info,sqlx=warn >> .env
)

REM 创建启动脚本
echo 创建启动脚本...
echo @echo off > start_windows.bat
echo echo 启动 Scan Demo... >> start_windows.bat
echo start /B target\release\scan_demo.exe >> start_windows.bat
echo timeout /t 3 /nobreak ^>nul >> start_windows.bat
echo start qt_frontend\build\Release\ScanDemoFrontend.exe >> start_windows.bat
echo pause >> start_windows.bat

REM 获取本机IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set "LOCAL_IP=%%b"
        goto :ip_found
    )
)
:ip_found

echo.
echo 🎉 Windows 部署完成！
echo.
echo 系统信息:
echo - OS: %OS%
echo - 架构: %PROCESSOR_ARCHITECTURE%
echo - 本机IP: %LOCAL_IP%
echo.
echo 启动方式:
echo 1. 双击 start_windows.bat
echo 2. 或手动启动:
echo    target\release\scan_demo.exe
echo    qt_frontend\build\Release\ScanDemoFrontend.exe
echo.
echo 访问地址:
echo - 本地: http://localhost:3000
echo - 网络: http://%LOCAL_IP%:3000
echo.
echo 日志查看:
echo - 后端日志: 查看控制台输出
echo - 系统日志: 事件查看器
echo.
echo ✅ 部署完成，可以开始使用了！
pause
