---
name: bot-health-check
description: 檢查 telegram-talk 這個 Telegram bot 目前是否健康/正在運作。當使用者問「bot 還活著嗎」「bot 是不是壞了」「健檢一下」「check bot health」「bot 有沒有在跑」時使用。
---

# Bot 健康檢查

跑 repo 裡的 `bot-health.ps1`，並用白話解讀結果，不要只丟原始輸出。

## 步驟

1. 找到工具根目錄（預設 `E:\claude`，若不確定先確認 `Claude Telegram.bat` 在哪）。
2. 執行：
   ```powershell
   & <工具根>\bot-health.ps1
   ```
3. 讀 exit code 與輸出文字：
   - **exit 0 / ✅** → 直接回覆「bot 正常」，可附上 bot PID / bun PID / 最後心跳時間。
   - **exit 1 / ❌** → 讀輸出裡列出的原因（可能不只一條），對照下表白話解釋給使用者聽，並說明 watchdog 是否會自動處理。

## 原因對照（不要只念英文/程式術語）

| 健檢輸出的原因 | 白話 | 會自動好嗎 |
|---|---|---|
| bot 進程不存在 | bot 沒在跑 | 會，watchdog 10 分鐘內自動重啟 |
| 有 N 個 --channels 進程 | 開了重複的 bot，互搶接收槽 | 會，watchdog 會清掉重複的再重啟一個 |
| 沒有屬於自己的收訊進程(bun) | 殭屍狀態，收不到訊息 | 會，除非 bot 剛啟動不到 15 分鐘（此時是正常暖機） |
| bun 無 Telegram 連線 | 網路或剛啟動，還沒連上 | 通常會隨 poller 重啟一併解決 |
| bot.pid ≠ 實際 bun（提示） | 只是狀態檔沒同步，不影響運作 | 不需處理 |

## 若要更深入診斷

若使用者想知道「為什麼壞」或「怎麼修」，改用 `bot-troubleshoot` skill，或參考 `docs/TROUBLESHOOTING.md`。

## 注意

- 這是純本地結構檢查（WMI + TCP 連線），不會消耗 Claude 額度，也不用 bot 本身回覆來驗證。
- 別自己重新發明健檢邏輯（例如自己下 WMI 查詢）—— 一律呼叫 `bot-health.ps1`，它已經處理過三個踩雷（單元素解包、CommandLine 間歇 null、孤兒 bun），細節見 `docs/TROUBLESHOOTING.md`。
