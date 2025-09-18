# 🐧 复制到Linux系统指南

## ✅ 文件转换完成

您的脚本文件已经成功转换为Linux格式！

## 📋 需要复制的文件清单

### 必需文件
```
项目根目录/
├── Cargo.toml                           # Rust项目配置
├── Cargo.lock                           # 依赖锁定文件
├── src/                                 # Rust源代码目录
│   └── main.rs
├── qt_frontend/                         # Qt前端目录
│   ├── CMakeLists.txt
│   ├── *.cpp, *.h                       # 所有C++源文件
│   └── *.ui                             # UI文件
└── build_linux_simple_unix.sh           # 编译脚本（推荐）
```

### 可选文件
```
├── static/                              # 静态文件（如果存在）
├── templates/                           # 模板文件（如果存在）
├── sql/                                 # SQL文件（如果存在）
└── README.md                            # 说明文档
```

## 🚀 在Linux系统上的操作步骤

### 1. 复制文件到Linux系统
将上述文件复制到Linux系统的任意目录

### 2. 进入项目目录
```bash
cd /path/to/your/project
```

### 3. 设置执行权限
```bash
chmod +x build_linux_simple_unix.sh
```

### 4. 运行编译脚本
```bash
./build_linux_simple_unix.sh
```

## 🔧 编译过程说明

脚本会自动执行以下操作：

1. **检查系统依赖**
   - 自动检测包管理器（apt-get, yum, dnf）
   - 安装必要的构建工具

2. **安装Rust**
   - 自动下载并安装Rust工具链

3. **安装Qt5开发包**
   - 根据系统自动安装Qt5开发环境

4. **编译Rust后端**
   - 编译生成 `target/release/scan_demo`

5. **编译Qt前端**
   - 编译生成 `qt_frontend/build/bin/ScanDemoFrontend`

6. **创建启动脚本**
   - 生成 `start_*.sh` 启动脚本

## 🎯 编译完成后

### 启动应用
```bash
# 启动完整应用（推荐）
./start_complete.sh

# 或者分别启动
./start_backend.sh    # 启动Rust后端
./start_frontend.sh   # 启动Qt前端
```

### 生成的文件
```
├── target/release/scan_demo              # Rust后端可执行文件
├── qt_frontend/build/bin/ScanDemoFrontend # Qt前端可执行文件
├── start_backend.sh                      # 后端启动脚本
├── start_frontend.sh                     # 前端启动脚本
├── start_complete.sh                     # 完整应用启动脚本
└── scan_demo.db                          # 数据库文件（自动创建）
```

## ⚠️ 注意事项

1. **确保网络连接** - 编译过程需要下载依赖
2. **确保有sudo权限** - 需要安装系统包
3. **确保磁盘空间** - 至少需要1GB可用空间
4. **确保系统兼容** - 支持Ubuntu 18.04+, CentOS 7+, Fedora 30+

## 🔍 故障排除

### 如果遇到权限问题
```bash
sudo chmod +x build_linux_simple_unix.sh
```

### 如果遇到依赖问题
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential cmake pkg-config curl

# CentOS/RHEL
sudo yum update
sudo yum install gcc gcc-c++ make cmake pkgconfig curl
```

### 如果遇到Qt5问题
```bash
# Ubuntu/Debian
sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools

# CentOS/RHEL
sudo yum install qt5-qtbase-devel qt5-qtbase-gui
```

## 📞 技术支持

如果遇到问题，请检查：
1. 系统依赖是否完整安装
2. 网络连接是否正常
3. 磁盘空间是否充足
4. 查看编译日志中的错误信息

---

**文件转换完成时间**: 2024年
**推荐使用**: `build_linux_simple_unix.sh`
