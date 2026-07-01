# TG bot 健康檢查 — 一眼判斷是否正常
# 結構檢查（不需 bot 回覆、不耗額度），抓「搶槽 / 殭屍」failure mode
# exit 0 = 正常；exit 1 = 壞了

# 找「屬於 bot 的」telegram bun(server.ts)——不取第一個，避免孤兒 bun 誤判
function Get-BotBun($botPid) {
    $buns = @(Get-CimInstance Win32_Process -Filter "Name='bun.exe'" |
        Where-Object { $_.CommandLine -match 'server\.ts' })
    foreach ($b in $buns) {
        $p = $b.ParentProcessId
        for ($i = 0; $i -lt 8 -and $p; $i++) {
            if ($p -eq $botPid) { return $b }
            $anc = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue
            if (-not $anc) { break }
            $p = $anc.ParentProcessId
        }
    }
    return $null
}

# 偵測 bot + 它的 bun，重試 3 次防 CommandLine 間歇 null 造成假 ❌
$bots = @(); $bot = $null; $botBun = $null
for ($retry = 0; $retry -lt 3; $retry++) {
    $bots = @(Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
        Where-Object { $_.CommandLine -match '--channels' })
    $bot = $bots | Select-Object -First 1
    if ($bot) { $botBun = Get-BotBun $bot.ProcessId }
    if ($bot -and $botBun) { break }
    Start-Sleep -Milliseconds 500
}

$ok = $true
$reasons = @()

# 1. bot 進程存在且只有一個
if (-not $bot) {
    $ok = $false; $reasons += 'bot 進程（claude --channels）不存在 → 沒在跑'
} elseif ($bots.Count -gt 1) {
    $ok = $false; $reasons += "有 $($bots.Count) 個 --channels 進程（應只有 1）→ 重複 bot 會互搶接收槽"
}

# 2. bot 有屬於自己的 bun poller
if ($bot -and -not $botBun) {
    $ok = $false
    $reasons += 'bot 沒有屬於自己的收訊進程(bun server.ts) → 收不到訊息（殭屍或被搶槽）'
}

# 3. bun 有連到 Telegram（重試一次避免瞬時無連線誤報）
if ($botBun) {
    $connected = $false
    for ($try = 0; $try -lt 2 -and -not $connected; $try++) {
        if ($try -gt 0) { Start-Sleep -Seconds 2 }
        $conns = Get-NetTCPConnection -OwningProcess $botBun.ProcessId -State Established -ErrorAction SilentlyContinue |
            Where-Object { $_.RemoteAddress -match '^149\.154\.|^91\.108\.' }
        if ($conns) { $connected = $true }
    }
    if (-not $connected) { $ok = $false; $reasons += 'bun 無 Telegram 連線（149.154/91.108）→ 沒在 poll' }
}

# 4. bot.pid 對齊（非致命，僅提示）
$pidFile = 'C:\Users\21030502\.claude\channels\telegram\bot.pid'
if ((Test-Path $pidFile) -and $botBun) {
    $recorded = (Get-Content $pidFile -Encoding UTF8 -TotalCount 1).Trim()
    if ($recorded -ne "$($botBun.ProcessId)") {
        $reasons += "（提示）bot.pid=$recorded ≠ 實際 bun=$($botBun.ProcessId)"
    }
}

# 5. 心跳資訊（參考；可能因 bot 漏寫而偏舊，不列入致命判定）
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
if ($bot)    { Write-Host "bot PID  : $($bot.ProcessId)（啟動 $($bot.CreationDate.ToString('MM-dd HH:mm'))）" }
if ($botBun) { Write-Host "bun PID  : $($botBun.ProcessId)" }
Write-Host "心跳     : $hb（僅參考，bot 偶爾漏寫）"

if ($ok) { exit 0 } else { exit 1 }
