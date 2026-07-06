# telegram-talk 一鍵診斷 — 出問題先跑這個
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File "<工具根>\diagnose.ps1"
# 會依序檢查 10 大項（軟體→檔案→secrets→設定→路徑→進程→排程→Telegram API→log）。
# 每個 ❌ 直接附修法；修不好就把「完整輸出」貼給 Claude 遠端診斷。
# 不會顯示 token 內容，輸出可安全貼上。加 -SkipNetwork 可跳過 Telegram API 檢查。

param([switch]$SkipNetwork)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$root = $PSScriptRoot
if (-not $root) { $root = Split-Path -Parent $MyInvocation.MyCommand.Path }

$script:failCount = 0
$script:warnCount = 0
function OK([string]$m)  { Write-Host "  [OK] $m" -ForegroundColor Green }
function BAD([string]$m, [string]$fix = '') {
    $script:failCount++
    Write-Host "  [X ] $m" -ForegroundColor Red
    if ($fix) { Write-Host "       修法：$fix" -ForegroundColor Yellow }
}
function WARN([string]$m) { $script:warnCount++; Write-Host "  [! ] $m" -ForegroundColor Yellow }
function INFO([string]$m) { Write-Host "       $m" -ForegroundColor Gray }
function SECTION([string]$t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗"
Write-Host "║  telegram-talk 一鍵診斷                  ║"
Write-Host "╚══════════════════════════════════════════╝"

# ─────────────────────────────────────────────
SECTION "0. 基本環境"
# ─────────────────────────────────────────────
INFO "時間        ：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
INFO "電腦 / 帳號 ：$env:COMPUTERNAME / $env:USERNAME"
INFO "工具根      ：$root"
INFO "USERPROFILE ：$env:USERPROFILE"
INFO "PowerShell  ：$($PSVersionTable.PSVersion)"

# ─────────────────────────────────────────────
SECTION "1. 必要軟體（node / bun / claude）"
# ─────────────────────────────────────────────
foreach ($tool in 'node', 'bun', 'claude') {
    $found = Get-Command $tool -ErrorAction SilentlyContinue
    if ($found) {
        $v = ''
        try { $v = (cmd /c "$tool --version 2>&1" | Select-Object -First 1) } catch {}
        if ($LASTEXITCODE -eq 0 -and $v) {
            OK "$tool 可用（$v）"
        } else {
            BAD "$tool 找得到但執行失敗：$v" $(if ($tool -eq 'claude') { '跑 npm install -g @anthropic-ai/claude-code 重裝' } else { "重裝 $tool 或檢查 PATH" })
        }
    } else {
        $fix = switch ($tool) {
            'node'   { '裝 Node.js ≥ 22（建議 nvm-windows），並確認在 PATH' }
            'bun'    { '裝 bun（powershell -c "irm bun.sh/install.ps1 | iex"），bot 收訊靠它' }
            'claude' { 'npm install -g @anthropic-ai/claude-code，裝完開新視窗再試' }
        }
        BAD "$tool 不在 PATH，找不到指令" $fix
    }
}

# ─────────────────────────────────────────────
SECTION "2. 檔案就位（repo 檔 + hook）"
# ─────────────────────────────────────────────
$repoFiles = @('Claude Telegram.bat', 'bot-settings.json', 'telegram-watchdog.ps1',
               'telegram-daily-restart.ps1', 'bot-health.ps1', 'tg-check.ps1')
foreach ($f in $repoFiles) {
    if (Test-Path (Join-Path $root $f)) { OK $f }
    else { BAD "$f 不在 $root" "git pull 或重新 clone repo 到工具根" }
}
$hookPath = Join-Path $env:USERPROFILE '.claude\hooks\tg-check.ps1'
if (Test-Path $hookPath) { OK "hook 已裝（$hookPath）" }
else { BAD "hook 未安裝：$hookPath 不存在" "把 repo 的 tg-check.ps1 複製過去：Copy-Item `"$root\tg-check.ps1`" `"$hookPath`"（hooks 資料夾不存在先建）" }

# ─────────────────────────────────────────────
SECTION "3. 機密檔（token / 允許名單）"
# ─────────────────────────────────────────────
$envFile = Join-Path $env:USERPROFILE '.claude\channels\telegram\.env'
$token = $null
if (Test-Path $envFile) {
    $token = Get-Content $envFile -Encoding UTF8 |
        Where-Object { $_ -match '^\s*TELEGRAM_BOT_TOKEN=(.+)$' } |
        ForEach-Object { $matches[1].Trim() } | Select-Object -First 1
    if ($token -and $token -match '^\d{6,}:[\w-]{30,}$') {
        OK ".env 存在且 token 格式正確（長度 $($token.Length)，內容不顯示）"
    } elseif ($token) {
        BAD ".env 有 TELEGRAM_BOT_TOKEN 但格式不像 bot token（應為 數字:35字英數）" "跟 @BotFather 要 token 重貼，整行格式：TELEGRAM_BOT_TOKEN=<token>，等號前後不留空格"
    } else {
        BAD ".env 存在但沒有 TELEGRAM_BOT_TOKEN= 開頭的行" "檔案內容應只有一行：TELEGRAM_BOT_TOKEN=<你的token>"
    }
} else {
    BAD ".env 不存在：$envFile" "手動建立（機密不在 git）：一行 TELEGRAM_BOT_TOKEN=<你的token>。token 在舊機同路徑或問 @BotFather"
}
$accessFile = Join-Path $env:USERPROFILE '.claude\channels\telegram\access.json'
if (Test-Path $accessFile) {
    try {
        $access = Get-Content $accessFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $allowCount = @($access.allowFrom).Count
        if ($allowCount -ge 1) { OK "access.json 正常（dmPolicy=$($access.dmPolicy)，允許 $allowCount 人）" }
        else { BAD "access.json 的 allowFrom 是空的 → 誰都不能觸發 bot" "把你的 chat_id 加進 allowFrom 陣列" }
    } catch {
        BAD "access.json 不是合法 JSON：$($_.Exception.Message)" "照 README §3 範例重建"
    }
} else {
    BAD "access.json 不存在：$accessFile" '手動建立，範例：{ "dmPolicy": "allowlist", "allowFrom": ["<你的chat_id>"], "groups": {}, "pending": {} }'
}

# ─────────────────────────────────────────────
SECTION "4. ~\.claude\settings.json（防搶槽 + 權限 + hook）"
# ─────────────────────────────────────────────
$settingsFile = Join-Path $env:USERPROFILE '.claude\settings.json'
if (Test-Path $settingsFile) {
    $settingsRaw = Get-Content $settingsFile -Raw -Encoding UTF8
    $settings = $null
    try { $settings = $settingsRaw | ConvertFrom-Json } catch {
        BAD "settings.json 不是合法 JSON：$($_.Exception.Message)" "用 VS Code 開啟找紅字修掉（常見：多逗號、少引號）"
    }
    if ($settings) {
        # 4a. 全域 telegram plugin 必須是 false（互動 session 不搶槽）
        $tgEnabled = $null
        if ($settings.enabledPlugins) { $tgEnabled = $settings.enabledPlugins.'telegram@claude-plugins-official' }
        if ($tgEnabled -eq $false) { OK "enabledPlugins.telegram = false（互動 session 不搶槽，正確）" }
        elseif ($tgEnabled -eq $true) { BAD "enabledPlugins.telegram = true → 每個互動 session 都會搶 bot 的接收槽！" "改成 false（bot 靠 --settings 單獨開啟，不受影響）" }
        else { WARN "settings.json 沒設 enabledPlugins.telegram = false（若 plugin 已裝，互動 session 可能搶槽），建議照 README §4 補上" }
        # 4b. 權限
        $needPerms = @('mcp__plugin_telegram_telegram__reply')
        $allowList = @()
        if ($settings.permissions -and $settings.permissions.allow) { $allowList = @($settings.permissions.allow) }
        $missing = @($needPerms | Where-Object { $allowList -notcontains $_ })
        if ($missing.Count -eq 0) { OK "permissions.allow 含 telegram reply（bot 回訊不被攔）" }
        else { WARN "permissions.allow 缺 $($missing -join ', ') → bot 可能收得到但回不了，照 README §4 補 5 條 allow" }
        # 4c. hook 有掛
        if ($settingsRaw -match 'tg-check\.ps1') { OK "UserPromptSubmit hook 已掛 tg-check.ps1" }
        else { WARN "settings.json 沒掛 tg-check hook（非致命，只是壞了不會主動提醒），照 README §4 補" }
    }
} else {
    BAD "settings.json 不存在：$settingsFile" "照 README §4 建立（enabledPlugins.telegram=false + 5 條 allow + hook）"
}

# ─────────────────────────────────────────────
SECTION "5. telegram plugin 已安裝進 cache"
# ─────────────────────────────────────────────
$pluginRoot = Join-Path $env:USERPROFILE '.claude\plugins'
if (Test-Path $pluginRoot) {
    $hits = @(Get-ChildItem $pluginRoot -Recurse -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^telegram$' -and $_.FullName -match 'claude-plugins-official' })
    if ($hits.Count -eq 0) {
        # 寬鬆再找一次（cache 目錄結構可能隨版本變）
        $hits = @(Get-ChildItem $pluginRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'telegram' })
    }
    if ($hits.Count -ge 1) { OK "plugin cache 找到 telegram（$($hits[0].FullName)）" }
    else { BAD "plugins 目錄裡找不到 telegram plugin" "開一個 claude 互動 session，跑 /plugin 安裝 telegram@claude-plugins-official（裝一次即可）" }
} else {
    BAD "plugins 目錄不存在：$pluginRoot" "開 claude 跑 /plugin 裝 telegram@claude-plugins-official；或從舊機複製整個 .claude\plugins"
}

# ─────────────────────────────────────────────
SECTION "6. 硬編碼路徑（搬機最常炸的點）"
# ─────────────────────────────────────────────
$oldRoot = 'E:\claude'; $oldUser = 'C:\Users\21030502'
$rootChanged = ($root -ne $oldRoot)
$userChanged = ($env:USERPROFILE -ne $oldUser)
if (-not $rootChanged -and -not $userChanged) {
    OK "本機路徑與舊機相同（$oldRoot / $oldUser），硬編碼路徑不用改"
} else {
    INFO "本機工具根=$root、家目錄=$env:USERPROFILE（與舊機不同 → 檢查殘留舊路徑）"
    $patterns = @()
    if ($rootChanged) { $patterns += [regex]::Escape($oldRoot) }
    if ($userChanged) { $patterns += [regex]::Escape($oldUser) }
    $pattern = $patterns -join '|'
    $stale = @()
    foreach ($f in $repoFiles) {
        $p = Join-Path $root $f
        if (Test-Path $p) {
            $hit = Select-String -Path $p -Pattern $pattern -List -ErrorAction SilentlyContinue
            if ($hit) { $stale += $f }
        }
    }
    if ($stale.Count -eq 0) { OK "腳本裡沒有殘留舊路徑" }
    else { BAD "這些檔案還寫著舊路徑（$oldRoot / $oldUser）：$($stale -join '、')" "照 MIGRATION.md §4f 的批次替換腳本跑一遍（會保 UTF-8 BOM），或手動 find-replace" }
}

# ─────────────────────────────────────────────
SECTION "7. 進程狀態（bot / poller / 連線）"
# ─────────────────────────────────────────────
# 重試 3 次：Win32_Process.CommandLine 會間歇回 null（見 README 踩雷區）
$bots = @()
for ($retry = 0; $retry -lt 3; $retry++) {
    $bots = @(Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match '--channels' })
    if ($bots.Count -ge 1) { break }
    Start-Sleep -Milliseconds 500
}
if ($bots.Count -eq 0) {
    BAD "bot 進程（claude --channels）不在跑" "雙擊「$root\Claude Telegram.bat」啟動；守護排程正常的話 10 分鐘內也會自動拉起"
} elseif ($bots.Count -gt 1) {
    BAD "有 $($bots.Count) 個 --channels 進程 → 互搶接收槽" "等守護排程清理，或手動全關後只開一個 Claude Telegram.bat"
} else {
    $bot = $bots[0]
    OK "bot 進程 1 個（PID $($bot.ProcessId)，啟動 $($bot.CreationDate.ToString('MM-dd HH:mm'))）"
    # bun poller 是否為 bot 子孫
    $botBun = $null
    for ($retry = 0; $retry -lt 3 -and -not $botBun; $retry++) {
        $buns = @(Get-CimInstance Win32_Process -Filter "Name='bun.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match 'server\.ts' })
        foreach ($b in $buns) {
            $p = $b.ParentProcessId
            for ($i = 0; $i -lt 8 -and $p; $i++) {
                if ($p -eq $bot.ProcessId) { $botBun = $b; break }
                $anc = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue
                if (-not $anc) { break }
                $p = $anc.ParentProcessId
            }
            if ($botBun) { break }
        }
        if (-not $botBun) { Start-Sleep -Milliseconds 500 }
    }
    $botAgeMin = (New-TimeSpan -Start $bot.CreationDate -End (Get-Date)).TotalMinutes
    if ($botBun) {
        OK "收訊進程（bun poller）健在（PID $($botBun.ProcessId)）"
        $conns = Get-NetTCPConnection -OwningProcess $botBun.ProcessId -State Established -ErrorAction SilentlyContinue |
            Where-Object { $_.RemotePort -eq 443 }
        if ($conns) { OK "bun 有 443 連線 → 正在 poll Telegram" }
        else { WARN "bun 目前沒有 443 連線（poll 間隔中屬正常，連跑兩次都這樣才可疑）" }
    } elseif ($botAgeMin -lt 15) {
        WARN "bot 剛啟動 $([math]::Round($botAgeMin,1)) 分鐘，poller 可能還沒拉起來，15 分鐘後再跑一次診斷"
    } else {
        BAD "bot 活著但沒有屬於它的 bun poller → 殭屍，收不到訊息" "等守護排程自動重啟，或手動：關掉 bot 視窗後重開 Claude Telegram.bat"
    }
}

# ─────────────────────────────────────────────
SECTION "8. Windows 排程（守護 + 每日重啟）"
# ─────────────────────────────────────────────
foreach ($taskName in 'Telegram-Bot守護', 'Telegram-Bot每日六點重啟') {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $task) {
        BAD "排程「$taskName」不存在" "用系統管理員 PowerShell 照 README §6 的指令建立"
        continue
    }
    $scriptPathOk = $true
    $argStr = ($task.Actions | ForEach-Object { $_.Arguments }) -join ' '
    if ($argStr -match '-File\s+"?([^"]+\.ps1)"?') {
        $taskScript = $matches[1]
        if (-not (Test-Path $taskScript)) {
            $scriptPathOk = $false
            BAD "排程「$taskName」指到不存在的腳本：$taskScript" "刪掉排程重建，路徑填 $root 下的對應 .ps1"
        }
    }
    if ($scriptPathOk) {
        $tinfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
        $lastRun = 'never'; $lastResult = ''
        if ($tinfo) {
            if ($tinfo.LastRunTime -and $tinfo.LastRunTime.Year -gt 2000) { $lastRun = $tinfo.LastRunTime.ToString('MM-dd HH:mm') }
            $lastResult = $tinfo.LastTaskResult
        }
        if ($task.State -eq 'Disabled') {
            BAD "排程「$taskName」被停用" "Task Scheduler 右鍵啟用，或 Enable-ScheduledTask -TaskName '$taskName'"
        } elseif ($lastResult -ne 0 -and $lastResult -ne 267011 -and $lastResult -ne '') {
            # 267011 = 0x41303 尚未跑過
            WARN "排程「$taskName」存在（上次跑 $lastRun）但 LastTaskResult=$lastResult（0 才是成功）→ 看 $root\telegram-watchdog.log 找原因"
        } else {
            OK "排程「$taskName」存在且正常（狀態 $($task.State)，上次跑 $lastRun）"
        }
    }
}

# ─────────────────────────────────────────────
SECTION "9. Telegram API（token 有效性 / webhook 佔用）"
# ─────────────────────────────────────────────
if ($SkipNetwork) {
    INFO "（-SkipNetwork：略過）"
} elseif (-not $token) {
    INFO "（沒有 token，略過 — 先修第 3 項）"
} else {
    try {
        $me = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/getMe" -TimeoutSec 10
        if ($me.ok) { OK "token 有效，bot 帳號：@$($me.result.username)" }
        else { BAD "getMe 回傳異常：$($me | ConvertTo-Json -Compress)" "跟 @BotFather 確認 token" }
    } catch {
        $msg = $_.Exception.Message
        if ($msg -match '401') { BAD "token 無效（401 Unauthorized）" "跟 @BotFather 重新拿 token，更新 .env" }
        else { BAD "連不上 Telegram API：$msg" "檢查網路 / 防火牆 / proxy；台灣一般不用 VPN" }
    }
    try {
        $wh = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/getWebhookInfo" -TimeoutSec 10
        if ($wh.ok) {
            if ($wh.result.url) {
                BAD "這個 token 設了 webhook（$($wh.result.url)）→ polling 模式永遠收不到訊息！" "跑一次：Invoke-RestMethod -Uri `"https://api.telegram.org/bot<token>/deleteWebhook`" 後重啟 bot"
            } else {
                OK "沒有 webhook 佔用（polling 模式正確）"
                if ($wh.result.pending_update_count -gt 0) { INFO "有 $($wh.result.pending_update_count) 則未取訊息排隊中（bot 恢復後會補收）" }
            }
        }
    } catch { WARN "getWebhookInfo 失敗：$($_.Exception.Message)" }
}

# ─────────────────────────────────────────────
SECTION "10. 守護 log（最近 12 行）"
# ─────────────────────────────────────────────
$logFile = Join-Path $root 'telegram-watchdog.log'
if (Test-Path $logFile) {
    Get-Content $logFile -Encoding UTF8 -Tail 12 | ForEach-Object { INFO $_ }
} else {
    INFO "（$logFile 不存在 — 守護排程還沒跑過，或路徑不對）"
}

# ─────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════ 診斷結果 ═══════════════" -ForegroundColor Cyan
if ($script:failCount -eq 0 -and $script:warnCount -eq 0) {
    Write-Host "  全部通過！bot 應該正常。手機發訊測試最準。" -ForegroundColor Green
} elseif ($script:failCount -eq 0) {
    Write-Host "  沒有致命問題，但有 $($script:warnCount) 個警告（見上方 [! ]）。" -ForegroundColor Yellow
} else {
    Write-Host "  發現 $($script:failCount) 個問題（[X ]）、$($script:warnCount) 個警告（[! ]）。" -ForegroundColor Red
    Write-Host "  由上而下修（前面的問題常是後面的根因）。" -ForegroundColor Yellow
    Write-Host "  修不動 → 把這整份輸出全選複製，貼給 Claude。" -ForegroundColor Yellow
}
Write-Host ""
if ($script:failCount -gt 0) { exit 1 } else { exit 0 }
