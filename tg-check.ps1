# TG health check — UserPromptSubmit hook
# 只在「真的壞」時提醒（反映專屬 bot 架構：bot 是獨立窗，訊息不進互動窗是正常的）。
# 純本地 WMI 檢查，不打網路（避免瞬時抖動誤報）。
# 重試 3 次防 CommandLine 間歇 null 造成假警報。

$bot = $null; $hasPoller = $false
for ($retry = 0; $retry -lt 3; $retry++) {
    $bot = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match '--channels' } | Select-Object -First 1
    if ($bot) {
        $buns = @(Get-CimInstance Win32_Process -Filter "Name='bun.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match 'server\.ts' })
        foreach ($b in $buns) {
            $p = $b.ParentProcessId
            for ($i = 0; $i -lt 8 -and $p; $i++) {
                if ($p -eq $bot.ProcessId) { $hasPoller = $true; break }
                $anc = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue
                if (-not $anc) { break }
                $p = $anc.ParentProcessId
            }
            if ($hasPoller) { break }
        }
    }
    if ($bot -and $hasPoller) { break }
    Start-Sleep -Milliseconds 400
}

$issues = @()
if (-not $bot) {
    $issues += "TG bot 進程不在（守護排程每 10 分鐘會自動重啟；要即刻恢復可手動跑 E:\claude\Claude Telegram.bat）"
} elseif (-not $hasPoller) {
    $issues += "TG bot 收訊進程(poller)不在（守護排程會自動重啟；bot 暫時收不到訊息）"
}

if ($issues.Count -gt 0) {
    $detail = $issues -join "; "
    $warning = "TG 狀態：$detail。回答使用者前先說明目前 bot 是否可用。"
    @{ hookSpecificOutput = @{ hookEventName = "UserPromptSubmit"; additionalContext = $warning } } | ConvertTo-Json -Compress
}
