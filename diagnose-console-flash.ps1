# diagnose-console-flash.ps1
# 診斷「畫面每隔一段時間閃黑框 / 藍框」的元凶。
#
# 兩層偵測（缺一不可）：
#   1. 可見視窗（EnumWindows + IsWindowVisible）
#      ← 這才是「真正會閃出來的東西」。務必優先看這個排行。
#   2. 新建 conhost.exe
#      ← console 物件被建立。注意：有 conhost 不代表視窗看得見
#        （用 wscript 隱藏啟動後 conhost 照樣會生，但從未顯示）。
#
# 用法：
#   & E:\claude\diagnose-console-flash.ps1              # 預設 3 分鐘
#   & E:\claude\diagnose-console-flash.ps1 -Minutes 11  # 涵蓋 10 分鐘週期的排程
#
# 先問顏色可以少繞很多路：藍底 = PowerShell、黑底 = cmd。
# 已知元凶與解法見 README「疑難排解」。

param(
    [double]$Minutes = 3,
    [string]$OutFile = "$env:TEMP\console-flash-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

$ErrorActionPreference = 'SilentlyContinue'

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class FlashWin {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int c);
  [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out uint pid);
  public static string Title(IntPtr h) {
    int n = GetWindowTextLength(h);
    if (n == 0) return "";
    StringBuilder sb = new StringBuilder(n + 1);
    GetWindowText(h, sb, sb.Capacity);
    return sb.ToString();
  }
}
"@

# console 程式清單（conhost 是關鍵：每個 console 視窗都會生一個）
$watch = @('conhost','cmd','powershell','pwsh','python','pythonw',
           'wscript','cscript','node','docker','docker-compose')

$scanWin = {
    $cur = @{}
    $cb = [FlashWin+EnumProc]{
        param($h, $l)
        if ([FlashWin]::IsWindowVisible($h)) { $cur[$h] = $true }
        return $true
    }
    [void][FlashWin]::EnumWindows($cb, [IntPtr]::Zero)
    return $cur
}

$seenProc = @{}
$seenWin  = @{}
$procHits = @{}
$winHits  = @{}

# 基準線：監控開始前就存在的不算
foreach ($p in Get-Process -Name $watch) { $seenProc[$p.Id] = $true }
foreach ($h in (& $scanWin).Keys)        { $seenWin[$h] = $true }

"=== console 閃爍診斷 開始 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')（監控 $Minutes 分鐘）===" |
    Tee-Object -FilePath $OutFile
Write-Host "記錄檔：$OutFile`n"

$end = (Get-Date).AddMinutes($Minutes)
while ((Get-Date) -lt $end) {

    # ── 1. 可見視窗（真正會閃的）──
    foreach ($h in (& $scanWin).Keys) {
        if ($seenWin.ContainsKey($h)) { continue }
        $seenWin[$h] = $true
        $wpid = 0
        [void][FlashWin]::GetWindowThreadProcessId($h, [ref]$wpid)
        $wpr = Get-Process -Id $wpid
        $wn  = if ($wpr) { $wpr.Name } else { '(已結束)' }
        $winHits[$wn] = [int]$winHits[$wn] + 1
        "[{0}] * 可見視窗 {1}(pid={2}) 標題='{3}'" -f `
            (Get-Date -Format 'HH:mm:ss.fff'), $wn, $wpid, [FlashWin]::Title($h) |
            Tee-Object -FilePath $OutFile -Append
    }

    # ── 2. 新建 console 行程 ──
    foreach ($p in Get-Process -Name $watch) {
        if ($seenProc.ContainsKey($p.Id)) { continue }
        $seenProc[$p.Id] = $true
        $ci = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)"
        if (-not $ci) { continue }
        $pp    = Get-CimInstance Win32_Process -Filter "ProcessId=$($ci.ParentProcessId)"
        $pName = if ($pp) { $pp.Name } else { '(已結束)' }
        $procHits[$pName] = [int]$procHits[$pName] + 1
        "[{0}] {1}(pid={2})`n    父: {3}({4})`n    父指令: {5}" -f `
            (Get-Date -Format 'HH:mm:ss.fff'), $p.Name, $p.Id,
            $pName, $ci.ParentProcessId, $(if ($pp) { $pp.CommandLine } else { '' }) |
            Tee-Object -FilePath $OutFile -Append
    }

    Start-Sleep -Milliseconds 200
}

"`n=== 可見視窗排行（這才是真正會閃的東西）===" | Tee-Object -FilePath $OutFile -Append
if ($winHits.Count -eq 0) {
    "  （無）監控期間沒有任何新的可見視窗 → 畫面應該是乾淨的" | Tee-Object -FilePath $OutFile -Append
} else {
    $winHits.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        "{0,6} 次  <-  {1}" -f $_.Value, $_.Key | Tee-Object -FilePath $OutFile -Append
    }
}

"`n=== 新建 console 排行（參考用；有 conhost 不代表看得見）===" | Tee-Object -FilePath $OutFile -Append
if ($procHits.Count -eq 0) {
    "  （無）" | Tee-Object -FilePath $OutFile -Append
} else {
    $procHits.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        "{0,6} 次  <-  {1}" -f $_.Value, $_.Key | Tee-Object -FilePath $OutFile -Append
    }
}

"`n=== 結束 $(Get-Date -Format 'HH:mm:ss') ===" | Tee-Object -FilePath $OutFile -Append
