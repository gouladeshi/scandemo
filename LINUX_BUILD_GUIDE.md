# Linux 编译指南

## 📋 概述

本指南将帮助您将 Rust + Qt 扫码生产看板项目编译成 Linux 可执行文件。

## 🛠️ 编译方式

### 方式一：直接编译（推荐）

在 Linux 系统上直接编译：

```bash
# 1. 给脚本执行权限
chmod +x build_linux_simple.sh

# 2. 运行编译脚本
./build_linux_simple.sh
```

**系统要求：**
- Ubuntu 18.04+ / CentOS 7+ / Fedora 30+
- 网络连接（用于下载依赖）

### 方式二：Docker 编译

使用 Docker 容器编译（跨平台）：

```bash
# 1. 给脚本执行权限
chmod +x build_docker_linux.sh

# 2. 运行 Docker 编译脚本
./build_docker_linux.sh
```

**系统要求：**
- Docker 20.0+
- 网络连接

### 方式三：Windows 环境编译

在 Windows 上使用 WSL 或 Docker：

```bash
# 运行 Windows 批处理脚本
build_linux_complete.bat
```

然后选择：
- 选项 1：使用 Docker 编译
- 选项 2：使用 WSL 编译
- 选项 3：生成 Linux 编译脚本

## 📦 编译结果

编译完成后，您将得到以下文件：

```
项目目录/
├── target/release/scan_demo          # Rust 后端可执行文件
├── qt_frontend/build/bin/ScanDemoFrontend  # Qt 前端可执行文件
├── start_backend.sh                  # 后端启动脚本
├── start_frontend.sh                 # 前端启动脚本
├── start_complete.sh                 # 完整应用启动脚本
└── scan-demo-linux-*.tar.gz         # 部署包
```

## 🚀 运行应用

### 快速启动（推荐）

```bash
./start_complete.sh
```

这个脚本会：
1. 自动启动后端服务
2. 启动前端应用
3. 处理端口冲突检测

### 分别启动

```bash
# 终端1：启动后端
./start_backend.sh

# 终端2：启动前端
./start_frontend.sh
```

### 直接运行

```bash
# 启动后端
./target/release/scan_demo

# 启动前端
./qt_frontend/build/bin/ScanDemoFrontend
```

## ⚙️ 配置说明

### 环境变量

- `API_BASE_URL`: 前端连接的后端地址（默认：http://localhost:3000）
- `DATABASE_URL`: 数据库连接字符串（默认：sqlite:scan_demo.db）
- `EXTERNAL_API_URL`: 外部API地址（默认：https://httpbin.org/post）

### 端口配置

- 后端默认端口：3000
- 可通过修改 `src/main.rs` 中的端口配置

### 数据库

- 默认使用 SQLite 数据库：`scan_demo.db`
- 首次运行会自动创建数据库和表结构

## 🔧 故障排除

### 常见问题

1. **Qt5 库缺失**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install qt5-default qtbase5-dev
   
   # CentOS/RHEL
   sudo yum install qt5-qtbase
   
   # Fedora
   sudo dnf install qt5-qtbase
   ```

2. **权限问题**
   ```bash
   chmod +x target/release/scan_demo
   chmod +x qt_frontend/build/bin/ScanDemoFrontend
   chmod +x start_*.sh
   ```

3. **端口被占用**
   ```bash
   # 查看端口占用
   netstat -tlnp | grep 3000
   
   # 杀死占用进程
   sudo kill -9 <PID>
   ```

4. **编译失败**
   - 检查网络连接
   - 确保有足够的磁盘空间
   - 检查系统依赖是否完整安装

### 日志查看

- 后端日志：`backend.log`
- 系统日志：`journalctl -u scan-demo`

## 📋 系统要求

### 运行时要求

- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+, Fedora 30+)
- **内存**: 最少 512MB，推荐 1GB+
- **磁盘**: 最少 100MB 可用空间
- **网络**: 用于外部API调用

### 编译时要求

- **Rust**: 1.70+
- **Qt5**: 5.12+
- **CMake**: 3.16+
- **GCC**: 7.0+
- **pkg-config**

## 🔄 更新和维护

### 更新应用

1. 停止运行中的应用
2. 重新编译
3. 替换可执行文件
4. 重启应用

### 数据备份

```bash
# 备份数据库
cp scan_demo.db scan_demo.db.backup

# 备份配置文件
cp .env .env.backup
```

## 📞 技术支持

如果遇到问题，请检查：

1. 系统依赖是否完整安装
2. 网络连接是否正常
3. 端口是否被占用
4. 日志文件中的错误信息

## 📝 版本信息

- **项目版本**: 0.1.0
- **Rust版本**: 1.70+
- **Qt版本**: 5.12+
- **最后更新**: 2024年
