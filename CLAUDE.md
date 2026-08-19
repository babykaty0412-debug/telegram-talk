# E:\claude — 工具根目錄

## 目錄結構

```
E:\claude\
├── docs\        ← SOP 文件（17份）主要參考資料
├── notion\      ← Notion 自動日誌系統
│   ├── config.js          ← token（不可 git / 不可分享）
│   ├── auto-log.ps1       ← 排程觸發腳本（09:30 / 17:00）
│   ├── auto-log-prompt.txt← Claude headless prompt
│   ├── dashboard-update.js← 更新 Notion dashboard
│   ├── notion-to-obsidian.js ← 同步到 Obsidian vault
│   └── journal-to-notion.js  ← 本地日誌 → Notion（手動或由 auto-log.ps1 自動呼叫）
```

## 重要規則

- `config.js` 含 Notion token，**絕對不能 commit / 分享**
- `docs/` 是唯讀參考，不要修改原始 SOP 檔
- Notion DB ID：`350f5143-a2e6-8092-8266-d86c55a8ce5d`

## 常用指令

```powershell
# 手動觸發今天日誌
powershell -File "E:\claude\notion\auto-log.ps1" -TargetDay today

# 同步 Notion → Obsidian
node "E:\claude\notion\notion-to-obsidian.js" --days 7

# 手動同步本地日誌 → Notion（今天）
node "E:\claude\notion\journal-to-notion.js"

# 手動同步本地日誌 → Notion（最近 7 天）
node "E:\claude\notion\journal-to-notion.js" --days 7
```

## 關聯路徑

- Claude Code 設定：`C:\Users\21030502\.claude\`
- Obsidian vault / 工作日誌：`E:\claude\journal\YYYY-MM-DD.md`（唯一存放位置）
- 工作日誌 memory：`C:\Users\21030502\.claude\projects\C--Users-21030502\memory\`

## Telegram Channel 回應規則（Bot session 專用）

收到 `<channel source="telegram">` 訊息時，嚴格照以下順序：
1. **立刻**用 `react` 工具對該訊息加 👀 表情（讓使用者知道已收到、正在處理）
2. **立刻**觸發「輸入中…」狀態：`powershell -Command ". 'E:\claude\daily\common.ps1'; Send-TgTyping"`（顯示約 5 秒）
3. 執行任務。若任務預計超過 1 分鐘，先用 `reply` 回一句「⏳ 處理中：[做什麼]」
4. 長任務執行期間，每做完一個步驟就再呼叫一次 `Send-TgTyping`，讓「輸入中…」持續出現
5. 完成後用 `reply` 回報結果（編輯訊息不會推播，完成一定要用新 reply）
6. 失敗或卡住也要 reply 說明，不可無聲結束
7. **【必做・不可省略】每次 `reply` 回覆後，立刻更新心跳檔**——漏寫會害守護排程誤判額度耗盡、每隔幾小時亂重啟 Bot（使用者最痛的訊息疲勞來源）：
   `powershell -Command "Set-Content 'E:\claude\bot-heartbeat.txt' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8"`

### 啟動 / 健檢 / 架構（2026-06-25）

- **重啟 Bot 只用** `E:\claude\Claude Telegram.bat`（內含 `--settings "E:\claude\bot-settings.json"`）。**別手動跑 `claude --channels`**——全域 `enabledPlugins.telegram=false`，少了 `--settings` 會 `Channel notifications skipped`：收得到訊息卻不回。
- **健檢（判斷壞沒壞，不需回覆、不耗額度）**：`& E:\claude\bot-health.ps1` → `✅ 正常` / `❌ 壞了+原因`。被問狀態先跑這個再答。
- 收訊架構 / 搶接收槽根因 / `--plugin-dir` 陷阱：見 memory `telegram-bot-architecture`
- **⚠️ 2026-08-19 起：兩個守護排程已由使用者要求停用，bot 掛掉不會自動重啟。**
  發現 bot 沒回應時，先 `bot-health.ps1` 健檢，壞了要**手動**跑 `Claude Telegram.bat`。
  完整停用清單見 `README.md` →「刻意停用的排程」。

## 工作日誌規則

- 所有日誌統一存放在 `E:\claude\journal\`，格式 `YYYY-MM-DD.md`
- 日誌寫完後自動發 Telegram 通知（chat_id: 729844447）
- auto-log.ps1 執行順序：Claude 寫日誌 → 本地日誌→Notion → Dashboard → Notion→Obsidian
- 搜尋日誌時直接找 `E:\claude\journal\YYYY-MM-DD.md`，不需確認
