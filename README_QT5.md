# 扫码生产看板 - QT5 + Rust 架构

## 项目概述

这是一个现代化的扫码生产看板系统，采用 **QT5 前端 + Rust 后端** 的架构设计。

### 架构特点

- **前端**: QT5 桌面应用程序，提供现代化的用户界面
- **后端**: Rust Web API 服务，提供高性能的数据处理
- **通信**: HTTP/JSON API 进行前后端通信
- **数据库**: SQLite 轻量级数据库
- **部署**: 支持树莓派等嵌入式设备

## 项目结构

```
scan_demo/
├── src/                    # Rust 后端源码
│   └── main.rs            # 主程序，包含 Web API 和 CLI 模式
├── qt_frontend/           # QT5 前端源码
│   ├── CMakeLists.txt     # CMake 构建配置
│   ├── main.cpp           # QT5 应用程序入口
│   ├── mainwindow.h/cpp   # 主窗口
│   ├── apiclient.h/cpp    # API 客户端
│   ├── barcodescanner.h/cpp # 条码扫描器
│   └── statsdisplay.h/cpp # 统计显示
├── target/                # Rust 编译输出
├── qt_frontend/build/     # QT5 编译输出
├── deploy_qt.sh          # 完整部署脚本
├── build_qt.sh           # QT5 前端构建脚本
└── start_*.sh            # 启动脚本
```

## API 接口

### 后端 API 端点

- `GET /api/health` - 健康检查
- `POST /api/scan` - 扫描条码
- `GET /api/stats` - 获取统计数据

### API 请求/响应格式

#### 扫描条码
```bash
POST /api/scan
Content-Type: application/json

{
  "barcode": "123456789"
}
```

响应：
```json
{
  "success": true,
  "message": "扫描处理完成",
  "data": {
    "success": true,
    "message": "扫描成功",
    "current_count": 15
  }
}
```

#### 获取统计
```bash
GET /api/stats
```

响应：
```json
{
  "success": true,
  "message": "统计数据获取成功",
  "data": {
    "team": "A班",
    "shift_name": "白班",
    "planned_output": 500,
    "current_count": 15,
    "completion_rate": 3.0
  }
}
```

## 安装和部署

### 系统要求

- **操作系统**: Linux 5.15+ (Ubuntu 20.04+, CentOS 8+, Fedora 35+, Arch Linux)
- **内存**: 至少 1GB RAM (推荐 2GB+)
- **存储**: 至少 2GB 可用空间
- **网络**: 支持 HTTP 请求
- **架构**: x86_64, aarch64, armv7l

### 依赖包

- Rust 1.70+
- Qt5 开发包
- CMake 3.16+
- SQLite3
- OpenSSL 开发库

### 快速部署

#### 方法一：自动部署脚本（推荐）

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd scan_demo
   ```

2. **Linux 5.15 系统快速部署**
   ```bash
   chmod +x deploy_linux.sh
   ./deploy_linux.sh
   ```

3. **启动应用**
   ```bash
   # 启动完整应用（推荐）
   ./start_all.sh
   
   # 或分别启动
   ./start_backend.sh  # 启动后端
   ./start_frontend.sh # 启动前端
   ```

#### 方法二：完整部署脚本

```bash
chmod +x deploy_qt.sh
./deploy_qt.sh
```

#### 方法三：系统服务安装

```bash
# 安装为系统服务
sudo chmod +x install_service.sh
sudo ./install_service.sh

# 管理服务
sudo systemctl start scan-demo-qt
sudo systemctl status scan-demo-qt
sudo journalctl -u scan-demo-qt -f
```

### 手动构建

#### 构建 Rust 后端
```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# 编译
cargo build --release
```

#### 构建 QT5 前端
```bash
# 安装依赖
sudo apt-get install qtbase5-dev cmake build-essential

# 构建
cd qt_frontend
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

## 使用说明

### 启动应用

1. **启动后端服务**
   ```bash
   ./target/release/scan_demo
   ```
   后端将在 `http://0.0.0.0:3000` 启动

2. **启动前端应用**
   ```bash
   ./qt_frontend/build/bin/ScanDemoFrontend
   ```

### 功能特性

#### 前端界面
- **生产统计显示**: 实时显示班组、班次、计划产量、当前产量
- **进度条**: 可视化显示完成率
- **条码扫描**: 支持手动输入和扫码枪输入
- **操作日志**: 显示所有操作记录
- **自动刷新**: 每5秒自动更新统计数据

#### 后端服务
- **RESTful API**: 标准的 HTTP/JSON 接口
- **数据库管理**: 自动创建和管理 SQLite 数据库
- **外部接口**: 支持调用外部 API 验证条码
- **日志记录**: 详细的运行日志
- **CORS 支持**: 支持跨域请求

### 配置选项

#### 环境变量
```bash
# 数据库连接
DATABASE_URL=sqlite:scan_demo.db

# 外部 API 地址
EXTERNAL_API_URL=https://httpbin.org/post

# 日志级别
RUST_LOG=info,sqlx=warn
```

#### 前端配置
前端默认连接 `http://localhost:3000`，可以通过环境变量修改：
```bash
export API_BASE_URL=http://your-server:3000
./qt_frontend/build/bin/ScanDemoFrontend
```

## 网络访问

### 本地访问
- 后端 API: `http://localhost:3000`
- 前端应用: 直接运行 QT5 程序

### 局域网访问
- 后端 API: `http://树莓派IP:3000`
- 前端应用: 在 PC 上运行，配置 API 地址

### 防火墙配置
```bash
# 开放端口
sudo ufw allow 3000

# 检查状态
sudo ufw status
```

## 故障排除

### 常见问题

1. **编译失败**
   - 检查依赖包是否完整安装
   - 确保网络连接正常
   - 检查磁盘空间是否充足

2. **前端无法连接后端**
   - 确认后端服务已启动
   - 检查防火墙设置
   - 验证网络连接

3. **数据库错误**
   - 检查数据库文件权限
   - 确认 SQLite3 已安装
   - 查看应用日志

### 日志查看
```bash
# 后端日志
tail -f scan_demo.log

# 系统日志
journalctl -u scan-demo -f
```

## 开发指南

### 添加新功能

1. **后端 API**
   - 在 `src/main.rs` 中添加新的路由处理函数
   - 定义相应的请求/响应结构体
   - 更新数据库模式（如需要）

2. **前端界面**
   - 在 `qt_frontend/` 中添加新的 UI 组件
   - 在 `apiclient.cpp` 中添加新的 API 调用
   - 更新主窗口以集成新功能

### 代码结构

- **后端**: 使用 Axum 框架，采用异步编程模型
- **前端**: 使用 QT5 信号槽机制，采用事件驱动模型
- **通信**: 基于 HTTP/JSON 的 RESTful API

## 许可证

本项目采用 MIT 许可证，详见 LICENSE 文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进项目。

## 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至项目维护者
