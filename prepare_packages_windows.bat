@echo off
REM Windows 版本预下载包脚本
echo === Windows 预下载包脚本 ===

REM 创建包目录
if not exist packages mkdir packages
if not exist packages\windows mkdir packages\windows
if not exist packages\rust mkdir packages\rust

echo 开始预下载包...

REM 1. 预下载 Rust 工具链
echo 1. 预下载 Rust 工具链...
if not exist packages\rust\rustup-init.exe (
    echo 下载 rustup 安装程序...
    powershell -Command "Invoke-WebRequest -Uri 'https://win.rustup.rs/x86_64' -OutFile 'packages\rust\rustup-init.exe'"
    if %errorLevel% == 0 (
        echo ✅ rustup 安装程序下载成功
    ) else (
        echo ❌ rustup 安装程序下载失败
    )
) else (
    echo ✅ rustup 安装程序已存在
)

REM 2. 预下载 Git
echo 2. 预下载 Git...
if not exist packages\windows\Git-installer.exe (
    echo 下载 Git 安装程序...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/latest/download/Git-2.42.0.2-64-bit.exe' -OutFile 'packages\windows\Git-installer.exe'"
    if %errorLevel% == 0 (
        echo ✅ Git 安装程序下载成功
    ) else (
        echo ❌ Git 安装程序下载失败
    )
) else (
    echo ✅ Git 安装程序已存在
)

REM 3. 预下载 CMake
echo 3. 预下载 CMake...
if not exist packages\windows\cmake-installer.exe (
    echo 下载 CMake 安装程序...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-windows-x86_64.msi' -OutFile 'packages\windows\cmake-installer.msi'"
    if %errorLevel% == 0 (
        echo ✅ CMake 安装程序下载成功
    ) else (
        echo ❌ CMake 安装程序下载失败
    )
) else (
    echo ✅ CMake 安装程序已存在
)

REM 4. 预下载 Visual Studio Build Tools
echo 4. 预下载 Visual Studio Build Tools...
if not exist packages\windows\vs_buildtools.exe (
    echo 下载 Visual Studio Build Tools...
    powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile 'packages\windows\vs_buildtools.exe'"
    if %errorLevel% == 0 (
        echo ✅ Visual Studio Build Tools 下载成功
    ) else (
        echo ❌ Visual Studio Build Tools 下载失败
    )
) else (
    echo ✅ Visual Studio Build Tools 已存在
)

REM 5. 预下载 Qt5
echo 5. 预下载 Qt5...
if not exist packages\windows\qt-installer.exe (
    echo 下载 Qt5 安装程序...
    powershell -Command "Invoke-WebRequest -Uri 'https://download.qt.io/official_releases/online_installers/qt-unified-windows-x64-online.exe' -OutFile 'packages\windows\qt-installer.exe'"
    if %errorLevel% == 0 (
        echo ✅ Qt5 安装程序下载成功
    ) else (
        echo ❌ Qt5 安装程序下载失败
    )
) else (
    echo ✅ Qt5 安装程序已存在
)

REM 6. 创建安装脚本
echo 6. 创建安装脚本...
echo @echo off > packages\windows\install.bat
echo echo 安装预下载的 Windows 包... >> packages\windows\install.bat
echo echo. >> packages\windows\install.bat
echo echo 1. 安装 Git... >> packages\windows\install.bat
echo Git-installer.exe /SILENT >> packages\windows\install.bat
echo echo. >> packages\windows\install.bat
echo echo 2. 安装 CMake... >> packages\windows\install.bat
echo msiexec /i cmake-installer.msi /quiet >> packages\windows\install.bat
echo echo. >> packages\windows\install.bat
echo echo 3. 安装 Visual Studio Build Tools... >> packages\windows\install.bat
echo vs_buildtools.exe --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools >> packages\windows\install.bat
echo echo. >> packages\windows\install.bat
echo echo 4. 安装 Qt5 (需要手动操作)... >> packages\windows\install.bat
echo echo 请手动运行 qt-installer.exe 并安装 Qt5 >> packages\windows\install.bat
echo echo. >> packages\windows\install.bat
echo echo 5. 安装 Rust... >> packages\windows\install.bat
echo ..\rust\rustup-init.exe -y >> packages\windows\install.bat
echo echo. >> packages\windows\install.bat
echo echo ✅ 所有包安装完成！ >> packages\windows\install.bat
echo echo 请重启命令提示符或重新登录以更新环境变量 >> packages\windows\install.bat
echo pause >> packages\windows\install.bat

REM 7. 创建 Rust 安装脚本
echo 7. 创建 Rust 安装脚本...
echo @echo off > packages\rust\install.bat
echo echo 安装 Rust... >> packages\rust\install.bat
echo rustup-init.exe -y >> packages\rust\install.bat
echo echo ✅ Rust 安装完成！ >> packages\rust\install.bat
echo echo 请重启命令提示符以更新环境变量 >> packages\rust\install.bat
echo pause >> packages\rust\install.bat

REM 8. 创建包清单
echo 8. 创建包清单...
echo # Windows 预下载包清单 > packages\README.md
echo. >> packages\README.md
echo 生成时间: %date% %time% >> packages\README.md
echo. >> packages\README.md
echo ## 包含的包 >> packages\README.md
echo. >> packages\README.md
echo ### Windows 包 >> packages\README.md
echo - Git 安装程序 >> packages\README.md
echo - CMake 安装程序 >> packages\README.md
echo - Visual Studio Build Tools >> packages\README.md
echo - Qt5 安装程序 >> packages\README.md
echo. >> packages\README.md
echo ### Rust 工具链 >> packages\README.md
echo - rustup-init.exe >> packages\README.md
echo. >> packages\README.md
echo ## 使用方法 >> packages\README.md
echo. >> packages\README.md
echo 1. 运行 packages\windows\install.bat 安装系统包 >> packages\README.md
echo 2. 运行 packages\rust\install.bat 安装 Rust >> packages\README.md
echo 3. 重启命令提示符 >> packages\README.md
echo 4. 编译项目 >> packages\README.md

REM 9. 创建完整项目包
echo 9. 创建完整项目包...
set PACKAGE_NAME=scan-demo-windows-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set PACKAGE_NAME=%PACKAGE_NAME: =0%

if not exist packages\%PACKAGE_NAME% mkdir packages\%PACKAGE_NAME%

echo 复制项目文件...
xcopy /E /I /Y src packages\%PACKAGE_NAME%\src
xcopy /E /I /Y qt_frontend packages\%PACKAGE_NAME%\qt_frontend
copy Cargo.toml packages\%PACKAGE_NAME%\
copy Cargo.lock packages\%PACKAGE_NAME%\
copy *.bat packages\%PACKAGE_NAME%\
copy *.md packages\%PACKAGE_NAME%\
if exist .env copy .env packages\%PACKAGE_NAME%\

echo 复制预下载的包...
xcopy /E /I /Y packages\windows packages\%PACKAGE_NAME%\packages\windows
xcopy /E /I /Y packages\rust packages\%PACKAGE_NAME%\packages\rust

REM 创建 Windows 安装脚本
echo 创建 Windows 安装脚本...
echo @echo off > packages\%PACKAGE_NAME%\install_windows.bat
echo echo === 安装 Scan Demo Windows 版本 === >> packages\%PACKAGE_NAME%\install_windows.bat
echo. >> packages\%PACKAGE_NAME%\install_windows.bat
echo echo 1. 安装系统依赖... >> packages\%PACKAGE_NAME%\install_windows.bat
echo cd packages\windows >> packages\%PACKAGE_NAME%\install_windows.bat
echo call install.bat >> packages\%PACKAGE_NAME%\install_windows.bat
echo cd ..\.. >> packages\%PACKAGE_NAME%\install_windows.bat
echo. >> packages\%PACKAGE_NAME%\install_windows.bat
echo echo 2. 安装 Rust... >> packages\%PACKAGE_NAME%\install_windows.bat
echo cd packages\rust >> packages\%PACKAGE_NAME%\install_windows.bat
echo call install.bat >> packages\%PACKAGE_NAME%\install_windows.bat
echo cd ..\.. >> packages\%PACKAGE_NAME%\install_windows.bat
echo. >> packages\%PACKAGE_NAME%\install_windows.bat
echo echo 3. 编译项目... >> packages\%PACKAGE_NAME%\install_windows.bat
echo call cargo build --release >> packages\%PACKAGE_NAME%\install_windows.bat
echo. >> packages\%PACKAGE_NAME%\install_windows.bat
echo echo 4. 编译 Qt5 前端... >> packages\%PACKAGE_NAME%\install_windows.bat
echo cd qt_frontend >> packages\%PACKAGE_NAME%\install_windows.bat
echo if not exist build mkdir build >> packages\%PACKAGE_NAME%\install_windows.bat
echo cd build >> packages\%PACKAGE_NAME%\install_windows.bat
echo cmake .. -G "Visual Studio 16 2019" -A x64 >> packages\%PACKAGE_NAME%\install_windows.bat
echo cmake --build . --config Release >> packages\%PACKAGE_NAME%\install_windows.bat
echo cd ..\.. >> packages\%PACKAGE_NAME%\install_windows.bat
echo. >> packages\%PACKAGE_NAME%\install_windows.bat
echo echo ✅ 安装完成！ >> packages\%PACKAGE_NAME%\install_windows.bat
echo echo 启动命令: start_windows.bat >> packages\%PACKAGE_NAME%\install_windows.bat
echo pause >> packages\%PACKAGE_NAME%\install_windows.bat

REM 创建启动脚本
echo 创建启动脚本...
echo @echo off > packages\%PACKAGE_NAME%\start_windows.bat
echo echo 启动 Scan Demo... >> packages\%PACKAGE_NAME%\start_windows.bat
echo start /B target\release\scan_demo.exe >> packages\%PACKAGE_NAME%\start_windows.bat
echo timeout /t 3 /nobreak ^>nul >> packages\%PACKAGE_NAME%\start_windows.bat
echo start qt_frontend\build\Release\ScanDemoFrontend.exe >> packages\%PACKAGE_NAME%\start_windows.bat
echo pause >> packages\%PACKAGE_NAME%\start_windows.bat

echo.
echo ✅ Windows 包准备完成！
echo.
echo 包目录结构:
dir packages /B
echo.
echo 完整项目包: packages\%PACKAGE_NAME%
echo.
echo 使用方法:
echo 1. 将 packages\%PACKAGE_NAME% 复制到目标机器
echo 2. 运行 install_windows.bat 安装
echo 3. 运行 start_windows.bat 启动
echo.
echo 包大小:
for /f %%i in ('dir packages\%PACKAGE_NAME% /s /-c ^| find "个文件"') do echo %%i
echo.
pause
