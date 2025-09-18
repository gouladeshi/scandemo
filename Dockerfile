# 多阶段构建 Dockerfile
FROM rust:1.70 as rust-builder

# 设置工作目录
WORKDIR /app

# 复制 Cargo 文件
COPY Cargo.toml Cargo.lock ./

# 创建虚拟 main.rs 以缓存依赖
RUN mkdir src && echo "fn main() {}" > src/main.rs

# 构建依赖（缓存层）
RUN cargo build --release && rm -rf src

# 复制源代码
COPY src ./src

# 构建应用
RUN cargo build --release

# QT5 构建阶段
FROM ubuntu:20.04 as qt-builder

# 安装 QT5 依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    qtbase5-dev \
    qt5-qmake \
    qtbase5-dev-tools \
    libqt5network5-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制 QT5 前端源码
COPY qt_frontend ./qt_frontend

# 构建 QT5 前端
RUN cd qt_frontend && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)

# 最终运行镜像
FROM ubuntu:20.04

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    libssl1.1 \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    libqt5network5 \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN useradd -r -s /bin/false scanuser

# 设置工作目录
WORKDIR /app

# 从构建阶段复制文件
COPY --from=rust-builder /app/target/release/scan_demo ./
COPY --from=qt-builder /app/qt_frontend/build/bin/ScanDemoFrontend ./

# 复制配置文件
COPY .env* ./

# 设置权限
RUN chown -R scanuser:scanuser /app
RUN chmod +x scan_demo ScanDemoFrontend

# 切换到应用用户
USER scanuser

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["./scan_demo"]
