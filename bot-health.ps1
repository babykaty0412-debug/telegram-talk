# TG bot 健康檢查 — 一眼判斷是否正常
# 結構檢查（不需 bot 回覆、不耗額度），抓得到今晚的「搶槽」failure mode
# exit 0 = 正常；exit 1 = 壞了

$ok = $true
$reasons = @()

# 1. bot 進程（--channels）存在
$bot = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
    Where-Object { $_.CommandLine -match '--channels' } | Select-Object -First 1
if (-not $bot) { $ok = $false; $reasons += 'bot 進程（claude --channels）不存在 → 沒在跑' }

# 2. telegram bun（server.ts）存在 → 真正 poll Telegram 的進程
$serverBun = Get-CimInstance Win32_Process -Filter "Name='bun.exe'" |
    Where-Object { $_.CommandLine -match 'server\.ts' } | Select-Object -First 1
if (-not $serverBun) { $ok = $false; $reasons += 'telegram bun（server.ts）未運行 → 沒人 poll，收不到訊息' }

# 3. bun 父鏈必須屬於 bot（揪「被別的 session 搶槽」）
function Test-Ancestor($childPid, $targetPid) {
    $p = $childPid
    for ($i = 0; $i -lt 8 -and $p; $i++) {
        if ($p -eq $targetPid) { return $true }
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue
        if (-not $proc) { return $false }
        $p = $proc.ParentProcessId
    }
    return $false
}
if ($bot -and $serverBun) {
    if (-not (Test-Ancestor $serverBun.ProcessId $bot.ProcessId)) {
        $ok = $false
        $reasons += "telegram bun（PID $($serverBun.ProcessId)）不屬於 bot（PID $($bot.ProcessId)）→ 接收槽被別的 session 搶走"
    }
}

# 4. bun 有連到 Telegram 伺服器（證明真的在 poll）
if ($serverBun) {
    $conns = Get-NetTCPConnection -OwningProcess $serverBun.ProcessId -State Established -ErrorAction SilentlyContinue |
        Where-Object { $_.RemoteAddress -match '^149\.154\.|^91\.108\.' }
    if (-not $conns) { $ok = $false; $reasons += 'bun 無 Telegram 連線（149.154/91.108）→ 沒在 poll' }
}

# 5. bot.pid 對齊（非致命，僅提示）
$pidFile = 'C:\Users\21030502\.claude\channels\telegram\bot.pid'
if ((Test-Path $pidFile) -and $serverBun) {
    $recorded = (Get-Content $pidFile -Encoding UTF8 -TotalCount 1).Trim()
    if ($recorded -ne "$($serverBun.ProcessId)") {
        $reasons += "（提示）bot.pid=$recorded ≠ 實際 bun=$($serverBun.ProcessId)"
    }
}

# 6. 心跳資訊（參考；可能因 bot 漏寫而偏舊，不列入致命判定）
$hb = if (Test-Path 'E:\claude\bot-heartbeat.txt') {
    Get-Content 'E:\claude\bot-heartbeat.txt' -Encoding UTF8 -TotalCount 1
} else { '(無)' }

# ── 判定 ──
Write-Host ""
if ($ok) {
    Write-Host "✅ Bot 正常（結構完整、獨佔接收槽、有在 poll）"
} else {
    Write-Host "❌ Bot 壞了！原因："
}
$reasons | ForEach-Object { Write-Host "   - $_" }
Write-Host ""
if ($bot)       { Write-Host "bot PID  : $($bot.ProcessId)（啟動 $($bot.CreationDate.ToString('MM-dd HH:mm'))）" }
if ($serverBun) { Write-Host "bun PID  : $($serverBun.ProcessId)" }
Write-Host "心跳     : $hb（僅參考，bot 偶爾漏寫）"

if ($ok) { exit 0 } else { exit 1 }
