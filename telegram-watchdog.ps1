# Telegram Bot 守護腳本（每 10 分鐘由排程觸發）
# 只看「結構健康」，不用心跳猜額度（安靜沒人傳訊時心跳本來就停，不代表壞）：
#   Layer 1：Bot 進程死了 → 自動重啟，失敗則 npm 修復
#   Layer 2：TG 接收槽被另一個 --channels 進程搶走 → 靜默重啟奪回
#   Layer 3：Bot 活著但收訊進程(bun poller)不在 → 殭屍 → 重啟
# 健康就靜默結束。判斷壞沒壞另有 bot-health.ps1。

$ErrorActionPreference = 'Continue'
$logFile = 'E:\claude\telegram-watchdog.log'
$env:PATH = "C:\nvm4w\nodejs;$env:PATH"

function WLog([string]$m) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m" | Out-File $logFile -Append -Encoding utf8
}

function Send-Telegram([string]$Message) {
    $token = (Get-Content 'C:\Users\21030502\.claude\channels\telegram\.env' -Encoding UTF8 |
        Where-Object { $_ -match 'TELEGRAM_BOT_TOKEN=(.+)' } |
        ForEach-Object { $matches[1] })
    $chatId = '729844447'
    try {
        $body = @{ chat_id = $chatId; text = $Message } | ConvertTo-Json
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post -Body $body -ContentType 'application/json; charset=utf-8' | Out-Null
    } catch {
        WLog "TG send failed: $_"
    }
}

function Test-BotAlive {
    return (@(Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
        Where-Object { $_.CommandLine -match '--channels' }).Count -ge 1)
}

function Kill-Bot {
    Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
        Where-Object { $_.CommandLine -match '--channels' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 3
}

function Start-Bot {
    Start-Process 'cmd.exe' -ArgumentList '/c', '"E:\claude\Claude Telegram.bat"' -WindowStyle Minimized
    Start-Sleep -Seconds 60
    return (Test-BotAlive)
}

# ─────────────────────────────────────────────────────────────────────────────
# Layer 1：Bot 進程死了 → 重啟
# ─────────────────────────────────────────────────────────────────────────────

if (-not (Test-BotAlive)) {

    WLog "[DEAD] Bot session not found. Restarting..."
    . "E:\claude\daily\common.ps1"

    if (Start-Bot) {
        WLog "[RESTARTED] Bot is back."
        Send-Telegram "🔄 Telegram Bot 剛剛斷線，守護排程已自動重啟成功（$(Get-Date -Format 'HH:mm')）"
        exit 0
    }

    WLog "[RETRY] First restart failed. Checking claude command..."
    $claudeOk = $false
    try {
        $v = cmd /c "claude --version 2>&1"
        if ($LASTEXITCODE -eq 0 -and $v -match '\d+\.\d+') { $claudeOk = $true }
    } catch {}

    if (-not $claudeOk) {
        WLog "[REPAIR] claude command broken. Running npm reinstall..."
        cmd /c "npm install -g @anthropic-ai/claude-code >> ""$logFile"" 2>&1"
        if (Start-Bot) {
            WLog "[REPAIRED] npm reinstall fixed it. Bot is back."
            Send-Telegram "🔧 Telegram Bot 斷線且 claude 指令壞掉，守護排程已自動修復 + 重啟成功（$(Get-Date -Format 'HH:mm')）"
            exit 0
        }
    }

    WLog "[FAIL] All restart attempts failed."
    Send-Telegram "🔴 Telegram Bot 斷線，自動重啟與修復都失敗！請手動雙擊 E:\claude\Claude Telegram.bat（$(Get-Date -Format 'HH:mm')）"
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Layer 2：進程活著 → 確認 TG 接收槽沒被另一個 --channels 搶走
# ─────────────────────────────────────────────────────────────────────────────

$botProc = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
    Where-Object { $_.CommandLine -match '--channels' } |
    Select-Object -First 1

# 只比對有 --channels 的進程：互動 session 的 stream-json worker 不會搶 TG 槽
$lastChannelProc = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
    Where-Object { $_.CommandLine -match '--channels' } |
    Sort-Object CreationDate -Descending |
    Select-Object -First 1

if ($botProc -and $lastChannelProc -and ($botProc.ProcessId -ne $lastChannelProc.ProcessId)) {
    $stealerTime = $lastChannelProc.CreationDate.ToString('HH:mm')
    WLog "[TG-SLOT-STOLEN] Bot PID $($botProc.ProcessId) started at $($botProc.CreationDate.ToString('HH:mm')), but PID $($lastChannelProc.ProcessId) started at $stealerTime took the slot. Restarting bot..."
    Kill-Bot
    if (Start-Bot) {
        WLog "[TG-SLOT-RESTORED] Bot restarted and now holds TG slot."
        # 槽被搶是開新 Claude 視窗的正常副作用，靜默修好即可（不發通知）
    } else {
        WLog "[TG-SLOT-RESTORE-FAIL] Bot restart failed."
        Send-Telegram "⚠️ TG 接收槽被搶，Bot 重啟失敗，請手動雙擊 E:\claude\Claude Telegram.bat（$(Get-Date -Format 'HH:mm')）"
    }
    exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Layer 3：結構健康 — Bot 活著但收訊進程(bun poller)不在 → 殭屍 → 重啟
# 不再用心跳猜額度：沒人傳訊時心跳本來就停，重啟也救不了額度，只會洗版。
# ─────────────────────────────────────────────────────────────────────────────

# 剛啟動的 bot 給 15 分鐘把 bun 拉起來，避免 startup 空窗誤判 + 防重啟迴圈
$botAgeMin = (New-TimeSpan -Start $botProc.CreationDate -End (Get-Date)).TotalMinutes
if ($botAgeMin -lt 15) {
    WLog "[STARTING] Bot up $([math]::Round($botAgeMin,1))min, skip poller check."
    exit 0
}

# telegram bun(server.ts) 必須存在且是 bot 的子孫進程
$serverBun = Get-CimInstance Win32_Process -Filter "Name='bun.exe'" |
    Where-Object { $_.CommandLine -match 'server\.ts' } |
    Select-Object -First 1

$bunHealthy = $false
if ($serverBun) {
    $p = $serverBun.ParentProcessId
    for ($i = 0; $i -lt 8 -and $p; $i++) {
        if ($p -eq $botProc.ProcessId) { $bunHealthy = $true; break }
        $anc = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue
        if (-not $anc) { break }
        $p = $anc.ParentProcessId
    }
}

if (-not $bunHealthy) {
    WLog "[ZOMBIE] Bot alive but telegram poller(bun) missing/orphaned. Restarting..."
    Kill-Bot
    if (Start-Bot) {
        WLog "[ZOMBIE-RESTORED] Bot restarted with healthy poller."
        Send-Telegram "🔧 Telegram Bot 收訊進程異常（poller 不在），守護已自動重啟（$(Get-Date -Format 'HH:mm')）"
    } else {
        WLog "[ZOMBIE-RESTORE-FAIL] Restart failed."
        Send-Telegram "⚠️ Telegram Bot 收訊進程異常且重啟失敗，請手動雙擊 E:\claude\Claude Telegram.bat（$(Get-Date -Format 'HH:mm')）"
    }
    exit 0
}

# 結構健康 → 靜默結束（心跳停滯不代表壞）
exit 0
