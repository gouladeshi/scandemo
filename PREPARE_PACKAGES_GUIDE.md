# 预下载安装包使用指南

## 概述

这个方案允许你在有网络的机器上预下载所有需要的安装包，然后在目标机器上直接安装，无需网络连接。

## 使用流程

### 步骤 1: 在有网络的机器上准备包

```bash
# 1. 预下载所有安装包
chmod +x prepare_packages.sh
./prepare_packages.sh

# 2. 创建完整项目包
chmod +x package_with_deps.sh
./package_with_deps.sh
```

### 步骤 2: 在目标机器上部署

```bash
# 1. 解压包
tar -xzf scan-demo-with-deps-*.tar.gz
cd scan-demo-with-deps-*

# 2. 安装
chmod +x install.sh
./install.sh

# 3. 启动
./start.sh
```

## 详细说明

### 预下载的包类型

#### 1. 系统包
- **Ubuntu/Debian**: `.deb` 包
- **CentOS/RHEL**: `.rpm` 包  
- **Fedora**: `.rpm` 包
- **Arch Linux**: `.pkg.tar.*` 包

#### 2. Rust 工具链
- `rustup-init.sh` - Rust 安装脚本
- Cargo 依赖缓存

#### 3. 开发工具
- 编译器 (gcc, g++)
- 构建工具 (make, cmake)
- 库文件 (sqlite, openssl, qt5)

### 目录结构

```
packages/
├── ubuntu/           # Ubuntu/Debian 包
│   ├── *.deb
│   └── install.sh
├── centos/           # CentOS/RHEL 包
│   ├── *.rpm
│   └── install.sh
├── fedora/           # Fedora 包
│   ├── *.rpm
│   └── install.sh
├── arch/             # Arch Linux 包
│   ├── *.pkg.tar.*
│   └── install.sh
├── rust/             # Rust 工具链
│   ├── rustup-init.sh
│   └── install.sh
└── README.md         # 包说明
```

### 安装脚本

每个包目录都包含一个 `install.sh` 脚本：

```bash
# Ubuntu/Debian
cd packages/ubuntu
./install.sh

# CentOS/RHEL
cd packages/centos
./install.sh

# Fedora
cd packages/fedora
./install.sh

# Arch Linux
cd packages/arch
./install.sh
```

## 优势

### 1. 离线部署
- ✅ 无需网络连接
- ✅ 避免网络问题
- ✅ 适合内网环境

### 2. 版本控制
- ✅ 固定版本依赖
- ✅ 避免版本冲突
- ✅ 可重复部署

### 3. 批量部署
- ✅ 一次准备，多处使用
- ✅ 统一环境配置
- ✅ 减少部署时间

### 4. 安全性
- ✅ 避免下载恶意包
- ✅ 可控的依赖来源
- ✅ 审计友好

## 注意事项

### 1. 系统兼容性
- 确保目标系统与预下载包兼容
- 检查架构匹配 (x86_64, aarch64)
- 验证发行版版本

### 2. 包完整性
- 检查所有依赖包是否下载完整
- 验证包文件完整性
- 测试安装脚本

### 3. 权限要求
- 安装需要 sudo 权限
- 确保用户有足够权限
- 检查文件权限设置

### 4. 存储空间
- 预下载包占用较大空间
- 确保目标机器有足够空间
- 考虑压缩传输

## 故障排除

### 1. 包下载失败
```bash
# 检查网络连接
ping google.com

# 检查包管理器
sudo apt update  # Ubuntu/Debian
sudo dnf update  # Fedora
```

### 2. 安装失败
```bash
# 检查包完整性
ls -la packages/*/

# 检查系统兼容性
cat /etc/os-release

# 查看错误日志
sudo dmesg | tail
```

### 3. 编译失败
```bash
# 检查依赖安装
dpkg -l | grep -E "(gcc|cmake|qt5)"  # Ubuntu/Debian
rpm -qa | grep -E "(gcc|cmake|qt5)"  # CentOS/RHEL

# 检查环境变量
echo $PATH
echo $CARGO_HOME
```

## 最佳实践

### 1. 准备阶段
- 在相同系统上预下载包
- 测试安装脚本
- 验证包完整性

### 2. 传输阶段
- 使用压缩包传输
- 验证传输完整性
- 检查文件权限

### 3. 部署阶段
- 按顺序安装依赖
- 检查安装结果
- 测试应用功能

### 4. 维护阶段
- 定期更新包版本
- 备份工作配置
- 记录部署日志

## 示例命令

### 完整流程示例

```bash
# 1. 准备阶段（有网络机器）
./prepare_packages.sh
./package_with_deps.sh

# 2. 传输到目标机器
scp packages/scan-demo-with-deps-*.tar.gz user@target:/tmp/

# 3. 目标机器部署
cd /tmp
tar -xzf scan-demo-with-deps-*.tar.gz
cd scan-demo-with-deps-*
./install.sh
./start.sh
```

### 手动安装示例

```bash
# 1. 安装系统包
cd packages/ubuntu
sudo dpkg -i *.deb
sudo apt-get install -f -y

# 2. 安装 Rust
cd ../rust
./rustup-init.sh -y

# 3. 编译项目
export PATH="$HOME/.cargo/bin:$PATH"
cargo build --release
```

这个方案让你可以完全控制依赖的下载和安装过程，特别适合需要离线部署或批量部署的场景。
