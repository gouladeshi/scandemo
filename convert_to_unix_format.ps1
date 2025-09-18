# ============================================
# 转换为Unix格式的脚本
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔄 转换为Unix格式" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 检查文件是否存在
if (-not (Test-Path "build_linux_simple_fixed.sh")) {
    Write-Host "❌ 未找到 build_linux_simple_fixed.sh 文件" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到脚本文件" -ForegroundColor Green

# 读取文件内容
Write-Host "🔄 读取文件内容..." -ForegroundColor Yellow
$content = Get-Content "build_linux_simple_fixed.sh" -Raw -Encoding UTF8

# 转换为Unix格式
Write-Host "🔄 转换为Unix格式..." -ForegroundColor Yellow
# 将Windows换行符(CRLF)转换为Unix换行符(LF)
$content = $content -replace "`r`n", "`n"
# 移除任何剩余的CR字符
$content = $content -replace "`r", "`n"

# 使用UTF-8无BOM编码保存为Unix格式
Write-Host "🔄 保存为Unix格式..." -ForegroundColor Yellow
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path "build_linux_simple_fixed.sh"), $content, $utf8NoBom)

Write-Host "✅ Unix格式转换完成" -ForegroundColor Green

# 验证文件格式
Write-Host "🔍 验证文件格式..." -ForegroundColor Yellow

# 检查文件内容
$lines = Get-Content "build_linux_simple_fixed.sh" -Raw
$hasCrLf = $lines -match "`r`n"
$hasCr = $lines -match "`r"

if ($hasCrLf) {
    Write-Host "⚠️  警告: 文件仍包含Windows换行符(CRLF)" -ForegroundColor Yellow
} elseif ($hasCr) {
    Write-Host "⚠️  警告: 文件仍包含CR字符" -ForegroundColor Yellow
} else {
    Write-Host "✅ 文件已成功转换为Unix格式" -ForegroundColor Green
}

# 显示文件信息
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "📋 文件信息" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if (Test-Path "build_linux_simple_fixed.sh") {
    $fileInfo = Get-Item "build_linux_simple_fixed.sh"
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
Write-Host "   - build_linux_simple_fixed.sh (Unix格式，推荐使用)" -ForegroundColor Green
Write-Host ""
Write-Host "🐧 在Linux上运行:" -ForegroundColor White
Write-Host "   chmod +x build_linux_simple_fixed.sh" -ForegroundColor Cyan
Write-Host "   ./build_linux_simple_fixed.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ 文件现在是Unix格式，中文显示正常！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
