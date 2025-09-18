# ============================================
# 转换脚本文件为Linux格式 (PowerShell版本)
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔄 转换脚本文件为Linux格式" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 检查文件是否存在
if (-not (Test-Path "build_linux_simple.sh")) {
    Write-Host "❌ 未找到 build_linux_simple.sh 文件" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到 build_linux_simple.sh 文件" -ForegroundColor Green

# 转换文件格式
Write-Host "🔄 转换文件格式..." -ForegroundColor Yellow

# 读取文件内容并转换为Unix格式
$content = Get-Content "build_linux_simple.sh" -Raw
$content = $content -replace "`r`n", "`n"
$content = $content -replace "`r", "`n"

# 保存为Unix格式
$content | Out-File -FilePath "build_linux_simple_unix.sh" -Encoding UTF8 -NoNewline

Write-Host "✅ 转换完成" -ForegroundColor Green

# 显示文件信息
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "📋 文件信息" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if (Test-Path "build_linux_simple_unix.sh") {
    $fileInfo = Get-Item "build_linux_simple_unix.sh"
    Write-Host "文件名: $($fileInfo.Name)" -ForegroundColor White
    Write-Host "大小: $($fileInfo.Length) 字节" -ForegroundColor White
    Write-Host "创建时间: $($fileInfo.CreationTime)" -ForegroundColor White
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🚀 使用说明" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 现在您可以复制以下文件到Linux:" -ForegroundColor White
Write-Host "   - build_linux_simple_unix.sh (推荐使用)" -ForegroundColor Green
Write-Host "   - build_linux_simple.sh (原文件)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🐧 在Linux上运行:" -ForegroundColor White
Write-Host "   chmod +x build_linux_simple_unix.sh" -ForegroundColor Cyan
Write-Host "   ./build_linux_simple_unix.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
