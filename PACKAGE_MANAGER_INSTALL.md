# 📦 包管理器自动安装功能

## 🎯 新增功能

脚本现在支持自动检测和安装包管理器！

## 🔧 功能特性

### 1. 自动检测系统类型
- ✅ Ubuntu/Debian
- ✅ CentOS/RHEL
- ✅ Fedora
- ✅ Arch Linux/Manjaro
- ✅ openSUSE
- ✅ 其他Linux发行版

### 2. 智能包管理器检测
脚本会按优先级检测以下包管理器：
- `apt-get` (Ubuntu/Debian)
- `yum` (CentOS/RHEL)
- `dnf` (Fedora)
- `pacman` (Arch Linux)
- `zypper` (openSUSE)

### 3. 自动安装包管理器
如果检测不到包管理器，脚本会尝试：
- **Ubuntu/Debian**: 下载并安装 apt 包
- **CentOS/RHEL**: 下载并安装 yum 包
- **其他系统**: 提供手动安装指导

### 4. 详细的手动安装指导
如果自动安装失败，脚本会显示：
- 各系统的安装命令
- 必需的工具列表
- 具体的包名

## 🚀 使用场景

### 场景1：完整系统
```bash
./build_linux_simple_fixed.sh
# 脚本自动检测并使用现有包管理器
```

### 场景2：最小化安装系统
```bash
./build_linux_simple_fixed.sh
# 脚本检测到缺少包管理器，自动尝试安装
```

### 场景3：特殊系统
```bash
./build_linux_simple_fixed.sh
# 脚本显示详细的手动安装指导
```

## 📋 支持的包管理器

| 系统 | 包管理器 | 状态 |
|------|----------|------|
| Ubuntu/Debian | apt-get | ✅ 支持 |
| CentOS/RHEL | yum | ✅ 支持 |
| Fedora | dnf | ✅ 支持 |
| Arch Linux | pacman | ✅ 支持 |
| openSUSE | zypper | ✅ 支持 |

## 🔍 安装过程

### 1. 系统检测
```
[INFO] 检测系统类型和包管理器...
[INFO] 检测到系统: ubuntu
```

### 2. 包管理器检测
```
[SUCCESS] 找到可用的包管理器
```

### 3. 依赖安装
```
[INFO] 使用 apt-get 安装依赖...
[INFO] 安装 Qt5 开发包...
```

### 4. 手动指导（如果需要）
```
============================================
📋 手动安装指导
============================================

🔧 基础编译工具:
  Ubuntu/Debian: sudo apt-get install build-essential
  CentOS/RHEL:   sudo yum groupinstall 'Development Tools'
  ...
```

## ⚠️ 注意事项

1. **网络连接**: 自动安装需要网络连接
2. **权限要求**: 需要 sudo 权限
3. **系统完整性**: 建议使用完整的Linux发行版
4. **最小化系统**: 可能需要额外的基础工具

## 🛠️ 故障排除

### 问题1：无法安装包管理器
**解决方案**: 使用手动安装指导
```bash
# 按照脚本显示的命令手动安装
sudo apt-get install build-essential cmake pkg-config curl wget
```

### 问题2：网络连接问题
**解决方案**: 检查网络连接或使用离线安装
```bash
# 确保网络连接正常
ping google.com
```

### 问题3：权限不足
**解决方案**: 确保有sudo权限
```bash
# 检查sudo权限
sudo -v
```

## 📞 技术支持

如果遇到问题：
1. 查看脚本输出的错误信息
2. 按照手动安装指导操作
3. 确保系统满足最低要求
4. 检查网络连接和权限

---

**更新内容**: 添加了包管理器自动检测和安装功能
**兼容性**: 支持主流Linux发行版
**推荐使用**: `build_linux_simple_fixed.sh`
