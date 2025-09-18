# ============================================
# 验证Unix格式的脚本
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔍 验证Unix格式" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 检查文件是否存在
if (-not (Test-Path "build_linux_simple_fixed.sh")) {
    Write-Host "❌ 未找到 build_linux_simple_fixed.sh 文件" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到脚本文件" -ForegroundColor Green

# 读取文件内容进行验证
Write-Host "🔍 验证文件格式..." -ForegroundColor Yellow

# 以二进制方式读取文件来检查换行符
$bytes = [System.IO.File]::ReadAllBytes("build_linux_simple_fixed.sh")
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

# 检查换行符类型
$crlfCount = ($content -split "`r`n").Count - 1
$lfCount = ($content -split "`n").Count - 1
$crCount = ($content -split "`r").Count - 1

Write-Host "📊 换行符统计:" -ForegroundColor White
Write-Host "   CRLF (Windows): $crlfCount" -ForegroundColor $(if ($crlfCount -eq 0) { "Green" } else { "Red" })
Write-Host "   LF (Unix): $lfCount" -ForegroundColor $(if ($lfCount -gt 0) { "Green" } else { "Red" })
Write-Host "   CR (Mac): $crCount" -ForegroundColor $(if ($crCount -eq 0) { "Green" } else { "Red" })

# 检查编码
$encoding = [System.Text.Encoding]::UTF8
$hasBom = $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

Write-Host "📊 编码信息:" -ForegroundColor White
Write-Host "   编码: UTF-8" -ForegroundColor Green
Write-Host "   BOM: $(if ($hasBom) { "有" } else { "无" })" -ForegroundColor $(if (-not $hasBom) { "Green" } else { "Yellow" })

# 检查中文显示
$chineseTest = $content -match "开始编译|编译完成|启动"
Write-Host "📊 中文显示:" -ForegroundColor White
Write-Host "   中文内容: $(if ($chineseTest) { "正常" } else { "异常" })" -ForegroundColor $(if ($chineseTest) { "Green" } else { "Red" })

# 总体评估
$isUnixFormat = $crlfCount -eq 0 -and $crCount -eq 0 -and $lfCount -gt 0
$isCorrectEncoding = -not $hasBom
$hasChinese = $chineseTest

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "📋 验证结果" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($isUnixFormat -and $isCorrectEncoding -and $hasChinese) {
    Write-Host "✅ 文件格式完全正确！" -ForegroundColor Green
    Write-Host "   - Unix换行符: ✅" -ForegroundColor Green
    Write-Host "   - UTF-8无BOM: ✅" -ForegroundColor Green
    Write-Host "   - 中文显示: ✅" -ForegroundColor Green
} else {
    Write-Host "⚠️  文件格式需要调整:" -ForegroundColor Yellow
    if (-not $isUnixFormat) {
        Write-Host "   - Unix换行符: ❌" -ForegroundColor Red
    }
    if (-not $isCorrectEncoding) {
        Write-Host "   - UTF-8无BOM: ❌" -ForegroundColor Red
    }
    if (-not $hasChinese) {
        Write-Host "   - 中文显示: ❌" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🚀 使用说明" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 复制到Linux:" -ForegroundColor White
Write-Host "   - build_linux_simple_fixed.sh" -ForegroundColor Green
Write-Host ""
Write-Host "🐧 在Linux上运行:" -ForegroundColor White
Write-Host "   chmod +x build_linux_simple_fixed.sh" -ForegroundColor Cyan
Write-Host "   ./build_linux_simple_fixed.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
