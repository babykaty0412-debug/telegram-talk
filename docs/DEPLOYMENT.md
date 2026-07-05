# 新電腦部署（完整步驟）

原理與限制先讀 `docs/ARCHITECTURE.md`；也可以直接請 Claude 用 `deploy-new-machine` skill 走一遍。

## 0. 前置（先裝好）

- **Claude Code** 已安裝並登入 Claude 帳號
- **telegram plugin 已安裝進 cache**（bot 靠 `--channels ... --settings` 啟用 installed 版）。用 `/plugin` 裝 `telegram@claude-plugins-official` 一次即可
- **node**（本機用 nvm4w，路徑 `C:\nvm4w\nodejs`）與 **bun**（`~\.bun\bin\bun.exe`）已裝且在 PATH
- 已有 **Telegram bot**（同一個 bot token）與你的 chat_id

## 1. clone 本 repo

clone 到工具根目錄（建議沿用 `E:\claude`，可省去改路徑）：

```
git clone https://github.com/babykaty0412-debug/telegram-talk.git E:\claude
```

## 2. 改硬編碼路徑（若新機帳號/磁碟不同才需要）

find-replace 這些字串（`Claude Telegram.bat` + 所有 `.ps1`）：

| 舊值 | 改成 |
|------|------|
| `E:\claude` | 新工具根 |
| `C:\Users\21030502` | `C:\Users\<新使用者>` |
| `C:\nvm4w\nodejs` | 新機 node 路徑 |
| chat_id `729844447`（watchdog 通知用）| 你的 chat_id（同帳號則不變）|

> hook 用 `$env:USERPROFILE`，帳號變也不用改。

## 3. 重建 secrets（**不在 repo，手動建**）

- `~\.claude\channels\telegram\.env` → 一行：`TELEGRAM_BOT_TOKEN=<你的token>`
- `~\.claude\channels\telegram\access.json` → 允許名單，例：

```json
{ "dmPolicy": "allowlist", "allowFrom": ["<你的chat_id>"], "groups": {}, "pending": {} }
```

## 4. 併入 `~\.claude\settings.json`（合併，別覆蓋既有）

```json
{
  "enabledPlugins": { "telegram@claude-plugins-official": false },
  "permissions": { "allow": [
    "WebSearch",
    "mcp__plugin_telegram_telegram__reply",
    "mcp__plugin_telegram_telegram__react",
    "mcp__plugin_telegram_telegram__edit_message",
    "mcp__plugin_telegram_telegram__download_attachment"
  ]},
  "hooks": { "UserPromptSubmit": [ { "hooks": [ {
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$env:USERPROFILE\\.claude\\hooks\\tg-check.ps1\"",
    "shell": "powershell", "timeout": 12
  } ] } ] }
}
```

- `enabledPlugins.telegram=false` → 互動 session 不搶槽（**關鍵**，見 `docs/ARCHITECTURE.md`）
- allow 那 5 條 → bot 回訊不被權限守門員攔

## 5. 裝 hook

把 `tg-check.ps1` 複製到 `~\.claude\hooks\tg-check.ps1`。

## 6. 建排程（**系統管理員 PowerShell**）

```powershell
# 守護每 10 分鐘
$a=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NonInteractive -WindowStyle Hidden -File "E:\claude\telegram-watchdog.ps1"'
$t=New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName 'Telegram-Bot守護' -Action $a -Trigger $t -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable) -RunLevel Highest -Force

# 每日 06:00 重啟
$a2=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NonInteractive -WindowStyle Hidden -File "E:\claude\telegram-daily-restart.ps1"'
Register-ScheduledTask -TaskName 'Telegram-Bot每日六點重啟' -Action $a2 -Trigger (New-ScheduledTaskTrigger -Daily -At '06:00') -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable) -RunLevel Highest -Force
```

## 7. 啟動 + 驗證

```powershell
# 啟動 bot
Start-Process 'cmd.exe' -ArgumentList '/c','"E:\claude\Claude Telegram.bat"' -WindowStyle Minimized
# 等約 70 秒後健檢
& E:\claude\bot-health.ps1            # → ✅ Bot 正常
```

再用手機 Telegram 私訊 bot 發一則 → 看有沒有回覆。有回覆 = 部署成功。

## 部署完成後

- 檔案對照表見 `docs/SCRIPTS.md`
- 之後日常健檢改用 `bot-health-check` skill 或直接 `& <工具根>\bot-health.ps1`
- 若健檢失敗，走 `docs/TROUBLESHOOTING.md` 或 `bot-troubleshoot` skill
