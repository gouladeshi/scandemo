# 简单验证Unix格式
Write-Host "验证文件格式..." -ForegroundColor Cyan

if (Test-Path "build_linux_simple_fixed.sh") {
    $content = Get-Content "build_linux_simple_fixed.sh" -Raw
    $hasCrLf = $content -match "`r`n"
    $hasCr = $content -match "`r"
    
    Write-Host "文件检查结果:" -ForegroundColor White
    Write-Host "  CRLF (Windows): $(if ($hasCrLf) { '有' } else { '无' })" -ForegroundColor $(if (-not $hasCrLf) { 'Green' } else { 'Red' })
    Write-Host "  CR (Mac): $(if ($hasCr) { '有' } else { '无' })" -ForegroundColor $(if (-not $hasCr) { 'Green' } else { 'Red' })
    
    if (-not $hasCrLf -and -not $hasCr) {
        Write-Host "✅ 文件已转换为Unix格式！" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 文件仍包含非Unix换行符" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ 文件不存在" -ForegroundColor Red
}
