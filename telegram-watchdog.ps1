# Telegram Bot 守護腳本（每 10 分鐘由排程觸發）
# 只看「結構健康」，不用心跳猜額度（安靜沒人傳訊時心跳本來就停，不代表壞）：
#   Layer 1：Bot 進程死了 → 自動重啟，失敗則 npm 修復
#   Layer 2：偵測到多個 --channels 進程（重複 bot）→ 全清後重啟一個
#   Layer 3：Bot 活著但沒有屬於它的收訊進程(bun poller) → 殭屍 → 重啟
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

function Get-ChannelBots {
    return @(Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
        Where-Object { $_.CommandLine -match '--channels' })
}

function Test-BotAlive {
    # 重試 3 次：Win32_Process.CommandLine 會間歇回 null，一次查不到不代表真的死
    # 注意：Get-ChannelBots 回傳單一元素會被 PowerShell 解包成純量，call site 必須 @() 重新包陣列
    for ($i = 0; $i -lt 3; $i++) {
        if (@(Get-ChannelBots).Count -ge 1) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

# 有任一 server.ts bun 是這個 bot 的子孫 → 收訊進程健康（不取 -First 1，避免孤兒 bun 誤判）
# 重試 3 次：CommandLine 間歇 null 會讓 bun 查不到，一次沒查到不代表真的沒 poller
function Test-BotHasPoller([int]$BotPid) {
    for ($retry = 0; $retry -lt 3; $retry++) {
        $buns = @(Get-CimInstance Win32_Process -Filter "Name='bun.exe'" |
            Where-Object { $_.CommandLine -match 'server\.ts' })
        foreach ($b in $buns) {
            $p = $b.ParentProcessId
            for ($i = 0; $i -lt 8 -and $p; $i++) {
                if ($p -eq $BotPid) { return $true }
                $anc = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue
                if (-not $anc) { break }
                $p = $anc.ParentProcessId
            }
        }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

function Kill-Bot {
    # 殺 --channels bot
    Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
        Where-Object { $_.CommandLine -match '--channels' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    # 一併清掉 telegram bun，避免孤兒 bun 佔住接收槽
    Get-CimInstance Win32_Process -Filter "Name='bun.exe'" |
        Where-Object { $_.CommandLine -match 'server\.ts' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 3
}

function Start-Bot {
    Start-Process 'cmd.exe' -ArgumentList '/c', '"E:\claude\Claude Telegram.bat"' -WindowStyle Minimized
    Start-Sleep -Seconds 60
    return (Test-BotAlive)
}

# ─────────────────────────────────────────────────────────────────────────────
# 防併發：已有另一個 watchdog 或 daily-restart 在跑 → 讓位（避免兩者同時重啟的 race，
# 例如 06:00 daily-restart 殺 bot、watchdog 同刻判 [DEAD] 也去重啟）
# ─────────────────────────────────────────────────────────────────────────────
$others = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -match 'telegram-watchdog|telegram-daily-restart' })
if ($others.Count -gt 0) {
    WLog "[SKIP] Another watchdog/daily-restart running (PID $($others[0].ProcessId)). Yielding."
    exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Layer 1：Bot 進程死了 → 重啟
# ─────────────────────────────────────────────────────────────────────────────

if (-not (Test-BotAlive)) {

    WLog "[DEAD] Bot session not found. Restarting..."

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
# Layer 2：多個 --channels 進程（重複 bot）→ 全清後重啟一個
# 用 count 判斷，不依賴 Get-CimInstance 回傳順序
# ─────────────────────────────────────────────────────────────────────────────

$channelBots = @(Get-ChannelBots)

# 防護：Layer 1 已確認 bot 活著，這裡若查到 0 個必是 WMI 瞬時 null → 靜默結束，別誤動作
if ($channelBots.Count -eq 0) {
    WLog "[TRANSIENT] Bot alive per Layer1 but query returned 0 (WMI null). Skipping."
    exit 0
}

if ($channelBots.Count -gt 1) {
    WLog "[DUP-BOT] $($channelBots.Count) --channels processes found. Killing all and restarting one..."
    Kill-Bot
    if (Start-Bot) {
        WLog "[DUP-BOT-RESTORED] Single bot restored."
    } else {
        WLog "[DUP-BOT-FAIL] Restart failed."
        Send-Telegram "⚠️ 偵測到多個 Bot 進程，清理後重啟失敗，請手動雙擊 E:\claude\Claude Telegram.bat（$(Get-Date -Format 'HH:mm')）"
    }
    exit 0
}

$botProc = $channelBots[0]

# ─────────────────────────────────────────────────────────────────────────────
# Layer 3：結構健康 — Bot 活著但沒有屬於它的收訊進程(bun poller) → 殭屍 → 重啟
# 不再用心跳猜額度：沒人傳訊時心跳本來就停，重啟也救不了額度，只會洗版。
# ─────────────────────────────────────────────────────────────────────────────

# 剛啟動的 bot 給 15 分鐘把 bun 拉起來，避免 startup 空窗誤判 + 防重啟迴圈
$botAgeMin = (New-TimeSpan -Start $botProc.CreationDate -End (Get-Date)).TotalMinutes
if ($botAgeMin -lt 15) {
    WLog "[STARTING] Bot up $([math]::Round($botAgeMin,1))min, skip poller check."
    exit 0
}

if (-not (Test-BotHasPoller $botProc.ProcessId)) {
    WLog "[ZOMBIE] Bot alive but no telegram poller(bun) belongs to it. Restarting..."
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
