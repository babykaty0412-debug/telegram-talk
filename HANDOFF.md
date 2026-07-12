# 交接：新 session / 雲端接手（TG bot）

> 給接手的 Claude / 新 session：**先讀這份**，再依需要讀 `README.md` 與本機 memory。
> 使用者原本在 Windows PC，正要改用雲端版，需接續 TG bot 的工作。

## 一句話現況
Windows PC 上跑的 Telegram bot（手機端對話 Claude）+ 守護排程。已穩定運作、腳本經**兩輪邏輯審查修正**、全部 push 到本 repo（`telegram-talk`）。

## 這個 session 做了什麼（重點）
- **修好「7 天無回應」根因**：互動 Claude Code session 會搶 Telegram 接收槽 → 全域 `enabledPlugins.telegram=false` + 專屬 bot 用 `--settings` 獨佔槽（`Claude Telegram.bat`）。**別用 `--plugin-dir`**（會 channel skipped）。
- **守護改「只看結構健康」**：移除「用心跳猜額度」的舊邏輯（安靜沒人傳訊時心跳本來就停，舊版每 5h 發假 ⏸️/🔄 洗版）。現在只在「進程死/重複 bot/poller 不在」才重啟。
- **兩輪審查修 10 個邏輯漏洞**（含我自己重構引進的 PowerShell 單元素解包誤判死、WMI CommandLine 間歇 null、孤兒 bun 誤判、bot-health TCP 只比 IPv4 漏判 Telegram IPv6 假❌、併發 double-restart race…）詳見 `README.md` 的「腳本踩雷」。
- **repo 做成完整遷移包**：`README.md` 有「🖥️ 新電腦部署」完整步驟。

## 現在狀態怎麼查（別憑記憶，壞的先說）
```
& E:\claude\bot-health.ps1     # → ✅ 正常 / ❌ 壞了+原因（結構檢查，不耗額度）
```
被問 bot 狀態時先跑這個再答。

## 待辦（接手後可做）
1. **每日 06:00 重啟排程尚未建立**（`Telegram-Bot每日六點重啟`）——需管理員 PowerShell，指令見 `README.md` 步驟 6。非必要（守護每 10 分鐘已在顧）。
2. **整台機器搬雲端**：見本機 `E:\claude\MIGRATION.md`（另一 session 寫的全機搬遷 SOP，含多機衝突鐵則）。

## 相關資料在哪
- **本 repo（GitHub `telegram-talk`，雲端可 clone）**：所有腳本 + `tg-check.ps1` hook 複本 + `README.md`（架構/部署/踩雷全在裡面）。
- **本機 memory（雲端可能讀不到，僅列供參考）**：
  - `telegram_bot_architecture.md` — TG bot 完整架構/根因/修法/踩雷/權限設定
  - `scheduled_tasks.md` — 所有 Windows 排程清單 + 多機衝突鐵則
  - `stock_info_sync.md` — TG 群組雙向同步（受本次 `enabledPlugins=false` 影響，發群組改用直接 API）
  - `MEMORY.md` — 全 memory 索引
- **Secrets（不在 repo，新機手動重建）**：`~\.claude\channels\telegram\.env`（bot token）、`~\.claude\channels\telegram\access.json`（allowlist / chat_id）。

## 沿用鐵則
- 改守護/健檢腳本前，先讀 `README.md`「腳本踩雷」：call site 一律 `@(Get-X).Count`、WMI null 重試 3 次、bun 別取 `-First 1`、TCP 看 **443** 不看 IP、併發要讓位。
- Git：push 前確認 commit short hash **不含「4」**；push 前給摘要等使用者 OK。
- 回報前**實測**貼證據；「改好了」要工具驗過才說。
