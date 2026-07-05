# E:\claude 工作環境 — 搬機遷移指南

> 把整個 `E:\claude` 工作環境搬到另一台電腦的完整步驟。
> ⚠️ **這份文件請另存一份在 USB / 手機**（雞生蛋問題：要照它才能把檔案弄到新機）。

搬機資料分**三類**，git 只涵蓋第一類：

| 類別 | 內容 | 搬法 |
|------|------|------|
| **A. 程式碼** | 13 個 git repo | 新機 `git clone` |
| **B. 機密檔** | token / 密碼 / env | **手動加密搬**（USB/加密），**絕不進 git** |
| **C. 機器特定** | Claude 設定、排程、雲端登入、硬編路徑 | 新機重建 |

---

## 0. 新電腦先裝這些

| 軟體 | 用途 | 備註 |
|------|------|------|
| **Git** + Git Credential Manager | 全部 repo | |
| **Node.js ≥ 22** | 前端 build、worker、舊 Express（`--experimental-sqlite`）| 建議用 nvm-windows |
| **Claude Code CLI** | 主工具 | |
| **wrangler**（`npx wrangler`）| Cloudflare Worker 部署 | 免全域裝 |
| **Python 3** + whisper 相依 | `whisper-voice.py` 語音 | 見該檔 import |
| **VS Code / Cursor** | 編輯器 | `cursor/` 有設定 |

> 🔑 **強烈建議新機也用 `E:\claude` 路徑、同一個 Windows 使用者名稱**。整個環境有大量硬編絕對路徑（`E:\claude\...`、`C:\Users\21030502\...`），路徑或帳號不同會**大範圍損壞**（排程、腳本、Claude 設定、launch.json）。**你這次就是不同路徑/帳號 → 務必照 §4f 的搜尋替換步驟做。**

---

## A. 程式碼 — git clone 清單

新機建 `E:\claude\`，逐一 clone（先在新機完成 GitHub 認證，見 §4d）：

```bash
# 工作環境根（含頂層腳本 / CLAUDE.md / notion 等非機密檔）
git clone https://github.com/babykaty0412-debug/telegram-talk.git E:/claude   # ⚠️ 見下方說明

cd E:/claude
git clone https://github.com/babykaty0412-debug/daily.git            daily
git clone https://github.com/babykaty0412-debug/fb-scheduler.git     fb-scheduler
git clone https://github.com/babykaty0412-debug/job-search.git       job-search
git clone https://github.com/babykaty0412-debug/multi-model.git      multi-model
git clone https://github.com/babykaty0412-debug/shopee-boost.git     shopee-boost
git clone https://github.com/babykaty0412-debug/stock-info.git       stock-info
git clone https://github.com/Hao0321/claude-skill-social-post.git    claude-skill-social-post

mkdir projects; cd projects
git clone https://github.com/babykaty0412-debug/Cocos.git            Cocos
git clone https://github.com/babykaty0412-debug/shanghao-web.git     shanghao
git clone https://github.com/babykaty0412-debug/shanghao-admin.git   shanghao-admin
git clone https://github.com/babykaty0412-debug/shanghao-worker.git  shanghao-worker
# 舊 Express 後端（已廢棄，要的話才 clone；新後台在 shanghao-admin 的 master，舊碼在 legacy-express 分支）
git clone https://github.com/babykaty0412-debug/shanghao-admin.git   shanghao-api
#   cd shanghao-api && git checkout legacy-express
```

> **⚠️ E:\claude 根是巢狀 git repo**：`E:\claude` 本身連到 `telegram-talk.git`，底下多個資料夾又是各自獨立的 repo（nested）。先 clone telegram-talk.git 成 `E:\claude`，再把上面各子 repo clone 進對應資料夾。子 repo 的資料夾已被根 repo `.gitignore`（或視為 untracked），互不干擾。

> **⚠️ `projects/player` 無 remote（純本機）**：git 拿不到，必須從舊機**手動複製整個資料夾**。或先在舊機幫它建 remote 再 push。

各 repo clone 後：`npm install`（有 `package.json` 的）。前台/後台要 `npm run build`。

---

## B. 機密檔 — 手動加密搬（絕不進 git）

以下檔案被 gitignore（正確），git clone **拿不到**，必須從舊機**手動安全搬**（USB / 加密壓縮）到新機對應路徑：

| 檔案 | 內容 | 備註 |
|------|------|------|
| `C:\Users\<你>\.claude\channels\telegram\.env` | **TG bot token** | 🔴 少了這個整個 TG bot 不能用，最關鍵 |
| `notion/config.js` | Notion API token | DB ID 350f5143… |
| `multi-model/config.js` | 多 AI API 金鑰 | ⚠️ GPT Codex token 曾被 server 端撤銷，見 memory |
| `projects/shanghao/.env.production` `.env.local` | `VITE_API_BASE`（worker 網址）| 非機密，可重建 |
| `projects/shanghao-admin/.env.production` `.env.local` | 同上 | |
| `projects/shanghao-worker/.dev.vars` | worker 本機開發 secrets | ⚠️ 機密 |
| `projects/shanghao-api/.env` | 舊 Express 的 JWT/密碼 | 已廢棄，通常不需搬 |

> **Cloudflare Worker 的正式 secrets**（`JWT_SECRET` / `ADMIN_PASSWORD` / `SETUP_TOKEN`）存在 Cloudflare 端，**無法匯出**。Worker 已上線，新機只要「用」它（前台 `.env` 指到同一個 workers.dev 網址）就好，**不需重設**。只有要「從新機重新部署 worker」時，才需在新機 `wrangler secret put` 重新輸入（你必須自己知道這些值）。

---

## C. 機器特定 — 新機重建

### 4a. Claude Code 設定（`C:\Users\<你>\.claude\`）
**要搬的**（複製這些子項到新機同路徑）：
- `settings.json`、`settings.local.json`（權限 / hooks / env）
  - ✅ hook 路徑用 `$env:USERPROFILE` / `$HOME`，**帳號不同也不用改**
- `CLAUDE.md`（在家目錄 `C:\Users\<你>\CLAUDE.md`，AI 行為規則）
- `hooks/`、`skills/`、`agents/`（自訂 hook/skill/agent）
- `plugins/`（**含 5 個已裝 marketplace，71MB**）：`claude-plugins-official`、`anthropic-skills`、`superpowers-marketplace`、`ui-ux-pro-max-skill`、`pua`
  - 啟用清單在 `settings.json` 的 `enabledPlugins`：frontend-design / example-skills / superpowers / ui-ux-pro-max / pua
  - 替代做法：不搬 `plugins/`，新機用 `git clone` 各 marketplace repo 重建（清單見 memory `installed_skills.md`）
- `projects\C--Users-<你>\memory\`（**記憶檔 + MEMORY.md**，24 檔，很重要）
- `launch.json`（preview server 設定）
- `channels\telegram\access.json`（TG 允許清單：誰能觸發 bot、哪些群組）+ `.env`（**bot token，機密，見 §B**）
  - ⚠️ **不要搬** `channels\telegram\bot.pid`（機器特定 PID，會自動重生）；`approved\` 空目錄可略

**不用搬**（機器特定 / 可重生，且很大）：
- `sessions/`、`history.jsonl`、`cache/`、`shell-snapshots/`、`file-history/`、`stats-cache.json`、`backups/`
- `projects\C--Users-<你>\*.jsonl`（**完整對話記錄 155MB**，除非你要保留歷史，否則不搬）

> ⚠️ memory 路徑含使用者名稱：`projects\C--Users-21030502\`。新機若帳號不同，資料夾名要跟著改（見 §5）。

> 📌 **家目錄有本機 git repo**（2026-06-30 建）：`C:\Users\21030502\.git` 只版控 `CLAUDE.md` + `memory/*.md`（白名單 gitignore 排除 jsonl/token）。**無 remote，純本機 rollback 用**。搬機時它幫不上忙（沒 remote 可 clone），memory + CLAUDE.md 仍照上面手動複製。搬完後新機可重新 `git init` 建自己的本機版控。

### 4b. Windows 排程（Task Scheduler）
本機有多個排程（早上自動化 / 蝦皮置頂 / TG 重啟 / Notion 日誌等）。
**逐一在新機重建** — 完整清單見 memory 檔 **`scheduled_tasks.md`**（含中文化改名對應）。
相關腳本在 `E:\claude` 頂層（`*.ps1` / `*.bat`）與各專案內。

> 🔴 **搬機過渡期鐵則：TG bot 一次只能一台開。** Telegram 一個 token 只允許一個 `getUpdates` 接收者，新舊機同時跑 bot 會互搶接收槽、狂 409。順序：**先確定舊機的 `多模型TG-Bot-開機啟動` + 守護排程已停（或舊機關機），再讓新機啟動 bot。** 別在兩台都開著時測 TG。
> 🔴 **蝦皮/早上自動化同理**：`ShopeeAutoPromo`、`Morning-*` 這類「對外動作」的排程，新機建好後**先確認舊機已停用**，否則兩台會重複執行（重複置頂、重複發文）。

### 4c. Cloudflare / wrangler
```bash
cd projects/shanghao-worker
npx wrangler login        # 瀏覽器授權
```
Worker 已部署、資料在 D1（雲端），新機**不需重新部署**即可用。要改 worker 程式才需 `npx wrangler deploy`（secrets 已在雲端，除非要改才 `secret put`）。

### 4d. GitHub 認證
第一次 `git clone`/`push` 會跳登入；用 Git Credential Manager 存 PAT（需 `repo` scope）。
> 舊機沒裝 `gh` CLI，靠 Git Credential Manager 存 token（見 memory `shanghao_site_rebuild.md` 的憑證備註）。

### 4e. MCP / 連接器重新授權
Claude 的 MCP 連接器（Notion / Gmail / Calendar / Canva 等）在新機要**重新 OAuth 授權**（token 不隨設定搬）。`mcp-needs-auth-cache.json` 只是快取。

### 4f. 硬編路徑相依 🚨【不同路徑/帳號必看】
大量腳本硬編 `E:\claude\...` 與 `C:\Users\21030502\...`。**同路徑同帳號最省事**；路徑或帳號不同時，照下面做全域搜尋替換。

**要替換的兩組字串：**
```
E:\claude          → <新根路徑，例如 D:\work\claude>
C:\Users\21030502  → C:\Users\<新帳號>
```

**Step 1｜先掃出所有命中位置（替換前先看清楚）**
```powershell
$root = "<新機的 E:\claude 對應路徑>"
Get-ChildItem $root -Recurse -Include *.ps1,*.bat,*.js,*.json,*.txt -File -ErrorAction SilentlyContinue |
  Select-String -Pattern 'E:\\claude|C:\\Users\\21030502' -List |
  Select-Object Path | Format-Table -AutoSize
```

**Step 2｜批次替換（先備份再跑；排除 node_modules/.git）**
```powershell
$root    = "<新根路徑>"
$oldRoot = 'E:\claude';         $newRoot = '<新根路徑>'
$oldUser = 'C:\Users\21030502'; $newUser = 'C:\Users\<新帳號>'
Get-ChildItem $root -Recurse -Include *.ps1,*.bat,*.js,*.json,*.txt -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\node_modules\\|\\.git\\' } |
  ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $n = $c.Replace($oldRoot,$newRoot).Replace($oldUser,$newUser)
    if ($n -ne $c) {
      [System.IO.File]::WriteAllText($_.FullName, $n, [System.Text.UTF8Encoding]::new($true))  # 保 BOM
      Write-Output "改了 $($_.FullName)"
    }
  }
```
> ⚠️ `.ps1`/`.bat` 改完務必保 **UTF-8 with BOM**（上面 script 已處理），否則排程跑出亂碼（見 §常見坑）。

**Step 3｜無法自動替換、必須手動的：**
| 項目 | 為何不能自動 | 怎麼做 |
|------|------------|--------|
| **Task Scheduler 排程** | 存在系統登錄不在檔案裡 | 全部**重建**，動作路徑填新路徑（清單見 memory `scheduled_tasks.md`）|
| **memory 資料夾名** `C--Users-21030502` | 資料夾名含帳號 | 改成 `C--Users-<新帳號>` |
| **`.claude\settings.local.json` 權限快取** | 含舊路徑字串 | 沒功能影響，下次跳 permission 重建即可 |

**Step 4｜替換後驗證沒漏：** 重跑 Step 1 的掃描指令，應**零命中**（node_modules/.git 除外）。

### 4g. 本機資料夾/檔案（❗非 git，clone 拿不到 → 必須手動整包複製）

`E:\claude` 根連到 `telegram-talk.git`，但它的 `.gitignore` 是「忽略全部、只白名單 8 個 bot 檔」。所以除了 §A 那 13 個子 repo，**其餘本機資料夾與鬆散檔 clone 全都拿不到**，會整包遺失。逐一手動複製（2026-07-01 實掃）：

| 本機資料夾 | 內容 | 檔數 |
|-----------|------|------|
| `docs\` | SOP 文件（主要參考資料）| 17 |
| `notion\` | Notion 自動日誌腳本 + Obsidian 同步（**含機密 `config.js`，見 §B**）| 63 |
| `journal\` | Obsidian vault（工作日誌本體）| 26 |
| `gmail\` | Gmail 自動化（`filters.xml` / `cleanup.gs` / `PLAN.md`）| 3 |
| `cursor\` | 編輯器設定 | — |
| `whisper-voice-package\` | 語音套件 | 4 |
| ~~`multi-model-backup-*`~~ / ~~`telegram-talk\`(空殼)~~ | 舊備份 / 空資料夾 | 不需搬 |

**根目錄鬆散檔**（clone 只帶白名單 8 檔，其餘手動複製）：
`CLAUDE.md`（E:\claude 工具根說明，重要）、`AGENTS.md`、`start-claude.ps1`、`開工.bat`、`whisper-voice.py` / `whisper-voice.bat`、`MIGRATION.md`（本指南，另存 USB）。
> 可略：`*.log`、`bot-heartbeat.txt`、`task_update.txt`（可重生）。

> 💡 **最保險的「完整」做法**：直接把**整個 `E:\claude`** 與**整個 `C:\Users\<你>\.claude`** 用 robocopy/USB **整包複製**到新機——連 `.git`、secrets、本機資料夾一次到位，不會漏。代價：① USB 要加密（含 token）② 體積大（對話 jsonl ~155MB、plugins ~71MB，可事後刪）。清爽派才走 §A clone + §B/§4g 手動補的分離法。

---

## 5. 搬機順序（建議）

1. 新機裝 §0 全部軟體
2. 完成 GitHub 認證（§4d）→ 依 §A clone 全部 repo 到 `E:\claude`
3. 手動搬 §B 機密檔 + §4g 本機資料夾（docs/notion/journal/gmail…）+ `projects/player`（無 remote）到對應路徑
4. 各 repo `npm install`；前台/後台 `npm run build`
5. 複製 §4a 的 `.claude` 設定 + 家目錄 `CLAUDE.md`
6. `wrangler login`（§4c）、重新授權 MCP（§4e）
7. 依 memory `scheduled_tasks.md` 重建排程（§4b）
8. 跑 §6 驗證

---

## 6. 搬機後驗證清單

- [ ] `git -C E:/claude/projects/shanghao status` 乾淨、能 `npm run build`
- [ ] 前台 `npm run dev` → `localhost:5180/shanghao/` 正常
- [ ] 後台 `npm run dev` → `localhost:5181/shanghao/admin/login` 能登入（用 `localhost` 不要 `127.0.0.1`）
- [ ] Claude Code 能讀到 memory（`MEMORY.md` 索引出現）、hooks/skills 生效
- [ ] `notion/config.js`、`multi-model/config.js` 已就位，對應腳本能跑
- [ ] §4g 本機資料夾都在：`docs\`(17)、`notion\`(63)、`journal\`(26)、`gmail\`(3)、`whisper-voice-package\`；根目錄 `CLAUDE.md`/`AGENTS.md`/`開工.bat` 也在
- [ ] 排程在 Task Scheduler 出現且路徑正確
- [ ] MCP 連接器重新授權完成

---

## 7. 整包 zip 完整備份（離線保險 / 舊機下架前）

git clone 是主策略（乾淨、只搬機密）。但若要**離線也能還原、連 node_modules/whisper 模型/session 歷史都保留**，做整包 zip：

**大小參考（實測 2026-06-30）：** `E:\claude` ≈ 2.74GB（whisper 模型 1.4G + 各 node_modules 可重裝）、`.claude` ≈ 230MB。

```powershell
# 機密小包（幾 KB，手動加密搬這個最重要）— 只裝 git 拿不到的機密檔
$secret = @(
  "E:\claude\notion\config.js",
  "E:\claude\multi-model\config.js",
  "E:\claude\projects\shanghao\.env.production",
  "E:\claude\projects\shanghao\.env.local",
  "E:\claude\projects\shanghao-admin\.env.production",
  "E:\claude\projects\shanghao-worker\.dev.vars",
  "E:\claude\projects\shanghao-api\.env"
)
Compress-Archive -Path $secret -DestinationPath "$env:USERPROFILE\Desktop\SECRETS-backup.zip" -Force

# 整包（大、可選）— 用 7-Zip 加密碼（.NET Compress-Archive 對 >2GB 不穩，改用 7z）
& "C:\Program Files\7-Zip\7z.exe" a -tzip -p"<設個密碼>" -mhe=on `
  "$env:USERPROFILE\Desktop\claude-full-backup.7z" "E:\claude" "$env:USERPROFILE\.claude"
```

> 🔒 **兩個包都含 token / 對話 / 私鑰 → 絕不上 git / 公開雲端**。用加密 USB 或私人雲端（個人 OneDrive）搬。
> 排除大檔加速：整包前可先刪各專案 `node_modules`（新機 `npm install` 重生）、whisper 模型（重下），能從 2.7G 降到幾百 MB。

---

## 附：各 repo 對應資料夾

| 本機資料夾 | GitHub repo |
|-----------|-------------|
| `E:\claude`（根）| babykaty0412-debug/**telegram-talk** |
| `daily` | daily |
| `fb-scheduler` | fb-scheduler |
| `job-search` | job-search |
| `multi-model` | multi-model |
| `shopee-boost` | shopee-boost |
| `stock-info` | stock-info |
| `claude-skill-social-post` | Hao0321/claude-skill-social-post |
| `projects\Cocos` | Cocos |
| `projects\shanghao` | shanghao-web（前台）|
| `projects\shanghao-admin` | shanghao-admin（後台）|
| `projects\shanghao-worker` | shanghao-worker（後端）|
| `projects\shanghao-api` | shanghao-admin 的 `legacy-express` 分支（舊 Express）|
| `projects\player` | ⚠️ 無 remote，手動複製 |
