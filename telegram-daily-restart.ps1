# 每日固定重啟 TG bot（需管理員建排程，每日 06:00）
# 新守護只看結構健康，不用 quota 檔/心跳，這裡也對齊：純 kill + restart。

$logFile = 'E:\claude\telegram-watchdog.log'
function WLog([string]$m) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Out-File $logFile -Append -Encoding utf8
}

WLog "[DAILY-RESTART] scheduled restart starting..."

# 殺 --channels bot + 一併清 telegram bun（避免孤兒 bun 佔住接收槽）
Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
    Where-Object { $_.CommandLine -match '--channels' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Get-CimInstance Win32_Process -Filter "Name='bun.exe'" |
    Where-Object { $_.CommandLine -match 'server\.ts' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 3

# 重啟（.bat 內含 --settings，是唯一正確啟動方式）
Start-Process 'cmd.exe' -ArgumentList '/c', '"E:\claude\Claude Telegram.bat"' -WindowStyle Minimized

WLog "[DAILY-RESTART] Done. Bot restarted."
