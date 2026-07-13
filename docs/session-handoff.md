---
doc_type: handoff
doc_id: HANDOFF-001
title: PAOS Session Handoff（跨 Session / 跨裝置接手說明）
status: living
version: "1.0"
date: 2026-07-13
---

# PAOS Session Handoff

> 這份文件的用途：**當你在新的電腦、新的瀏覽器、或新的 Claude Code Session 接手 PAOS 時，讀完這一份就能無縫接續。**
>
> PAOS 的「記憶」不在任何單一對話裡，而在**這個 Git repo + 分支**。只要新 Session 指向同一個 repo / 分支，並先讀 `docs/index.md` 與本檔，就等於接續了先前所有進度。對話本身會消失，但 commit 過的內容不會。

---

## 0. 一句話現況

PAOS 已從「純文件架構設計」進入「**第一段可執行程式碼**」階段：Marketplace Domain 的 **Path A Lite MVP**（Facebook 二手書單篇貼文判斷）已經寫完、可執行、型別檢查通過；**唯一還沒完成的是用真實 AI Provider 跑一次並產出第一份正式 Product Validation Evaluation Report**（被 blocked，原因見 §4）。

---

## 1. 開發環境 / Git 座標

| 項目 | 值 |
|---|---|
| Repo | `babykaty0412-debug/telegram-talk` |
| 開發分支 | `claude/paos-platform-architecture-6lhcht` |
| 文件入口 | `docs/index.md`（**AI 接手一律從這裡開始**） |
| 專案規則 | `CLAUDE.md`（根目錄，OVERRIDE 一切預設行為） |
| 第一段程式碼 | `prototypes/marketplace-book-mvp/` |

新 Session 接手步驟：
1. 確認指向上述 repo / 分支。
2. 讀 `CLAUDE.md` → `docs/index.md` → 本檔（`docs/session-handoff.md`）。
3. 依 §5「下一步」決定要做什麼。

---

## 2. 目前 Milestone 狀態

| 項目 | 狀態 |
|---|---|
| 通用語言（Glossary / Concept Map / Naming / Principles）| ✅ Accepted（Principles v1.2，含 **P-14**） |
| 15 份 ADR | ✅ Accepted |
| Domain Template（TMPL-001）| ✅ v1.1（Experimental） |
| 治理框架（GOVR-001~009 + PV-MKT-001/002）| ✅ Accepted / In Progress |
| Marketplace Domain | ✅ Level 2（Validated） |
| **Path A Lite MVP（程式碼）** | ✅ 寫完、可執行、`tsc` 通過、`npm run dry` 通過 |
| **第一份正式 PV Evaluation Report** | ⏳ **BLOCKED** — 等真實 `npm start` 輸出 + ground-truth 確認（見 §4） |
| Stocks Domain | ⏳ 待開始（Template v1.1 的第二個 Validator） |

---

## 3. MVP 是什麼、放在哪、怎麼跑

**位置**：`prototypes/marketplace-book-mvp/`（README 有完整說明）

**目標（唯一）**：驗證 AI 能否正確判斷「一篇 Facebook 二手書貼文是否值得通知」。單平台（FB）、單品類（書）、無 DB / 無 Dashboard / 無排程。

**6 步管線**：parse（決定性）→ is_book（AI）→ 判價 deal_score/value_verdict（AI）→ WatchRule 比對（決定性）→ 通知決策 P1/P2/skip（決定性）→ confidence（AI）。

**關鍵架構**：所有 AI 存取都經過 `src/aiProvider.ts`（唯一 import 廠商 SDK 的檔案，符合 **P-07 seam**）。Provider / Model 由**執行環境**用環境變數決定：
- `MARKETPLACE_MVP_PROVIDER`（預設 `anthropic`）
- `MARKETPLACE_MVP_MODEL`（預設 `claude-haiku-4-5`，與 DOMAIN-001 §12 一致）

**怎麼跑**（在**本機**，非在 AI 對話裡）：
```bash
cd prototypes/marketplace-book-mvp
npm install
npm run typecheck          # 只做型別檢查
npm run dry                # 離線跑 parse→match→notify（stub 分析器，非真 AI）
export ANTHROPIC_API_KEY=...   # 真實跑才需要；絕不 echo、不 commit、不貼到對話
npm start                  # 真實 Product Validation 跑法
```

---

## 4. 為什麼「第一份 PV Report」被 Blocked（重要，勿誤觸）

決策路線：**Route 1 — 使用者在本機自行執行，API Key 永不交給 AI、永不出現在對話或文件**。三個理由（使用者原話）：
1. API Key 不應提供給 AI，也不應出現在對話或文件中。
2. PAOS 應遵循「Secrets 永遠留在執行環境」（P-14）。
3. Product Validation 應驗證的是**平台能力**，不是特定 API。

因此這個沙箱 / 任何 AI Session **沒有也不應該有** `ANTHROPIC_API_KEY`，無法自行執行 `npm start`。**AI 絕不可捏造 AI 判斷結果或任何指標。**

**要解除 Blocked 需要使用者提供兩樣東西**：
- (a) 本機 `npm start` 的**真實輸出**（每篇貼文的 is_book / value_verdict / deal_score / confidence）。
- (b) **Ground-truth 確認**：由人（非 AI）標注每篇 fixture 的正確答案（GOVR-006 要求標注獨立性）。

**已可誠實計算、與 API Key 無關的決定性指標**（先前已驗證）：
- Price Detection：**8/8（100%）**
- Watch Rule Match：**6/6（100%）**

**尚無法計算（等 (a)+(b)）**：is_book Accuracy、Deal Detection、Suspicious Detection、Notification Accuracy。

> 待使用者回傳 (a)+(b) 後，依其指定的 7 段格式產出報告：1. Executive Summary、2. Metrics、3. Misclassification Analysis、4. Rule Improvement（不可全歸因 Prompt）、5. Confidence Analysis、6. Product Value、7. Next Recommendation（只提 3 件）。這份會是 Marketplace 第一份正式 Product Validation Report。

---

## 5. 下一步（新 Session 三選一）

1. **推進 PV Report**：若使用者已備妥 §4 的 (a)+(b) → 產出第一份正式 PV Evaluation Report。
2. **啟動 Stocks Domain**：用 TMPL-001 v1.1 寫 Stocks Domain 設計，作為 Template 的第二個真實 Validator（GOVR-008 需要 2 個 Domain 才能把 Template 升 Stable）。
3. **升級 platform-blueprint.md**：目前 Draft v0.9 → 正式 v1.0。

（若使用者沒特別指定，先問要走哪一條；不要自行跨越 Execution Boundary。）

---

## 6. 絕不可違反的護欄（接手前必讀）

- **P-14 Secrets Never Leave the Runtime**：API Key / Token / 密碼 / 憑證只存在執行環境（環境變數或 Secret Manager）；**絕不寫入 Git、絕不寫入文件、絕不貼入 AI 對話、絕不硬編碼**。不得把 harness / OAuth token 拿去當 App 的 API 金鑰用。
- **P-09 / P-10**：AI 不可自動刪除資料、自動購買、自動發文；高風險動作需人類批准。
- **P-13 No New Domain Before Proven Value**：未證明價值前不新增 Domain。
- **GOVR-009 Execution Boundary**：以下四類**必須停下請 Owner 決策**——(1) 架構決策、(2) 新增 / 修改 ADR、(3) 修改 Template（TMPL-001）結構、(4) 新增 Core / 共用元件。其餘同一 Milestone 內可自主推進、commit、push。
- **GOVR-008**：共用規格需**至少兩個真實 Domain 的共同需求**驅動，不提前抽象化。
- **誠信**：**永不捏造** AI 執行結果或指標；沒有真實輸出就標記為「待執行」，只回報真正能算的決定性指標。

---

## 7. Git 操作慣例

- Commit 後 push：`git push -u origin claude/paos-platform-architecture-6lhcht`
- 未經明確要求**不開 PR**。
- 若指定分支的 PR 已被 merge：視為全新變更，從最新 default 分支 `git checkout -B` 同名分支重啟，不在已 merge 的歷史上疊 commit。

---

*本檔為 living document：每次 Session 交接、或 Milestone 狀態改變時更新 §0、§2、§4、§5。*
