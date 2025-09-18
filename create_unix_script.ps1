# 创建完全正确的Unix格式脚本
Write-Host "创建Unix格式脚本..." -ForegroundColor Cyan

# 读取原始文件内容
$content = Get-Content "build_linux_simple_fixed.sh" -Raw

# 强制转换为Unix格式
$content = $content -replace "`r`n", "`n"
$content = $content -replace "`r", "`n"

# 使用UTF-8无BOM编码保存
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("build_linux_final.sh", $content, $utf8NoBom)

Write-Host "Unix格式脚本创建完成: build_linux_final.sh" -ForegroundColor Green

# 验证文件
$finalContent = Get-Content "build_linux_final.sh" -Raw
$hasCrLf = $finalContent -match "`r`n"
$hasCr = $finalContent -match "`r"

Write-Host "验证结果:" -ForegroundColor Yellow
Write-Host "  CRLF: $hasCrLf" -ForegroundColor $(if (-not $hasCrLf) { "Green" } else { "Red" })
Write-Host "  CR: $hasCr" -ForegroundColor $(if (-not $hasCr) { "Green" } else { "Red" })

if (-not $hasCrLf -and -not $hasCr) {
    Write-Host "✅ 文件已成功转换为Unix格式！" -ForegroundColor Green
} else {
    Write-Host "❌ 转换失败" -ForegroundColor Red
}
