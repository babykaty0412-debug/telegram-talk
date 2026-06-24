# Telegram Bot 守護腳本（每 10 分鐘由排程觸發）
# 功能：
#   1. Bot 進程死了 → 自動重啟，失敗則嘗試 npm 修復
#   2. Bot 活著但心跳停滯 (>=2h) → 疑似額度耗盡 → 推 TG 通知 + 等 5h 後自動重啟
#   3. 額度恢復（心跳更新）→ 推 TG "已恢復"
#   4. TG 接收槽被新 session 搶走 → 靜默重啟奪回（不發通知）

$ErrorActionPreference = 'Continue'
$logFile          = 'E:\claude\telegram-watchdog.log'
$heartbeatFile    = 'E:\claude\bot-heartbeat.txt'
$quotaStateFile   = 'E:\claude\bot-quota-suspected.txt'
$lastRestartFile  = 'E:\claude\bot-quota-restarted.txt'
$quotaWindowHours     = 5
$heartbeatStaleHours  = 2
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
# Layer 2：進程活著 → 確認 TG 接收槽沒被搶
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
        # 槽被搶是開新 Claude 視窗的正常副作用，靜默修好即可（不發通知、不動心跳）
    } else {
        WLog "[TG-SLOT-RESTORE-FAIL] Bot restart failed."
        Send-Telegram "⚠️ TG 接收槽被搶，Bot 重啟失敗，請手動雙擊 E:\claude\Claude Telegram.bat（$(Get-Date -Format 'HH:mm')）"
    }
    exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Layer 3：接收槽正常 → 檢查心跳
# ─────────────────────────────────────────────────────────────────────────────

if (-not (Test-Path $heartbeatFile)) {
    exit 0
}

$lastBeat   = [datetime](Get-Content $heartbeatFile -Encoding UTF8 -TotalCount 1)
$staleHours = (New-TimeSpan -Start $lastBeat -End (Get-Date)).TotalHours

if ($staleHours -lt $heartbeatStaleHours) {
    # 心跳新鮮 → 確認是否從額度耗盡中恢復
    if (Test-Path $quotaStateFile) {
        Remove-Item $quotaStateFile -ErrorAction SilentlyContinue
        Remove-Item $lastRestartFile -ErrorAction SilentlyContinue
        WLog "[RECOVERED] Heartbeat fresh after quota suspicion. Bot resumed."
        Send-Telegram "✅ Telegram Bot 額度已恢復！Bot 已自動繼續（最後心跳：$($lastBeat.ToString('HH:mm'))）"
    }
    exit 0
}

WLog "[HEARTBEAT-STALE] Last beat: $($lastBeat.ToString('HH:mm')), stale: $([math]::Round($staleHours,1))h"

# ─────────────────────────────────────────────────────────────────────────────
# Layer 4：心跳停滯 ≥ 2h → 疑似額度耗盡
# ─────────────────────────────────────────────────────────────────────────────

if (-not (Test-Path $quotaStateFile)) {
    Set-Content $quotaStateFile (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8
    $estimatedReset = $lastBeat.AddHours($quotaWindowHours).ToString('HH:mm')
    WLog "[QUOTA?] Suspected quota exhaustion. Estimated reset: $estimatedReset"
    Send-Telegram "⏸️ Bot 進程活著，但 $([math]::Round($staleHours, 1)) 小時無回應`n疑似 Claude Pro 額度耗盡`n最後活躍：$($lastBeat.ToString('HH:mm'))，預計恢復：約 $estimatedReset`n額度恢復後守護排程將自動重啟 Bot"
    exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Layer 5：已通知過 → 等 5h 視窗後重啟（防無限循環：用獨立檔記錄上次重啟時間）
# ─────────────────────────────────────────────────────────────────────────────

$waitedHours = (New-TimeSpan -Start $lastBeat -End (Get-Date)).TotalHours

if ($waitedHours -ge $quotaWindowHours) {

    # 防無限重啟：確認距上次重啟已滿 $quotaWindowHours
    if (Test-Path $lastRestartFile) {
        $lastRestartAt   = [datetime](Get-Content $lastRestartFile -Encoding UTF8 -TotalCount 1)
        $hoursSinceRestart = (New-TimeSpan -Start $lastRestartAt -End (Get-Date)).TotalHours
        if ($hoursSinceRestart -lt $quotaWindowHours) {
            WLog "[WAITING-AFTER-RESTART] Last restart $([math]::Round($hoursSinceRestart,1))h ago. Next retry at $($lastRestartAt.AddHours($quotaWindowHours).ToString('HH:mm'))."
            exit 0
        }
    }

    WLog "[QUOTA-RETRY] $([math]::Round($waitedHours,1))h passed. Killing and restarting..."
    Kill-Bot
    if (Start-Bot) {
        Set-Content $lastRestartFile (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8
        WLog "[QUOTA-RESTART] Bot restarted after quota window."
        Send-Telegram "🔄 Claude Pro 額度視窗已過，Bot 已自動重啟（$(Get-Date -Format 'HH:mm')）"
    } else {
        WLog "[QUOTA-RESTART-FAIL] Bot restart failed after quota window."
        Send-Telegram "⚠️ 額度視窗已過但 Bot 重啟失敗，請手動雙擊 E:\claude\Claude Telegram.bat（$(Get-Date -Format 'HH:mm')）"
    }

} else {

    WLog "[WAITING] Quota window: $([math]::Round($waitedHours,1))h / $quotaWindowHours h. Waiting..."
}
