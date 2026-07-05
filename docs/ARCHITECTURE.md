# 架構重點

## 核心限制：單一 poller

**一個 bot token 同時只能有一個 `getUpdates` 消費者（poller）。**

- 多個 process 同時 poll → Telegram 只保證「最後啟動的」用 stale-holder 語意奪取接收槽（讀 `bot.pid` 殺前一個），其餘變孤兒，永遠收不到訊息。
- **出站**（主動發訊）任何 process 都行，不受此限制 —— 直接呼叫 `sendMessage` API 即可。
- **入站**（接收使用者訊息）只有當下持槽的那個 poller 收得到。

因此架構設計為：**專屬 bot 進程獨佔接收槽，互動 session（你平常開的 `claude`）全域不載入 telegram plugin**，兩邊不會搶槽。

## 啟動規則

- **啟動只用 `Claude Telegram.bat`**（內含 `--settings "bot-settings.json"`）。
- 別手動下 `claude --channels ...` 不帶 `--settings`：全域 `enabledPlugins.telegram=false` 時，缺了 `--settings` 會出現 `Channel notifications skipped`（收得到訊息但不回覆，難以察覺的半殘狀態）。
- **🚫 別用 `--plugin-dir`**：載入出來的識別碼是 inline 格式，與 `--channels @claude-plugins-official` 的命名不一致 → 一樣被判定 skipped。

## 守護策略

守護（`telegram-watchdog.ps1`）**只看結構健康**，不用心跳猜額度：

- 進程死了 / 重複 bot / 殭屍（bot 活著但沒有屬於自己的 bun poller）才重啟。
- 不會因為「安靜沒人傳訊、心跳停滯」誤判成額度耗盡而狂發假警報 —— 這是舊版本的已知問題，新版特意避開。

三層判斷邏輯與各自的重試/防呆設計，細節見 `docs/TROUBLESHOOTING.md`。

## 副作用：互動 session 沒有 telegram 工具

全域關閉 `enabledPlugins.telegram` 後，一般互動 session（你手動開的 `claude`）**沒有 telegram MCP 工具**（`reply` / `react` / `edit_message` / `download_attachment` 都叫不到）。

若要從互動 session 主動發訊到群組/使用者，改用直接 API：

```powershell
$token = "<TELEGRAM_BOT_TOKEN>"
Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post `
  -Body (@{ chat_id = "<chat_id>"; text = "..." } | ConvertTo-Json) `
  -ContentType 'application/json; charset=utf-8'
```

## 相關檔案

| 檔案 | 角色 |
|------|------|
| `Claude Telegram.bat` | 唯一正確的 production 啟動方式 |
| `bot-settings.json` | 讓 bot 進程單獨啟用 installed 版 telegram plugin |
| `telegram-watchdog.ps1` | 三層結構健康守護 |
| `telegram-daily-restart.ps1` | 每日固定重啟（不判斷健康，純 kill + restart） |
| `bot-health.ps1` | 一次性健檢，供人工或 skill 呼叫 |
| `tg-check.ps1` | Claude Code `UserPromptSubmit` hook，壞了才提醒 |

各腳本細節見 `docs/SCRIPTS.md`；部署步驟見 `docs/DEPLOYMENT.md`。
