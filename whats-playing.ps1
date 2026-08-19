# whats-playing.ps1
# 找出「電腦突然有背景音、但我沒叫它播」是哪個程式在出聲。
#
# 原理：透過 Windows Core Audio API 列出所有音訊工作階段（音量混音程式看到的那些），
#       讀每個階段的峰值音量——峰值 > 0 代表此刻真的正在出聲。
#
# 用法：
#   & E:\claude\whats-playing.ps1              # 監看 20 秒
#   & E:\claude\whats-playing.ps1 -Seconds 90  # 聽到聲音時跑久一點才抓得到
#
# 註：COM 列舉全部在 C# 內完成。PowerShell 5.1 直接接 COM 介面會退化成
#     System.__ComObject 而呼叫不到方法（第一版就是這樣掛掉的）。

param([int]$Seconds = 20)

if (-not ("AudioProbe" -as [type])) {
Add-Type -Language CSharp @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
internal class MMDeviceEnumeratorComObject { }

[ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMMDeviceEnumerator {
  int NotImpl1();
  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice);
}

[ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMMDevice {
  int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams,
               [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
}

[ComImport, Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IAudioSessionManager2 {
  int NotImpl1();
  int NotImpl2();
  int GetSessionEnumerator(out IAudioSessionEnumerator SessionEnum);
}

[ComImport, Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IAudioSessionEnumerator {
  int GetCount(out int SessionCount);
  int GetSession(int SessionCount, out IAudioSessionControl2 Session);
}

[ComImport, Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IAudioSessionControl2 {
  int GetState(out int state);
  int GetDisplayName(out IntPtr name);
  int SetDisplayName(string value, ref Guid ctx);
  int GetIconPath(out IntPtr path);
  int SetIconPath(string value, ref Guid ctx);
  int GetGroupingParam(out Guid group);
  int SetGroupingParam(ref Guid group, ref Guid ctx);
  int RegisterAudioSessionNotification(IntPtr nf);
  int UnregisterAudioSessionNotification(IntPtr nf);
  int GetSessionIdentifier(out IntPtr id);
  int GetSessionInstanceIdentifier(out IntPtr id);
  int GetProcessId(out uint pid);
  int IsSystemSoundsSession();
  int SetDuckingPreference(bool optOut);
}

[ComImport, Guid("C02216F6-8C67-4B5B-9D00-D008E73E0064"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IAudioMeterInformation {
  int GetPeakValue(out float pfPeak);
}

public class AudioProbe {
  // 回傳格式：pid|peak|state    (state: 0=非作用 1=作用中 2=過期)
  public static string[] Snapshot() {
    var list = new List<string>();
    try {
      var de = (IMMDeviceEnumerator)(new MMDeviceEnumeratorComObject());
      IMMDevice dev;
      if (de.GetDefaultAudioEndpoint(0, 1, out dev) != 0) return list.ToArray();

      Guid iid = typeof(IAudioSessionManager2).GUID;
      object o;
      if (dev.Activate(ref iid, 1, IntPtr.Zero, out o) != 0) return list.ToArray();

      IAudioSessionEnumerator se;
      if (((IAudioSessionManager2)o).GetSessionEnumerator(out se) != 0) return list.ToArray();

      int count;
      se.GetCount(out count);
      for (int i = 0; i < count; i++) {
        IAudioSessionControl2 ctl;
        if (se.GetSession(i, out ctl) != 0 || ctl == null) continue;

        uint pid; ctl.GetProcessId(out pid);
        int state; ctl.GetState(out state);

        float peak = 0f;
        var meter = ctl as IAudioMeterInformation;
        if (meter != null) meter.GetPeakValue(out peak);

        list.Add(pid + "|" + peak.ToString("F5") + "|" + state);
      }
    } catch { }
    return list.ToArray();
  }
}
"@
}

function Get-Sessions {
    $rows = @()
    foreach ($line in [AudioProbe]::Snapshot()) {
        $pidStr, $peakStr, $stateStr = $line -split '\|'
        $procId = [int]$pidStr
        $name = if ($procId -eq 0) { '系統音效' }
                else {
                    $pr = Get-Process -Id $procId -ErrorAction SilentlyContinue
                    if ($pr) { $pr.Name } else { "(已結束 pid=$procId)" }
                }
        $rows += [PSCustomObject]@{
            程式 = $name
            PID  = $procId
            峰值 = [double]$peakStr
            狀態 = switch ([int]$stateStr) { 0 {'非作用'} 1 {'作用中'} 2 {'過期'} default {$stateStr} }
        }
    }
    return $rows
}

# 先確認 API 讀得到東西
$probe = Get-Sessions
if ($probe.Count -eq 0) {
    Write-Host "讀不到任何音訊工作階段（API 可能失敗或目前無音訊裝置）" -ForegroundColor Red
    exit 1
}

Write-Host "監看 $Seconds 秒，找正在出聲的程式..." -ForegroundColor Cyan
Write-Host "（目前有 $($probe.Count) 個音訊工作階段；峰值 > 0 = 此刻真的在出聲）`n" -ForegroundColor DarkGray

$loud = @{}
$end = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $end) {
    foreach ($s in Get-Sessions) {
        if ($s.峰值 -gt 0) {
            $k = "$($s.程式) (pid=$($s.PID))"
            if (-not $loud.ContainsKey($k)) { $loud[$k] = 0.0 }
            if ($s.峰值 -gt $loud[$k]) { $loud[$k] = $s.峰值 }
            Write-Host ("[{0}] >> {1,-24} 峰值 {2}" -f (Get-Date -Format 'HH:mm:ss'), $k, $s.峰值) -ForegroundColor Yellow
        }
    }
    Start-Sleep -Milliseconds 400
}

Write-Host "`n=== 監看期間有出聲的程式 ===" -ForegroundColor Cyan
if ($loud.Count -eq 0) {
    Write-Host "  （無）這段時間沒有任何程式出聲" -ForegroundColor DarkGray
    Write-Host "  → 聲音是偶發的，下次聽到的當下再跑一次才抓得到" -ForegroundColor DarkGray
} else {
    $loud.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        Write-Host ("  {0,-32} 最大峰值 {1}" -f $_.Key, [math]::Round($_.Value, 5)) -ForegroundColor Yellow
    }
}

Write-Host "`n=== 目前所有音訊工作階段 ===" -ForegroundColor Cyan
Get-Sessions | Sort-Object 峰值 -Descending | Format-Table -AutoSize
