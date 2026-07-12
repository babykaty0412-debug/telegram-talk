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

---

# 交接：整機搬遷（MIGRATION.md）＋ 上好網站拆分（2026-07-13）

> 另一條工作線的交接（與上面 TG bot 交接並存）。本機 memory 對應檔：`migration_handoff.md`、`shanghao_site_rebuild.md`。

## 一句話現況
`MIGRATION.md`（整機搬遷總指南，本 repo 內）已寫完＋經 **24-agent 全面邏輯審查（27 條確認漏洞）**、文件面漏洞已全數修正並 push。上好網站已拆成 3 repo 且全部推上 GitHub，只剩 FTP 部署。

## 搬機這條線：已完成
- `MIGRATION.md` 進版控（白名單放行），涵蓋：repo clone 清單、機密檔手搬清單（含 TG token / Google OAuth token.json）、§4f 不同路徑帳號的全域替換 SOP（已修 PS5.1 ANSI 亂碼雷、雙反斜線/正斜線變體、`~\.claude` 第二掃描根）、§4g 非版控資料夾、§7 機密小包打包（已修同名攤平互蓋雷）
- 各 repo 未推缺口已清（job-search / multi-model 由各自 session 推掉）

## 搬機這條線：待使用者決定（新 session 請逐項確認再動）
1. 🚨 **telegram-talk repo 是 PUBLIC**（審查實測未登入可讀）——本檔與 MIGRATION.md 含環境細節、個人 chat_id。**建議使用者到 GitHub Settings 轉 private**（AI 不可代操作權限變更）
2. `projects/player` 零 commit 零 remote——要留就 init+建 repo push，不留就在 MIGRATION.md 標「不搬」
3. 家目錄 memory repo（`C:\Users\21030502\.git`）無 remote——要雲端化需建 **private** repo（memory 含個人工作脈絡）
4. `daily` 的 `podcast_state/episodes.json` 有未 commit 的播放進度——搬機前最後一刻 commit+push（屬「早上自動化凍結區」，動前先問）
5. Cursor 設定實際在 `%APPDATA%\Cursor`（`E:\claude\cursor\` 是空的，文件已更正）——搬機時要另外匯出
6. `shanghao-admin/.env.production` 已進 git（內容僅公開 worker 網址，文件已註記「保持非機密」）——若要改成 ignore+`git rm --cached` 再議

## 上好網站（shanghao）這條線：現況
- **拆分完成**：shanghao-web（前台，已去 Element Plus，CSS 465→107kB）／shanghao-admin（後台，Element Plus SPA，base=/shanghao/admin/）／shanghao-worker（後端 CF Workers，未動）。舊 Express 在 shanghao-admin.git 的 `legacy-express` 分支
- **待辦＝部署**：兩包 dist FTP 上智邦——前台 → `public_html/shanghao/`（先清空）、後台 → `public_html/shanghao/admin/`；上傳後驗 `.htaccess` 前後台互動（深層路由重整）。步驟見 shanghao-web repo 的 `DEPLOY.md`
- 踩雷備忘：dev 用 `localhost` 別用 `127.0.0.1`（worker CORS）；測 babykaty.com 要帶瀏覽器 UA（智邦擋無 UA 的 curl 回 500，別誤判成站掛了）

## 審查完整輸出（本機才有）
27 條發現全文（JSON，`result.confirmed`）：
`C:\Users\21030502\AppData\Local\Temp\claude\C--Users-21030502\f39ecf12-99e8-4471-a5a6-0a4a40055585\tasks\w3d443lv1.output`
