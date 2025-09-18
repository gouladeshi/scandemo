## 扫码生产看板 Demo（Rust + Axum + SQLite + HTMX + Alpine.js）

### 功能
- 前端输入/扫描条码；
- 后台调用外部接口（默认 `https://httpbin.org/post`，可配置）；
- 显示当前班组、班次、本班次排产量、实时产量；
- 显示最近一次条码扫描是否成功。

### 运行
1) 安装 Rust（Raspberry Pi Ubuntu 建议使用 `rustup` 安装 stable）。
2) 在项目根目录创建 `.env`（已自动生成，可修改）：
```
DATABASE_URL=sqlite:scan_demo.db
EXTERNAL_API_URL=https://httpbin.org/post
RUST_LOG=info,sqlx=warn
```
3) 编译并运行：

**Web模式（浏览器界面）:**
```
cargo run
```
访问：`http://<设备IP>:3000/`

**CLI模式（命令行界面）:**
```
cargo run -- --cli
```
直接在终端中输入条码，支持以下命令：
- `<条码>` - 扫描条码
- `stats` - 显示当前统计
- `help` - 显示帮助
- `quit` - 退出程序

### 修改班次与计划
当前以 `shift_plan` 表保存班组/班次/排产量以及开始/结束时间（24小时制）。首次运行会自动插入：A班/白班/500，08:00:00-20:00:00。可用任意 SQLite 管理工具或 `sqlx` CLI 修改。

### 外部接口
默认用 httpbin 做示例，实际生产可将 `EXTERNAL_API_URL` 设置为你的接口地址；服务将以 JSON `{ "barcode": "xxx" }` POST 过去，并根据 HTTP 状态码判定成功与否。

### 部署到树莓派（Ubuntu）

**重要说明：** Ubuntu是Linux系统，不能运行Windows的`.exe`文件。需要在Ubuntu上重新编译。

#### 快速部署（推荐）
1. 将项目文件复制到树莓派
2. 给部署脚本执行权限：
   ```bash
   chmod +x deploy.sh
   ```
3. 运行部署脚本：
   ```bash
   ./deploy.sh
   ```

#### 手动部署
1. 确保安装 `libsqlite3-dev`：
   ```bash
   sudo apt update
   sudo apt install -y build-essential libsqlite3-dev pkg-config
   ```
2. 安装Rust（如果未安装）：
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source ~/.cargo/env
   
   ```
3. 构建：
   ```bash
   cargo build --release
   ```
4. 运行：
   ```bash
   # CLI模式（推荐）
   ./target/release/scan_demo --cli
   
   # Web模式
   ./target/release/scan_demo
   ```

#### 后台运行
```bash
# 后台运行CLI模式
nohup ./target/release/scan_demo --cli > scan_demo.log 2>&1 &

# 查看日志
tail -f scan_demo.log

# 停止程序
pkill scan_demo
```

#### systemd服务（可选）
创建服务文件 `/etc/systemd/system/scan-demo.service`：
```ini
[Unit]
Description=Scan Demo Production Board
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/scan_demo
ExecStart=/home/pi/scan_demo/target/release/scan_demo --cli
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl enable scan-demo
sudo systemctl start scan-demo
sudo systemctl status scan-demo
```
