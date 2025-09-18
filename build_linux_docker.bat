@echo off
chcp 65001 >nul
echo === 使用Docker编译Linux可执行文件 ===

REM 检查Docker是否安装
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker未安装，请先安装Docker Desktop
    pause
    exit /b 1
)

echo ✅ Docker环境检查通过

REM 创建临时Dockerfile用于编译
(
echo FROM rust:1.89
echo.
echo # 设置工作目录
echo WORKDIR /app
echo.
echo # 安装必要的系统依赖
echo RUN apt-get update ^&^& apt-get install -y \
echo     libsqlite3-dev \
echo     pkg-config \
echo     libssl-dev \
echo     ^&^& rm -rf /var/lib/apt/lists/*
echo.
echo # 复制项目文件
echo COPY Cargo.toml Cargo.lock ./
echo COPY src ./src
echo.
echo # 编译Release版本
echo RUN cargo build --release
echo.
echo # 复制编译好的可执行文件到输出目录
echo RUN mkdir -p /output
echo RUN cp target/release/scan_demo /output/
) > Dockerfile.build

echo 构建Docker镜像...
docker build -f Dockerfile.build -t scan-demo-builder .

if errorlevel 1 (
    echo ❌ Docker镜像构建失败
    del Dockerfile.build
    pause
    exit /b 1
)

echo ✅ Docker镜像构建成功

REM 从容器中复制可执行文件
echo 提取Linux可执行文件...
docker create --name temp-container scan-demo-builder
docker cp temp-container:/output/scan_demo ./scan_demo_linux
docker rm temp-container

REM 显示文件信息
echo ✅ Linux可执行文件编译成功！
echo 文件位置: ./scan_demo_linux
for %%A in (scan_demo_linux) do echo 文件大小: %%~zA bytes

REM 清理临时文件
del Dockerfile.build

echo.
echo 使用方法：
echo 1. 将 scan_demo_linux 传输到Linux服务器
echo 2. 在Linux服务器上设置执行权限: chmod +x scan_demo_linux
echo 3. 运行: ./scan_demo_linux
echo 4. 或者CLI模式: ./scan_demo_linux --cli
echo.
pause
