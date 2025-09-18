# 🎯 最终Linux编译脚本

## ✅ 问题已解决

之前的 `build_linux_simple_unix.sh` 文件中文显示乱码，现在已经修复！

## 📋 使用正确的文件

**请使用：`build_linux_simple_fixed.sh`**

这个文件已经：
- ✅ 修复了中文编码问题
- ✅ 使用正确的UTF-8编码
- ✅ 使用Unix换行符
- ✅ 中文显示正常

## 🚀 复制到Linux的步骤

### 1. 复制文件到Linux系统
复制以下文件：
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
└── build_linux_simple_fixed.sh          # 编译脚本（推荐）
```

### 2. 在Linux上运行
```bash
# 进入项目目录
cd /path/to/your/project

# 设置执行权限
chmod +x build_linux_simple_fixed.sh

# 运行编译脚本
./build_linux_simple_fixed.sh
```

## 🎉 编译完成后

```bash
# 启动完整应用
./start_complete.sh
```

## 📝 文件说明

- **`build_linux_simple_fixed.sh`** - 修复编码后的编译脚本（推荐使用）
- **`build_linux_simple.sh`** - 原始脚本（可能有编码问题）
- **`build_linux_complete.sh`** - 完整版编译脚本

## ⚠️ 注意事项

1. **使用 `build_linux_simple_fixed.sh`** - 这个文件中文显示正常
2. **确保网络连接** - 编译过程需要下载依赖
3. **确保有sudo权限** - 需要安装系统包
4. **确保磁盘空间** - 至少需要1GB可用空间

## 🔍 如果还有问题

如果 `build_linux_simple_fixed.sh` 仍然有编码问题，请：

1. 在Linux上运行：
   ```bash
   file build_linux_simple_fixed.sh
   ```

2. 如果显示编码问题，运行：
   ```bash
   iconv -f utf-8 -t utf-8 build_linux_simple_fixed.sh > build_linux_final.sh
   chmod +x build_linux_final.sh
   ./build_linux_final.sh
   ```

---

**推荐使用**: `build_linux_simple_fixed.sh`
**编码**: UTF-8 (无BOM)
**换行符**: Unix (LF)
