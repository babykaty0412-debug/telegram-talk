# diagnose-console-flash.ps1
# 診斷「畫面每隔一段時間閃黑框/黑影」的元凶。
#
# 原理：Windows 每建立一個 console 視窗就會生一個 conhost.exe。
#       只要抓「新出現的 conhost 的父行程是誰」，就能直接指認元凶，
#       不必靠猜（猜錯會改到無辜的排程，白繞好幾圈）。
#
# 用法：
#   & E:\claude\diagnose-console-flash.ps1              # 預設監控 3 分鐘
#   & E:\claude\diagnose-console-flash.ps1 -Minutes 11  # 想涵蓋 10 分鐘週期的排程就設 11
#
# 讀法：看輸出末尾的「元凶排行」。同一個父行程高頻出現 = 就是它。
#       時間戳的間隔就是它的週期（每 10 秒 / 每 10 分鐘…），可用來對照排程設定。

param(
    [int]$Minutes = 3,
    [string]$OutFile = "$env:TEMP\console-flash-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

$ErrorActionPreference = 'SilentlyContinue'

# conhost = console 視窗宿主，出現即代表有視窗被畫出來（即使瞬間關閉）
# 其餘為常見的 console 程式，一併記錄以便追鏈
$watch = @('conhost','cmd','powershell','pwsh','python','pythonw',
           'wscript','cscript','node','docker','docker-compose')

$seen    = @{}
$culprit = @{}   # 父行程 → 次數

# 先記下既有行程，避免把「監控開始前就在跑的」誤報成新事件
foreach ($p in Get-Process -Name $watch) { $seen[$p.Id] = $true }

$header = "=== console 閃爍診斷 開始 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')（監控 $Minutes 分鐘）==="
$header | Tee-Object -FilePath $OutFile
Write-Host "記錄檔：$OutFile`n"

$end = (Get-Date).AddMinutes($Minutes)
while ((Get-Date) -lt $end) {
    foreach ($p in Get-Process -Name $watch) {
        if ($seen.ContainsKey($p.Id)) { continue }
        $seen[$p.Id] = $true

        $ci = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)"
        if (-not $ci) { continue }

        $pp     = Get-CimInstance Win32_Process -Filter "ProcessId=$($ci.ParentProcessId)"
        $pName  = if ($pp) { $pp.Name } else { '(已結束)' }
        $key    = "$pName"
        $culprit[$key] = [int]$culprit[$key] + 1

        $line = "[{0}] {1}(pid={2})`n    父: {3}({4})`n    父指令: {5}" -f `
                (Get-Date -Format 'HH:mm:ss.fff'), $p.Name, $p.Id,
                $pName, $ci.ParentProcessId, $(if ($pp) { $pp.CommandLine } else { '' })
        $line | Tee-Object -FilePath $OutFile -Append
    }
    Start-Sleep -Milliseconds 200
}

"`n=== 元凶排行（新建 console 次數）===" | Tee-Object -FilePath $OutFile -Append
$culprit.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    "{0,6} 次  ←  {1}" -f $_.Value, $_.Key | Tee-Object -FilePath $OutFile -Append
}
"`n=== 結束 $(Get-Date -Format 'HH:mm:ss') ===" | Tee-Object -FilePath $OutFile -Append
