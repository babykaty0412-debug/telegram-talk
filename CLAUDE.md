# telegram-talk — 專案上下文

給在本 repo 工作的 Claude Code session（含 bot 自己的互動 session）快速定位用。細節一律在 `docs/` 或對應 skill，這裡只放「你現在在哪、別踩什麼」。

## ⚠️ 進行中：PC → 雲端工作流評估

使用者正在評估把工作流改成雲端（動機：跨瀏覽器使用），但 **bot 本體要不要一起搬離 PC 尚未決定**。新 session 開始前**必讀** `docs/HANDOFF.md`，裡面有現況、待確認的方案選項、和「先跟使用者確認再動手」的提醒。這段完成後可以刪除本節。

## 這是什麼

Windows 機器上用 Claude Code 跑一個 Telegram bot（手機對話 Claude）+ 一組守護排程（watchdog/daily-restart/health-check）。本 repo 是「遷移到新電腦所需的全部可攜檔案」，即開機重建的來源。

## 唯一核心限制（改任何東西前先懂這個）

**一個 bot token 同時只能有一個 `getUpdates` 消費者（poller）。** 多個 process 同時 poll → 最後啟動的用 stale-holder（讀 `bot.pid` 殺前一個）奪取接收槽。出站任何 process 都行；入站只有持槽者收得到。所以架構是「專屬 bot 進程獨佔接收槽，互動 session 全域不載入 telegram plugin」。改動排程/啟動腳本前，先確認這個獨佔關係沒被破壞。

詳細機制、槽位模型、副作用 → `docs/ARCHITECTURE.md`。

## 文件地圖

| 需求 | 去哪 |
|------|------|
| 新電腦要重建整套 bot | `docs/DEPLOYMENT.md`（或直接用 `deploy-new-machine` skill） |
| 想知道每支腳本做什麼、部署到哪 | `docs/SCRIPTS.md` |
| bot 是不是還活著、健不健康 | `bot-health-check` skill（跑 `bot-health.ps1` 並解讀結果） |
| bot 壞了要怎麼修 | `bot-troubleshoot` skill / `docs/TROUBLESHOOTING.md` |
| 架構原理、核心限制細節 | `docs/ARCHITECTURE.md` |
| README 總覽 | `README.md`（純索引，深入內容都在上面幾份） |

## 改腳本前的鐵律

1. PowerShell 函式 `return @(...)` 只回 1 個元素會被解包成純量 → call site 一律 `@(Get-X).Count` 重新包陣列。
2. `Win32_Process.CommandLine` 會間歇回 `null` → 偵測 bot/bun 前重試 3 次再下結論，不要一次查不到就判死。
3. 抓 telegram bun 別用 `-First 1`：孤兒 bun（非本 bot 子孫）會選錯 → 要沿 `ParentProcessId` 往上追到這個 bot 的 PID。

這三條在 `bot-health.ps1`、`telegram-watchdog.ps1`、`tg-check.ps1` 裡都已經處理過；新腳本或改動時要延續同樣的防護，理由與案例見 `docs/TROUBLESHOOTING.md`。

## Secrets（絕不進 repo）

- bot token：`~\.claude\channels\telegram\.env`
- 允許名單：`~\.claude\channels\telegram\access.json`
- `.gitignore` 是白名單模式（預設全擋，逐一放行），新增可版控檔案要記得加 `!` 規則，否則會被靜默排除。
