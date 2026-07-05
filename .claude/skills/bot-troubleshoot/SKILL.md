---
name: bot-troubleshoot
description: 診斷並修復 telegram-talk 這個 Telegram bot 的故障（健檢失敗、watchdog 一直發警報、重複開了兩個 bot、收不到訊息）。當使用者說「bot 壞了」「watchdog 一直警告」「怎麼修 bot」「bot 收不到訊息」時使用。
---

# Bot 故障排查

先確認核心限制：**一個 bot token 同時只能有一個 poller**，多數故障都是這條被破壞導致（見 `docs/ARCHITECTURE.md`）。

## 診斷順序

1. 先跑 `bot-health-check` skill（或直接 `& <工具根>\bot-health.ps1`），拿到具體原因，不要用猜的。
2. 看 `<工具根>\telegram-watchdog.log` 最近幾行，確認 watchdog 自己有沒有嘗試處理過、結果如何（`[DEAD]` / `[DUP-BOT]` / `[ZOMBIE]` / `[FAIL]`）。
3. 對照 `docs/TROUBLESHOOTING.md` 的失敗模式表，判斷是哪一類：
   - **進程不在**：watchdog 應該會在 10 分鐘內自動處理，不用手動介入，除非急著要立即恢復。
   - **重複 bot**：watchdog 會清掉多餘的重啟一個；若沒有自動處理，代表 watchdog 排程可能沒在跑，檢查排程本身。
   - **殭屍（無 poller）**：若剛啟動不到 15 分鐘屬正常暖機，超過還沒好才是真的異常。
   - **watchdog log 出現 `[FAIL] All restart attempts failed`**：自動修復（含 `npm install -g @anthropic-ai/claude-code`）都失敗，需要手動介入。

## 手動介入步驟

```powershell
# 1. 確認 claude 指令本身是否健康
claude --version

# 2. 若壞掉，重裝
npm install -g @anthropic-ai/claude-code

# 3. 手動重啟 bot
Start-Process 'cmd.exe' -ArgumentList '/c','"<工具根>\Claude Telegram.bat"' -WindowStyle Minimized

# 4. 等 60-70 秒後重新健檢
& <工具根>\bot-health.ps1
```

若手動重啟後仍然 ❌，把 `telegram-watchdog.log` 最近 20-30 行內容和 `bot-health.ps1` 的完整輸出一起看，逐條核對是不是新的失敗模式（不在 `docs/TROUBLESHOOTING.md` 現有表格裡），再決定是否要改腳本。

## 改腳本前務必遵守（避免修出新的假警報）

改 `telegram-watchdog.ps1` / `bot-health.ps1` / `tg-check.ps1` 或新增偵測邏輯前，一定要延續這三個既有防護（詳見 `docs/TROUBLESHOOTING.md` 「腳本踩雷」）：

1. PowerShell `@(...)` 單元素解包 → call site 一律 `@(Get-X).Count`。
2. `Win32_Process.CommandLine` 間歇 `null` → 偵測前重試 3 次。
3. 抓 bun poller 別用 `-First 1` → 沿 `ParentProcessId` 追祖先鏈確認屬於這個 bot。

不確定改動是否安全時，先在小範圍測試（例如只跑 `bot-health.ps1` 觀察輸出），別直接改動排程觸發的 `telegram-watchdog.ps1` 上線。

## Secrets 提醒

排查時可能會看到 token 路徑（`~\.claude\channels\telegram\.env`）—— 不要把內容貼進 log、commit 或訊息回覆裡。
