---
name: deploy-new-machine
description: 在新的 Windows 機器上從零部署 telegram-talk 這套 Telegram bot（clone repo、改路徑、建 secrets、建排程、啟動驗證）。當使用者說「幫我在新電腦上部署 bot」「遷移到新電腦」「重建這套 bot」「set up telegram bot on new pc」時使用。
---

# 新電腦部署

完整步驟已寫在 `docs/DEPLOYMENT.md`，這個 skill 是把它變成一個可執行的引導流程，並在有需要時代為執行可自動化的部分。原理背景（單一 poller 限制、為何互動 session 不能開 telegram）見 `docs/ARCHITECTURE.md`。

## 執行前先跟使用者確認的資訊

- 新工具根目錄（不填就沿用 `E:\claude`）
- 新機使用者帳號名稱（對應 `C:\Users\<使用者>`）
- 新機 node 安裝路徑（不填就假設沿用 `C:\nvm4w\nodejs`）
- Telegram bot token 與 chat_id 是否延用舊的（多半延用同一個 bot）

## 步驟（對照 `docs/DEPLOYMENT.md`）

1. **前置確認**：Claude Code 已裝好登入、telegram plugin 已透過 `/plugin` 裝進 cache、node + bun 在 PATH。這步無法代為執行，只能提醒使用者檢查。
2. **clone repo** 到工具根目錄。
3. **改硬編碼路徑**：對 `Claude Telegram.bat` 和所有 `.ps1` 做 find-replace（`E:\claude`、`C:\Users\21030502`、`C:\nvm4w\nodejs`、chat_id `729844447`）。若使用者提供新值且要求代為修改，可以直接用 Edit 逐一取代 —— 但這些檔案部署到 Windows 機器上執行，若目前的 session 不是那台機器，只能提供改好的內容或明確的取代指令，不要假裝已經在對方機器上執行。
4. **重建 secrets**（一定要提醒使用者手動做，不可、也不會幫忙產生或索取 token 內容）：
   - `~\.claude\channels\telegram\.env`
   - `~\.claude\channels\telegram\access.json`
5. **合併 `~\.claude\settings.json`**：提醒這是「合併」不是覆蓋，貼出 `docs/DEPLOYMENT.md` 步驟 4 的 JSON 片段給使用者手動併入，或若使用者要求且能存取該檔案，用 Edit 合併並保留既有內容。
6. **裝 hook**：`tg-check.ps1` 複製到 `~\.claude\hooks\tg-check.ps1`。
7. **建排程**（需系統管理員 PowerShell，無法代為執行 —— 提供指令請使用者自行貼上執行）：
   - 守護排程每 10 分鐘
   - 每日 06:00 重啟排程
8. **啟動 + 驗證**：提供啟動指令，並建議等 60-70 秒後跑 `bot-health-check` skill 驗證，再用手機私訊測試。

## 重要邊界

- 這個 skill 通常是在**與目標 Windows 機器不同的環境**（例如雲端 session）被呼叫。除非目前的檔案系統就是目標機器，否則只能：
  - 產出改好路徑的檔案內容 / 明確指令清單
  - 不要宣稱「已經部署完成」，除非確實在目標機器上驗證過（跑過 `bot-health.ps1` 且看到 ✅）
- Secrets（token、access.json 內容）一律由使用者自行建立，不要幫忙生成假值當佔位符後忘記提醒替換。
- 建排程需要系統管理員權限，只能提供指令，不能代為執行。

## 完成後

提醒使用者之後日常維運改用 `bot-health-check` / `bot-troubleshoot` skill，不用每次回來翻 `docs/DEPLOYMENT.md`。
