$logFile       = 'E:\claude\telegram-watchdog.log'
$heartbeatFile = 'E:\claude\bot-heartbeat.txt'
$quotaStateFile  = 'E:\claude\bot-quota-suspected.txt'
$lastRestartFile = 'E:\claude\bot-quota-restarted.txt'

function WLog([string]$m) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Out-File $logFile -Append -Encoding utf8
}

WLog "[DAILY-RESTART] 06:00 scheduled restart starting..."

# Kill existing bot
Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
    Where-Object { $_.CommandLine -match '--channels' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 3

# Clear quota state so watchdog starts fresh
Remove-Item $quotaStateFile  -ErrorAction SilentlyContinue
Remove-Item $lastRestartFile -ErrorAction SilentlyContinue

# Seed heartbeat so watchdog doesn't immediately flag as stale
Set-Content $heartbeatFile (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8

# Start bot
Start-Process 'cmd.exe' -ArgumentList '/c', '"E:\claude\Claude Telegram.bat"' -WindowStyle Minimized

WLog "[DAILY-RESTART] Done. Bot restarted, quota state cleared, heartbeat seeded."
