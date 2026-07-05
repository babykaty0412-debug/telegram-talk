# 故障排除

## 一眼健檢

```powershell
& <工具根>\bot-health.ps1
```

✅ = 正常（結構完整、獨佔接收槽、有在 poll）；❌ = 壞了，會附原因。原理見 `docs/ARCHITECTURE.md` 的單一 poller 限制。也可直接請 Claude 用 `bot-health-check` skill 跑並解讀。

## 失敗模式對照表

| 現象 / 健檢原因 | 意味著 | 誰會自動處理 |
|---|---|---|
| `bot 進程（claude --channels）不存在` | bot 沒在跑 | watchdog 每 10 分鐘會重啟（Layer 1） |
| `有 N 個 --channels 進程（應只有 1）` | 重複 bot，互搶接收槽 | watchdog 全清後重啟一個（Layer 2） |
| `bot 沒有屬於自己的收訊進程(bun server.ts)` | 殭屍：bot 活著但收不到訊息（poller 被搶或沒拉起來） | watchdog 判定殭屍後重啟（Layer 3，啟動 15 分鐘內不判定，避免誤殺） |
| `bun 無 Telegram 連線（149.154/91.108）` | bun 沒連上 Telegram，可能網路問題或剛啟動 | 健檢會重試一次再判定；watchdog 不特別處理，通常隨 poller 重啟一併解決 |
| `bot.pid ≠ 實際 bun`（提示，非致命） | pid 檔沒同步，不影響運作 | 無需處理 |
| watchdog log 出現 `[FAIL] All restart attempts failed` | 自動重啟 + `npm install -g @anthropic-ai/claude-code` 修復都失敗 | 無人處理，需手動介入（見下） |

## 手動介入

自動修復都失敗時，手動重啟：

```powershell
Start-Process 'cmd.exe' -ArgumentList '/c','"<工具根>\Claude Telegram.bat"' -WindowStyle Minimized
```

若 `claude` 指令本身壞掉（`claude --version` 失敗），先重裝：

```powershell
npm install -g @anthropic-ai/claude-code
```

日誌在 `<工具根>\telegram-watchdog.log`，先看最近幾行判斷是哪一層失敗。

## 腳本踩雷（改腳本前必看）

破壞性動作（重啟/發通知）前一定要防這三個，否則會發假警報或誤殺健康進程：

1. **PowerShell 單元素解包**：函式 `return @(...)` 只回 1 個會被解包成純量，call site 對它 `.Count` 會拿到空白 → 誤判成 0 個。**call site 一律 `@(Get-X).Count` 重新包成陣列**。
2. **`Win32_Process.CommandLine` 間歇 null**：WMI 查詢偶爾會在 CommandLine 欄位回 `null`，一次查不到不代表進程真的不在。**偵測 bot/bun 前重試 3 次**再下結論。
3. **bun 別取 `-First 1`**：機器上可能有孤兒 bun（不屬於這個 bot 的殘留進程），取第一個會選錯。**要沿 `ParentProcessId` 往上追祖先鏈，確認有沒有任一 `server.ts` bun 是這個 bot 的子孫**。

這三條在 `bot-health.ps1`、`telegram-watchdog.ps1`、`tg-check.ps1` 裡都已實作；新增或修改偵測邏輯時要延續同樣防護，否則容易在深夜發假警報或誤重啟健康 bot。

## 執行期檔案（不在版控、不用遷移）

`bot-heartbeat.txt`、`telegram-watchdog.log`、`bot.pid` —— 這些是執行期產生的狀態檔，換機器時不用複製，會自然重新產生。
