@echo off
cd /d E:\claude
powershell -NoProfile -Command "if (Get-CimInstance Win32_Process -Filter \"Name='claude.exe'\" | Where-Object { $_.CommandLine -match '--channels' }) { exit 1 } else { exit 0 }"
if errorlevel 1 (
    echo Claude Telegram Bot is ALREADY RUNNING. Not starting a second one.
    echo This window will close in 8 seconds...
    timeout /t 8 >nul
    exit /b
)
claude --channels plugin:telegram@claude-plugins-official --settings "E:\claude\bot-settings.json"
