' run-hidden.vbs - generic hidden launcher for Task Scheduler
'
' WHY: powershell.exe -WindowStyle Hidden does NOT stop the flash. PowerShell
' creates a VISIBLE console window first, then hides it (measured 2026-07-27:
' process at 22:50:01, visible window at 22:50:02 - blue box flashes on screen).
' WshShell.Run(cmd, 0) sets SW_HIDE at CreateProcess time, so the window is
' never visible. No flash.
'
' USAGE (Task Scheduler action):
'   Program:   wscript.exe
'   Arguments: "E:\claude\run-hidden.vbs" powershell.exe -NoProfile -ExecutionPolicy Bypass -File E:\path\script.ps1
'
' NOTE: args are re-joined with spaces, so paths must NOT contain spaces.
' NOTE: keep this file ASCII-encoded. UTF-8 without BOM breaks wscript parsing.

Dim sh, cmd, i
Set sh = CreateObject("WScript.Shell")
cmd = ""
For i = 0 To WScript.Arguments.Count - 1
  If i > 0 Then cmd = cmd & " "
  cmd = cmd & WScript.Arguments(i)
Next
If Len(cmd) = 0 Then WScript.Quit 1
sh.Run cmd, 0, False
