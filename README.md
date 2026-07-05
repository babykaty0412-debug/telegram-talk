# telegram-talk

Windows 上以 Claude Code 跑的 Telegram bot（手機端對話 Claude）+ 守護排程。
**本 repo 含遷移到新電腦所需的全部可攜檔案；照 `docs/DEPLOYMENT.md` 即可重建。**

## 核心限制

**一個 bot token 同時只能有一個 `getUpdates` 消費者（poller）。** 多個 process 同時 poll → 最後啟動的用 stale-holder（讀 `bot.pid` 殺前一個）奪取接收槽。出站任何 process 都行；入站只有持槽者收得到 → 所以要「專屬 bot 獨佔槽、互動 session 不載入 telegram」。細節見 `docs/ARCHITECTURE.md`。

---

## 文件地圖

| 我想要... | 看這裡 |
|---|---|
| 快速搞懂這個 repo 在幹嘛（給 Claude Code 看的專案上下文） | `CLAUDE.md` |
| 架構原理、核心限制細節、副作用 | `docs/ARCHITECTURE.md` |
| 在新電腦上完整重建這套 bot | `docs/DEPLOYMENT.md`（或請 Claude 用 `deploy-new-machine` skill） |
| 查某支腳本的用途、部署位置、呼叫方式 | `docs/SCRIPTS.md` |
| bot 是不是壞了、怎麼修 | `docs/TROUBLESHOOTING.md`（或請 Claude 用 `bot-health-check` / `bot-troubleshoot` skill） |

`.claude/skills/` 底下是可直接在 Claude 對話中呼叫的維運技能（健康檢查、故障排查、新機部署），內容對應上面的 docs，改動時兩邊要一起維護。

---

## 檔案清單（repo 檔 → 部署位置）

| repo 檔 | 部署到 | 作用 |
|---------|--------|------|
| `Claude Telegram.bat` | `<工具根>\` | production 啟動（`--settings`）|
| `bot-settings.json` | `<工具根>\` | bot 專用：單獨開啟 installed 版 telegram plugin |
| `telegram-watchdog.ps1` | `<工具根>\` | 守護（每 10 分鐘）：死了/重複/殭屍才重啟，只看結構健康 |
| `telegram-daily-restart.ps1` | `<工具根>\` | 每日 06:00 重啟（需管理員建排程）|
| `bot-health.ps1` | `<工具根>\` | 一眼健檢：`& <工具根>\bot-health.ps1` → ✅/❌，exit 0/1 |
| `tg-check.ps1` | `~\.claude\hooks\` | UserPromptSubmit hook：bot 壞了才提醒（純本地檢查）|

`<工具根>` 舊機是 `E:\claude`。完整說明見 `docs/SCRIPTS.md`。

---

## 快速開始

1. clone 到工具根目錄
2. 照 `docs/DEPLOYMENT.md` 走完 0-7 步
3. 日常維運用 `bot-health-check` / `bot-troubleshoot` skill，或直接跑 `bot-health.ps1`

## 執行期檔案（不在版控、不用遷移）

`bot-heartbeat.txt`、`telegram-watchdog.log`、`bot.pid`。

## 注意

- bot token 在 `~\.claude\channels\telegram\.env`（**絕不進 repo / 不外洩**）
- `telegram-watchdog.ps1` 內含通知用 chat_id（非憑證；私有 repo）
