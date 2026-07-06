# telegram-talk

Windows 上以 Claude Code 跑的 Telegram bot（手機端對話 Claude）+ 守護排程。
**本 repo 含遷移到新電腦所需的全部可攜檔案；照「🖥️ 新電腦部署」即可重建。**

## 核心限制

**一個 bot token 同時只能有一個 `getUpdates` 消費者（poller）。** 多個 process 同時 poll → 最後啟動的用 stale-holder（讀 `bot.pid` 殺前一個）奪取接收槽。出站任何 process 都行；入站只有持槽者收得到 → 所以要「專屬 bot 獨佔槽、互動 session 不載入 telegram」。

---

## 🩺 出問題先跑這個 — 一鍵診斷

bot 沒回、腳本報錯、搬機卡住——不管什麼狀況，先跑：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "E:\claude\diagnose.ps1"
```

它會依序檢查 10 大項（軟體 → 檔案 → secrets → 設定 → 硬編路徑 → 進程 → 排程 → Telegram API → log），每個 `[X ]` 直接附修法，**由上而下修**（前面的問題常是後面的根因）。修不動就把**完整輸出**全選複製貼給 Claude（不含 token，可安全貼）。

---

## 📁 檔案清單（repo 檔 → 部署位置）

| repo 檔 | 部署到 | 作用 |
|---------|--------|------|
| `Claude Telegram.bat` | `<工具根>\` | production 啟動（`--settings`）|
| `bot-settings.json` | `<工具根>\` | bot 專用：單獨開啟 installed 版 telegram plugin |
| `telegram-watchdog.ps1` | `<工具根>\` | 守護（每 10 分鐘）：死了/重複/殭屍才重啟，只看結構健康 |
| `telegram-daily-restart.ps1` | `<工具根>\` | 每日 06:00 重啟（需管理員建排程）|
| `bot-health.ps1` | `<工具根>\` | 一眼健檢：`& <工具根>\bot-health.ps1` → ✅/❌，exit 0/1 |
| `diagnose.ps1` | `<工具根>\` | **一鍵診斷**：10 大項全面健檢，`[X ]` 附修法，輸出可直接貼給 Claude |
| `tg-check.ps1` | `~\.claude\hooks\` | UserPromptSubmit hook：bot 壞了才提醒（純本地檢查）|

`<工具根>` 舊機是 `E:\claude`。

---

## 🖥️ 新電腦部署（完整步驟）

### 0. 前置（先裝好）
- **Claude Code** 已安裝並登入 Claude 帳號
- **telegram plugin 已安裝進 cache**（bot 靠 `--channels ... --settings` 啟用 installed 版）。用 `/plugin` 裝 `telegram@claude-plugins-official` 一次即可
- **node**（本機用 nvm4w，路徑 `C:\nvm4w\nodejs`）與 **bun**（`~\.bun\bin\bun.exe`）已裝且在 PATH
- 已有 **Telegram bot**（同一個 bot token）與你的 chat_id

### 1. clone 本 repo
clone 到工具根目錄（建議沿用 `E:\claude`，可省去改路徑）：
```
git clone https://github.com/babykaty0412-debug/telegram-talk.git E:\claude
```

### 2. 改硬編碼路徑（若新機帳號/磁碟不同才需要）
find-replace 這些字串（`Claude Telegram.bat` + 所有 `.ps1`）：

| 舊值 | 改成 |
|------|------|
| `E:\claude` | 新工具根 |
| `C:\Users\21030502` | `C:\Users\<新使用者>` |
| `C:\nvm4w\nodejs` | 新機 node 路徑 |
| chat_id `729844447`（watchdog 通知用）| 你的 chat_id（同帳號則不變）|

> hook 用 `$env:USERPROFILE`，帳號變也不用改。

### 3. 重建 secrets（**不在 repo，手動建**）
- `~\.claude\channels\telegram\.env` → 一行：`TELEGRAM_BOT_TOKEN=<你的token>`
- `~\.claude\channels\telegram\access.json` → 允許名單，例：
```json
{ "dmPolicy": "allowlist", "allowFrom": ["<你的chat_id>"], "groups": {}, "pending": {} }
```

### 4. 併入 `~\.claude\settings.json`（合併，別覆蓋既有）
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
- `enabledPlugins.telegram=false` → 互動 session 不搶槽（**關鍵**）
- allow 那 5 條 → bot 回訊不被權限守門員攔

### 5. 裝 hook
把 `tg-check.ps1` 複製到 `~\.claude\hooks\tg-check.ps1`。

### 6. 建排程（**系統管理員 PowerShell**）
```powershell
# 守護每 10 分鐘（-RepetitionDuration 用有限天數，別用 [TimeSpan]::MaxValue 會報 XML 格式錯）
$a=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NonInteractive -WindowStyle Hidden -File "E:\claude\telegram-watchdog.ps1"'
$t=New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 3650)
$s=New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName 'Telegram-Bot守護' -Action $a -Trigger $t -Settings $s -RunLevel Highest -Force

# 每日 06:00 重啟
$a2=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NonInteractive -WindowStyle Hidden -File "E:\claude\telegram-daily-restart.ps1"'
Register-ScheduledTask -TaskName 'Telegram-Bot每日六點重啟' -Action $a2 -Trigger (New-ScheduledTaskTrigger -Daily -At '06:00') -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable) -RunLevel Highest -Force
```

### 7. 啟動 + 驗證
```powershell
# 啟動 bot
Start-Process 'cmd.exe' -ArgumentList '/c','"E:\claude\Claude Telegram.bat"' -WindowStyle Minimized
# 等約 70 秒後健檢
& E:\claude\bot-health.ps1            # → ✅ Bot 正常
```
再用手機 Telegram 私訊 bot 發一則 → 看有沒有回覆。有回覆 = 部署成功。

---

## 架構重點（2026-06〜07）

- **啟動只用 `Claude Telegram.bat`**（含 `--settings`）。別手動 `claude --channels`：全域 `enabledPlugins.telegram=false`，少了 `--settings` 會 `Channel notifications skipped`（收得到卻不回）。
- **🚫 別用 `--plugin-dir`**：載入成 inline 識別碼，與 `--channels @claude-plugins-official` 不符 → 一樣 skipped。
- **守護只看結構健康**（進程死/重複 bot/poller 不在才重啟），不用心跳猜額度（安靜沒人傳訊心跳本來就停，舊版會誤判額度耗盡狂發假警報）。
- **副作用**：全域關 telegram 後，互動 session 沒有 telegram MCP 工具；要從互動 session 發訊到群組改用直接 API（`Invoke-RestMethod` + token）。

## 腳本踩雷（改腳本前必看）

破壞性動作（重啟/發通知）前一定要防這三個，否則發假警報：
1. **PowerShell 單元素解包**：函式 `return @(...)` 只回 1 個會被解包成純量，call site 對它 `.Count` = 空白 → 誤判。**call site 一律 `@(Get-X).Count`**。
2. **`Win32_Process.CommandLine` 間歇 null**：偵測 bot/bun 前**重試 3 次**再下結論。
3. **bun 別取 `-First 1`**：孤兒 bun 會選錯 → 檢查「有沒有任一 server.ts bun 是 bot 子孫」。

## 執行期檔案（不在版控、不用遷移）
`bot-heartbeat.txt`、`telegram-watchdog.log`、`bot.pid`。

## 注意
- bot token 在 `~\.claude\channels\telegram\.env`（**絕不進 repo / 不外洩**）
- `telegram-watchdog.ps1` 內含通知用 chat_id（非憑證；私有 repo）
