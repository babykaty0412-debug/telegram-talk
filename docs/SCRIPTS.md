# 腳本參考

`<工具根>` 舊機是 `E:\claude`；新機路徑見 `docs/DEPLOYMENT.md` 的 find-replace 表。

| repo 檔 | 部署到 | 觸發方式 | 作用 |
|---------|--------|---------|------|
| `Claude Telegram.bat` | `<工具根>\` | 雙擊 / `Start-Process` | production 啟動（帶 `--settings`），唯一正確的啟動入口 |
| `bot-settings.json` | `<工具根>\` | 被 `.bat` 讀取 | bot 專用設定：單獨開啟 installed 版 telegram plugin |
| `telegram-watchdog.ps1` | `<工具根>\` | 排程每 10 分鐘 | 守護：死了/重複/殭屍才重啟，只看結構健康，不猜額度 |
| `telegram-daily-restart.ps1` | `<工具根>\` | 排程每日 06:00 | 固定重啟（需管理員建排程），純 kill + restart |
| `bot-health.ps1` | `<工具根>\` | 手動 / skill 呼叫 | 一眼健檢：`& <工具根>\bot-health.ps1` → ✅/❌，exit 0/1 |
| `tg-check.ps1` | `~\.claude\hooks\` | `UserPromptSubmit` hook | bot 壞了才提醒（純本地 WMI 檢查，不打網路） |

## 各腳本要點

### `Claude Telegram.bat`
- 先用 WMI 檢查是否已有 `--channels` 進程在跑，避免重複啟動。
- 真正啟動命令：`claude --channels plugin:telegram@claude-plugins-official --settings "bot-settings.json"`。
- 別省略 `--settings`：省略會導致 `Channel notifications skipped`（見 `docs/ARCHITECTURE.md`）。

### `bot-health.ps1`
- 五項檢查：進程存在且唯一、有屬於自己的 bun poller、bun 有連上 Telegram IP 段（`149.154.*` / `91.108.*`）、`bot.pid` 是否對齊（僅提示）、心跳時間（僅參考）。
- 沿用踩雷防護：偵測重試 3 次、bun 沿祖先鏈比對、不用 `-First 1`。
- exit 0 = 正常，exit 1 = 壞了；文字輸出直接可讀。

### `telegram-watchdog.ps1`
- 三層判斷，按順序執行，任一層處理完就 `exit 0`：
  1. **Layer 1**：bot 進程不存在 → 重啟；失敗再嘗試 `npm install -g @anthropic-ai/claude-code` 修復後重啟。
  2. **Layer 2**：偵測到多個 `--channels` 進程 → 全清後重啟一個。
  3. **Layer 3**：bot 活著但沒有屬於它的 bun poller（殭屍）→ 重啟；剛啟動 15 分鐘內跳過此檢查，避免啟動空窗期誤判。
- 關鍵動作都會寫 log（`telegram-watchdog.log`）並視情況用 `Send-Telegram` 通知（用 `.env` 讀 token，chat_id 寫死在腳本內）。

### `telegram-daily-restart.ps1`
- 不判斷健康，單純 kill（`--channels` 進程 + `server.ts` bun）+ 等 3 秒 + 重啟，避免長時間運行累積的不明狀況。
- 需系統管理員建排程觸發，見 `docs/DEPLOYMENT.md` 步驟 6。

### `tg-check.ps1`
- 掛在 Claude Code 的 `UserPromptSubmit` hook，每次你在互動 session 打字送出前跑一次。
- 只在真的壞（進程不在 / 沒有 poller）才回傳 `additionalContext` 提醒模型「回答前先說明 bot 是否可用」；健康時不輸出任何東西（沉默 = 正常）。
- 純本地檢查，不打網路，避免因網路抖動誤報。

## 執行期產出檔案（不在版控、換機不用複製）

`bot-heartbeat.txt`、`telegram-watchdog.log`、`bot.pid` —— 執行期自然產生，重建環境時不用管。
