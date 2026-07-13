# Handoff：PC → 雲端工作流評估（進行中）

給接手這個任務的新 session 看的交接筆記。讀完這份 + `CLAUDE.md` + `docs/ARCHITECTURE.md` 再開始動手。

## 現況（已完成）

- 剛做完一次文件重構：README 精簡為索引，深入內容拆到 `docs/`（`ARCHITECTURE.md` / `DEPLOYMENT.md` / `TROUBLESHOOTING.md` / `SCRIPTS.md`），新增 `CLAUDE.md` 專案上下文，新增 3 個 `.claude/skills/`（`bot-health-check` / `bot-troubleshoot` / `deploy-new-machine`）。
- 分支：`claude/cloud-docs-skills-optimization-0f9otb`，已 push 到 origin，尚未開 PR。
- commit：`d9a6505`（文件重構）、`5db2e16`（更早的完整遷移包）。

## 使用者這次要做的事

使用者想要「改成雲端版面」，動機是 **之後可以跨瀏覽器使用**，不想被綁死在同一台 PC 才能對話/維運。這句話目前只確認了「動機」，**還沒確認「Telegram bot 本體最終要跑在哪裡」**——這兩件事要分開看：

1. **跨瀏覽器管理/對話這個 repo**：這件事本來就成立。只要新 session 是跑在 Claude Code 的雲端/remote 環境（跟產生這份筆記的 session 同性質），使用者本來就能從任何瀏覽器開啟該 session 繼續對話、改 repo、跑指令。**不需要額外遷移**。
2. **Telegram bot 本身**（那個 24/7 監聽 `getUpdates` 的 poller 進程）要跑在哪：**還沒決定**。目前整套架構（`docs/ARCHITECTURE.md`、`docs/DEPLOYMENT.md`、`docs/TROUBLESHOOTING.md`、`docs/SCRIPTS.md`、三個 skill）**全部以「常駐 Windows PC」為前提寫的**（PowerShell、WMI、Windows Task Scheduler）。

## 關鍵事實：雲端 session ≠ bot 本體搬雲端

Claude Code 的雲端/remote session 是 ephemeral container，閒置一段時間會被回收，不是一台能長期開著、24/7 保持 Telegram 連線的機器。「開新雲端 session」本身**不會**讓 bot 也搬去雲端。若要讓 bot 脫離 PC，需要額外在下面三個方向中選一個：

| 方案 | PC 需要一直開著嗎 | 改動幅度 |
|---|---|---|
| A. 只把「開發/維運」搬雲端，bot 本體留在 PC | 要 | 最小，現有架構完全不用動 |
| B. bot 本體也搬到一台常駐雲端主機（VPS/VM） | 不用 | 中～大：PowerShell / WMI / Task Scheduler 全部要換成 Linux 對應方案（bash / systemd / cron），單一 poller 限制不變 |
| C. 改成 webhook 架構，讓 Telegram 主動推訊到雲端端點 | 不用 | 最大：架構整個改，但最適合「真正雲端、不需要常駐進程」的長期目標 |

使用者上一輪還沒選 A / B / C 中的哪一個。**新 session 開始工作前，先跟使用者確認要選哪個方案，不要自行假設後就動手改架構。**

## 新 session 該做的第一件事

1. 讀 `CLAUDE.md`、`docs/ARCHITECTURE.md`，搞懂現有架構與核心限制（單一 poller，見 `docs/ARCHITECTURE.md`）。
2. 跟使用者確認：這次「改雲端」是指上面 A / B / C 哪一種——或其實使用者要的只是第 1 點（跨瀏覽器對話這個 repo），那件事已經達成，不用做架構變更，可以直接跟使用者說清楚就結束。
3. 依照使用者選的方案，才決定要不要新增（例如）`docs/CLOUD-DEPLOYMENT.md`、Linux/bash 版腳本、新的 skill（例如 `deploy-cloud-vps`）。**不要覆蓋或刪除現有的 PC 版文件/腳本**——如果兩套架構需要並存，就並列寫，不要互相取代，PC 版在方案 A 底下仍然是唯一的正式架構。

## 分支資訊

- 目前工作分支：`claude/cloud-docs-skills-optimization-0f9otb`
- 若這是新任務，依當時系統給的 branch 指示為準（可能延續此分支，也可能開新分支）。
