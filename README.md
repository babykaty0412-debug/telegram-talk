# telegram-talk

Windows 上以 Claude Code 跑的 Telegram bot（手機端對話 Claude）+ 守護排程。
**本 repo 含遷移到新電腦所需的全部可攜檔案；照「🖥️ 新電腦部署」即可重建。**

## 核心限制

**一個 bot token 同時只能有一個 `getUpdates` 消費者（poller）。** 多個 process 同時 poll → 最後啟動的用 stale-holder（讀 `bot.pid` 殺前一個）奪取接收槽。出站任何 process 都行；入站只有持槽者收得到 → 所以要「專屬 bot 獨佔槽、互動 session 不載入 telegram」。

---

## 📁 檔案清單（repo 檔 → 部署位置）

| repo 檔 | 部署到 | 作用 |
|---------|--------|------|
| `Claude Telegram.bat` | `<工具根>\` | production 啟動（`--settings`）|
| `bot-settings.json` | `<工具根>\` | bot 專用：單獨開啟 installed 版 telegram plugin |
| `telegram-watchdog.ps1` | `<工具根>\` | 守護（每 10 分鐘）：死了/重複/殭屍才重啟，只看結構健康 |
| `telegram-daily-restart.ps1` | `<工具根>\` | 每日 06:00 重啟（需管理員建排程）|
| `bot-health.ps1` | `<工具根>\` | 一眼健檢：`& <工具根>\bot-health.ps1` → ✅/❌，exit 0/1 |
| `diagnose-console-flash.ps1` | `<工具根>\` | 抓「畫面一直閃黑框」的元凶（見疑難排解）|
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

---

## 🔍 疑難排解：畫面每隔一段時間閃黑框 / 黑影

### ⚠️ 先問顏色，再量測，最後才動手（2026-07-27 血淚教訓）

**第一句話該問的是「閃出來的視窗是什麼顏色」**：

| 顏色 | 是什麼 | 找誰 |
|------|--------|------|
| **藍底** | PowerShell 主控台 | 跑 `.ps1` 的排程 |
| **黑底** | cmd 主控台 | 跑 `.bat` 的排程、或 Docker/其他程式叫的 CLI |

那次繞了整整六輪（改川普排程→加 vbs→換 pythonw→查到 Docker→關視窗→還在閃），
就是因為沒問顏色。使用者一說「藍底」，範圍立刻縮到「PowerShell 排程」，一次就中。

**兩個元凶同時存在**（這也是為什麼修掉一個還在閃）：
- 黑底、每 10 秒 → Docker Desktop 儀表板
- 藍底、每 10 分鐘 → 三個 PowerShell 排程

**症狀是「週期性閃爍」時，先問顏色 → 再抓證據 → 才動手改。**

### 用法

```powershell
& E:\claude\diagnose-console-flash.ps1 -Minutes 3
```

原理：Windows 每建立一個 console 視窗就會生一支 `conhost.exe`。腳本高頻取樣，
記錄新出現的 conhost **父行程是誰**，最後印出「元凶排行」——次數最高的就是它，
時間戳間隔就是它的週期（每 10 秒 / 每 10 分鐘…），可直接對照排程設定。

### 已知元凶

| 元凶 | 頻率 | 判斷依據 | 解法 |
|------|------|----------|------|
| **Docker Desktop 儀表板** | **每 10 秒 × 3 個** | 父行程 `Docker Desktop.exe --name=dashboard`，子行程跑 `docker stats --all` | **關掉 Docker Desktop 視窗**（點 X）。容器與引擎照常運作，只是不再 GUI 輪詢；要看容器再從系統匣開 |
| **排程的 `powershell.exe`** | **每 10 分鐘各 1 次** | **藍底**；父行程 `svchost.exe`（= Task Scheduler 拉起）| **改用 `run-hidden.vbs`**，見下方 |
| 排程直接跑 `.bat` | 依排程頻率 | 會**停著十幾秒**而非一閃即逝 | 改用 wscript + vbs 隱藏啟動器（見 `stock-info/run_monitor_hidden.vbs`）|

> 實測數據：1 分鐘內 Docker 製造 33 個 console，所有排程加起來只有 1 個。
> 排程從來不是主因——**量級差 30 倍**。

### 排程視窗根治法：`run-hidden.vbs`

**`-WindowStyle Hidden` 完全擋不住閃爍**，實測鐵證（2026-07-27）：

```
[22:50:01.531] 行程 powershell(pid=29600) -WindowStyle Hidden ... telegram-watchdog.ps1
[22:50:02.615] 視窗 powershell(pid=29600) ← 可見視窗真的出現了，晚了 1 秒多
```

原因：powershell.exe **先建立可見的 console 視窗，再套用隱藏樣式**，中間那一秒就是藍底閃現。

解法是 `run-hidden.vbs`——`WshShell.Run(cmd, 0)` 在 **CreateProcess 當下**就指定 `SW_HIDE`，
視窗自始至終不曾可見。排程動作改成：

```
程式：wscript.exe
引數："E:\claude\run-hidden.vbs" powershell.exe -NoProfile -ExecutionPolicy Bypass -File E:\claude\你的腳本.ps1
```

批次套用（本機四個排程已用此法修正）：

```powershell
$map = @{
  '多模型TG-Bot-守護-每10分鐘' = 'E:\claude\multi-model\watchdog.ps1'
  '多模型TG-Bot-開機啟動'      = 'E:\claude\multi-model\watchdog.ps1'
  'Telegram-Bot守護-每30分鐘'  = 'E:\claude\telegram-watchdog.ps1'
  '自架網站-健檢通知'          = 'E:\claude\projects\selfhost-lab\scripts\site-health.ps1'
}
foreach ($name in $map.Keys) {
  $arg = '"E:\claude\run-hidden.vbs" powershell.exe -NoProfile -ExecutionPolicy Bypass -File {0}' -f $map[$name]
  Set-ScheduledTask -TaskName $name -Action (New-ScheduledTaskAction -Execute 'wscript.exe' -Argument $arg)
}
```

> **為什麼不用 S4U**：S4U 讓任務跑在 session 0（無桌面，確實不會閃），
> 但 bot 守護腳本會**啟動 bot 進程**——跑在 session 0 的 bot 你看不到也管不到，
> 等於修好閃爍卻弄壞 bot。vbs 保持在使用者 session，才是這裡的正解。

### 踩雷

- **`.ps1` 含中文要存成 UTF-8 with BOM**。PowerShell 5.1 讀無 BOM 的 UTF-8 會把中文解析錯，
  直接噴 `Unexpected token` 語法錯誤（本腳本第一版就是這樣掛掉的）。
- **`.vbs` 反過來——要存成 ASCII**。含中文註解又存 UTF-8 無 BOM 時，wscript 會靜默失敗：
  `cscript` 回 exit 0、卻什麼都沒執行，最難查。`run-hidden.vbs` 因此全用英文註解。
- **短命行程抓不到**：`docker stats` 這種瞬間生滅的，用 `Get-Process` 事後查一定是空的，
  必須高頻取樣（本腳本用 200ms）才抓得到命令列。
- **「有 conhost」不等於「有看得見的視窗」**：修好後 `conhost` 照樣會被建立
  （console 物件存在），但從未顯示。判斷有沒有閃要看**可見視窗**，不是數 conhost。
  真正該用的偵測是 `EnumWindows` + `IsWindowVisible` 掃可見視窗（見下方腳本）。
- **改完排程要看時間軸對不對**：曾誤以為修正無效，其實記錄檔涵蓋的時段全在修正之前。
  比對前先確認「變更時間」和「記錄時間」的先後。

---

## 執行期檔案（不在版控、不用遷移）
`bot-heartbeat.txt`、`telegram-watchdog.log`、`bot.pid`。

## 注意
- bot token 在 `~\.claude\channels\telegram\.env`（**絕不進 repo / 不外洩**）
- `telegram-watchdog.ps1` 內含通知用 chat_id（非憑證；私有 repo）
