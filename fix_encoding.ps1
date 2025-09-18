# ============================================
# 修复编码问题并创建正确的Linux脚本
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔧 修复编码问题" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 检查文件是否存在
if (-not (Test-Path "build_linux_simple_fixed.sh")) {
    Write-Host "❌ 未找到 build_linux_simple_fixed.sh 文件" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到修复后的脚本文件" -ForegroundColor Green

# 使用正确的编码保存文件
Write-Host "🔄 使用正确编码保存文件..." -ForegroundColor Yellow

# 读取文件内容
$content = Get-Content "build_linux_simple_fixed.sh" -Raw -Encoding UTF8

# 确保使用Unix换行符
$content = $content -replace "`r`n", "`n"
$content = $content -replace "`r", "`n"

# 使用UTF-8无BOM编码保存
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path "build_linux_simple_fixed.sh"), $content, $utf8NoBom)

Write-Host "✅ 编码修复完成" -ForegroundColor Green

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
Write-Host "   - build_linux_simple_fixed.sh (推荐使用，编码已修复)" -ForegroundColor Green
Write-Host ""
Write-Host "🐧 在Linux上运行:" -ForegroundColor White
Write-Host "   chmod +x build_linux_simple_fixed.sh" -ForegroundColor Cyan
Write-Host "   ./build_linux_simple_fixed.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ 中文显示应该正常了！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
