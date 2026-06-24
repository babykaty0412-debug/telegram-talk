# telegram-talk

Windows 上以 Claude Code 跑的 Telegram bot（手機端對話 Claude）+ 守護排程。

## 核心限制

**一個 bot token 同時只能有一個 `getUpdates` 消費者（poller）。** 多個 process 同時 poll → 最後啟動的會用 stale-holder 邏輯（讀 `bot.pid` 殺掉前一個）奪取接收槽。出站（發訊息）任何 process 都行；入站只有持槽者收得到。

## 架構與關鍵修法（2026-06-24）

### 根因：互動 session 搶接收槽
全域 `~/.claude/settings.json` 的 `enabledPlugins.telegram@claude-plugins-official: true` → 每個互動 Claude Code session 都被自動載入 telegram plugin 並啟動 poller，比專屬 bot 晚啟動就搶走槽，而互動 session 忙著服務桌面對話、不回覆 TG → bot 形同失聯。

### 修法
1. **全域關閉**：`settings.json` → `enabledPlugins.telegram@claude-plugins-official: false`（互動 session 不再 poll、不搶槽）
2. **bot 單獨開啟**：`Claude Telegram.bat` 用 `--settings bot-settings.json` 載入 installed 版 telegram
   ```
   claude --channels plugin:telegram@claude-plugins-official --settings "E:\claude\bot-settings.json"
   ```

### 🚫 `--plugin-dir` 陷阱（別用）
用 `--plugin-dir` 載入會變成「inline」識別碼，與 `--channels` 指名的「@claude-plugins-official」(installed) 不符 → debug log 報 `Channel notifications skipped`，bot 收到訊息也不處理。**必須用 `--settings`。**

### ⚠️ 副作用
全域關閉後，互動 session 不再有 telegram MCP 工具（reply/react）。需要從互動 session 發訊息到 TG 時，改用直接 API（`Invoke-RestMethod` + bot token）。

## 檔案

| 檔案 | 作用 |
|------|------|
| `Claude Telegram.bat` | production 啟動（`--settings`）|
| `bot-settings.json` | bot 專用：單獨開啟 telegram plugin |
| `telegram-watchdog.ps1` | 守護排程（每 10 分鐘）：進程死了重啟、接收槽被搶奪回、心跳停滯偵測額度耗盡並於 5h 視窗後重啟。Layer 2 只比對 `--channels` 進程，不誤判互動 worker |
| `telegram-daily-restart.ps1` | 每日重啟（需用管理員建排程）|
| `bot-health.ps1` | 一眼健檢（結構檢查，不需 bot 回覆、不耗額度）：`& E:\claude\bot-health.ps1` → `✅ 正常` / `❌ 壞了+原因`，exit 0/1 |

## 執行期檔案（不在版控）

`bot-heartbeat.txt`（bot 每次真實回覆後更新）、`bot-quota-*.txt`、`telegram-watchdog.log`。

## 驗證入站

開 Telegram 桌面版 → 私訊 bot → 看回覆 + `bot-heartbeat.txt` 是否更新。

## 注意

- bot token 在 `~/.claude/channels/telegram/.env`（**不在本 repo**，絕不外洩）
- `telegram-watchdog.ps1` 內含通知用的 chat_id（非憑證；私有 repo）
