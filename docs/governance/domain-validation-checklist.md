---
doc_type: governance
doc_id: GOVR-001
title: Domain Validation Checklist
status: accepted
version: "1.0"
date: 2026-06-27
related: [TMPL-001, GOVR-002, GOVR-003, GLOSS-001, ARCH-003, SYS-002]
tags: [domain, validation, checklist, quality]
---

# Domain Validation Checklist

> 本清單用於驗證 Domain 設計文件是否符合 PAOS 架構標準。  
> 使用方式：為每個 Domain 的每次正式審查複製一份填入，存放於 `docs/governance/reviews/{domain}-v{version}-level{n}-review.md`。

---

## 使用說明

### 嚴重度定義

| 嚴重度 | 意義 | 容忍上限 |
|---|---|---|
| **Blocker** | 必須修正，無例外。未通過 → 停止晉升 | 0 |
| **Major** | 必須修正；最多允許 2 個有文件說明的合理例外 | 2（需說明）|
| **Minor** | 應該修正；不影響晉升，但列入改善追蹤 | 不設上限 |

### Verdict 格式

```
✅ Pass   — 通過
❌ Fail   — 未通過（需說明原因）
⬜ NA    — 不適用（必須在備註欄說明原因）
```

### 晉升門檻

| 目標等級 | 必須通過的維度 | Blocker | Major 失敗上限 |
|---|---|---|---|
| **Level 1（Defined）** | TMPL + NAME + GLOSS | 0 | 0 |
| **Level 2（Validated）** | 所有 9 個維度 | 0 | ≤ 2（需文件化說明）|

---

## 審查元資料

| 欄位 | 填入 |
|---|---|
| Domain 名稱 | |
| Domain 文件路徑 | docs/architecture/domains/{domain}.md |
| 審查基準版本 | v |
| 目標晉升等級 | Level （ ）|
| 審查者 | |
| Final Approver | |
| 審查日期 | |
| 前次審查（若有）| |

---

## 維度一：Template Compliance（TMPL）

> 驗證 Domain 是否完整使用了 domain-template.md（TMPL-001）的 16 個必填區塊。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| TMPL-01 | 16 個必填區塊全部存在 | 所有章節標題存在，且每個區塊有實際內容（不是空白）| Blocker | | |
| TMPL-02 | 無模板佔位符殘留 | 不含 `{佔位符}`、`{XXX}`、`{Domain}` 等未替換的佔位文字 | Blocker | | |
| TMPL-03 | Front matter 必填欄位完整 | `doc_type`、`doc_id`、`title`、`status`、`version`、`date` 全部填入 | Blocker | | |
| TMPL-04 | doc_id 格式正確 | 格式為 `DOMAIN-XXX`（三位數字），在全局唯一 | Major | | |
| TMPL-05 | Changelog 區塊存在且有效 | 至少有初版（1.0）的記錄，日期格式正確 | Minor | | |

**TMPL 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度二：Naming Compliance（NAME）

> 驗證命名是否遵循 naming-convention.md（SYS-002）的所有規則。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| NAME-01 | 實體名稱使用 PascalCase | 所有資料模型實體（如 Listing、WatchRule）採 PascalCase | Major | | |
| NAME-02 | 元件名稱遵循 `{Domain}{Role}` 模式 | Collector、Parser、Analyzer 名稱有正確 Domain 前綴和 Role 後綴 | Major | | |
| NAME-03 | Workflow ID 使用 kebab-case | 所有 Workflow 識別碼為 kebab-case（如 marketplace-scan）| Minor | | |
| NAME-04 | Event 命名遵循 `{namespace}.{subject}_{past_verb}` | 事件名稱符合格式（如 marketplace.listing_matched）| Major | | |
| NAME-05 | 無禁止命名模式 | 不出現 Manager、Helper、XxxUtils、XxxBot（作為 AI 功能名稱）| Major | | |

**NAME 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度三：Glossary Compliance（GLOSS）

> 驗證所有術語使用是否與 glossary.md（GLOSS-001 v2.0）一致。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| GLOSS-01 | Glossary 已定義術語使用正確 | 沒有將 Agent、Worker、Event、Task 等核心術語用於非 Glossary 定義的含義 | Blocker | | |
| GLOSS-02 | Domain 新術語定義於 Core Concepts 區塊 | 所有 Domain 專屬概念（如 DealScore、WatchRule）在文件內有明確定義 | Major | | |
| GLOSS-03 | 未使用廢棄名稱 | 不出現 XxxBot（AI 功能）、XxxManager、StockBot 等廢棄模式（見 decision-log.md D-01~D-04）| Major | | |
| GLOSS-04 | 提供相關 ADR 交叉參考 | 設計決策有連結到對應的 ADR 編號（至少 2 個）| Minor | | |

**GLOSS 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度四：Architecture Compliance（ARCH）

> 驗證設計是否遵循 architecture-principles.md（ARCH-003）。

| ID | 原則 | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|---|
| ARCH-01 | P-02 | Event Bus 作為跨模組通訊骨幹 | Workflow 步驟之間透過 Event 傳遞，不直接呼叫另一個模組的函數 | Blocker | | |
| ARCH-02 | P-03 | Domain 隔離 | 無直接依賴或呼叫其他 Domain 的設計；跨 Domain 需求透過 Knowledge Service 或 Event Bus | Blocker | | |
| ARCH-03 | P-05 | Repository 抽象 | Collector、Analyzer 等元件不直接執行 SQL；資料存取透過 Repository 介面 | Major | | |
| ARCH-04 | P-07 | 不直接呼叫 AI SDK | Analyzer 的 AI 呼叫透過 AIProvider 介面，不直接 import Anthropic/OpenAI SDK | Major | | |
| ARCH-05 | P-08 | AI 輸出必須通過驗證 | Analyzer 輸出有對應的 Validator（至少 L1）才能進入 Knowledge 或觸發通知 | Major | | |
| ARCH-06 | P-09 | 所有 Action 可審計 | 有副作用的操作（寫入 Knowledge、觸發通知、外部 API 呼叫）有 Audit Log | Major | | |
| ARCH-07 | P-10 | 安全預設 | 高風險操作（購買、自動回覆等）設計為需要人工確認，不自動執行 | Major | | |
| ARCH-08 | P-11 | 單一所有權 | 每個核心實體有且只有一個 Owner 模組負責其生命週期 | Major | | |

**ARCH 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度五：Workflow Reusability（FLOW）

> 驗證 Workflow 步驟的可重用性、可測試性與獨立性。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| FLOW-01 | 每個 Workflow 步驟有明確的 Input / Output 型別 | 步驟規格表填寫了輸入型別和輸出型別（不是「取得資料」這種模糊描述）| Major | | |
| FLOW-02 | 觸發類型明確指定 | 每個 Workflow 的 Trigger Type（cron / event / user / api）已指定，cron 有 cron expression | Minor | | |
| FLOW-03 | 每個步驟有失敗行為說明 | 步驟失敗後的行為（retry / skip / abort workflow）有描述 | Major | | |
| FLOW-04 | 並行與序列步驟明確區分 | 可並行執行的步驟標記為 parallel，有明確依賴關係的步驟有序列說明 | Minor | | |

**FLOW 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度六：Extensibility（EXT）

> 驗證 Domain 能否在不破壞現有設計的情況下擴展。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| EXT-01 | 新資料來源（平台）可插拔 | 新增 Collector + Parser 即可接入新平台，不需修改 Core 或現有元件 | Major | | |
| EXT-02 | 業務規則設定透過 Knowledge 層管理 | 閾值、評分參數等設定儲存於 Knowledge，不是程式碼中的 hardcoded 常數 | Major | | |
| EXT-03 | 版本邊界表定義清楚 | V1 / V2 / V3 功能範圍有明確說明，新功能有對應的版本規劃 | Minor | | |
| EXT-04 | Future Extensions 區塊具體可執行 | 列出的未來功能有足夠的具體描述，而非泛泛的「也許未來會加 X」| Minor | | |

**EXT 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度七：Test Coverage（TEST）

> 驗證測試設計的完整性與有效性。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| TEST-01 | 核心元件有足夠的 Unit Test 案例 | 每個 Collector / Parser / Analyzer 至少 3 個單元測試描述 | Major | | |
| TEST-02 | 有端對端整合測試案例 | 至少 1 個覆蓋完整 Workflow 的整合測試場景 | Major | | |
| TEST-03 | 有 Edge Case 測試案例 | 至少 3 個邊界情況（空值、極端價格、狀態異常等）| Minor | | |
| TEST-04 | 有失敗情境測試案例 | 涵蓋網路失敗、API 錯誤、資料來源回傳空結果等情境 | Major | | |

**TEST 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度八：Sample Data Quality（DATA）

> 驗證範例資料是否足夠真實、完整，能支援未來的開發與測試。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| DATA-01 | Level 1 基礎範例存在 | 每個核心實體至少 1 筆真實、完整的範例資料 | Major | | |
| DATA-02 | Level 2 平台特定格式正確 | 範例資料反映真實平台格式（如蝦皮價格 ×100、Yahoo 拍賣的 condition 格式）| Minor | | |
| DATA-03 | Level 3 邊界案例範例存在 | 包含非典型情況（價格極低、condition 未知、賣家評分缺失等）| Minor | | |
| DATA-04 | 所有核心實體都有範例 | 每個主要資料實體（如 Listing、WatchRule、ListingAnalysis）都有對應範例 | Major | | |

**DATA 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 維度九：Future Domain Compatibility（COMPAT）

> 驗證此 Domain 能與未來新增的其他 Domain 和平共存，不造成命名衝突或架構假設。

| ID | 驗證項目 | Pass 標準 | 嚴重度 | Verdict | 備註 |
|---|---|---|---|---|---|
| COMPAT-01 | Event namespace 使用 Domain 前綴 | 所有 Event 名稱以 `{domain}.` 開頭，避免跨 Domain 命名衝突 | Major | | |
| COMPAT-02 | 資料庫 Table 名稱有 Domain 前綴 | 所有 SQLite Table 以 `{domain}_` 開頭（如 marketplace_listings）| Major | | |
| COMPAT-03 | Knowledge 條目有 Domain namespace | Knowledge key 格式為 `{domain}/{category}/...` | Minor | | |
| COMPAT-04 | 無「只有單一 Domain」的架構假設 | 設計不依賴「目前只有此 Domain 在運行」的隱性假設；多 Domain 並存時邏輯仍正確 | Major | | |

**COMPAT 小計**　Blockers: ___　Majors: ___　Minors: ___

---

## 總結評分表

| 維度 | Blocker (Fail) | Major (Fail) | Minor (Fail) | 整體 |
|---|---|---|---|---|
| TMPL Template Compliance | | | | |
| NAME Naming Compliance | | | | |
| GLOSS Glossary Compliance | | | | |
| ARCH Architecture Compliance | | | | |
| FLOW Workflow Reusability | | | | |
| EXT Extensibility | | | | |
| TEST Test Coverage | | | | |
| DATA Sample Data Quality | | | | |
| COMPAT Future Domain Compatibility | | | | |
| **合計** | | | | |

---

## 晉升判定

### Level 1（Defined）資格判定

| 條件 | 結果 |
|---|---|
| 總 Blocker 數 = 0 | ✅ / ❌ |
| TMPL 所有 Blocker 項目通過 | ✅ / ❌ |
| NAME 所有 Major 項目通過 | ✅ / ❌ |
| GLOSS-01 通過 | ✅ / ❌ |
| **Level 1 最終判定** | **Pass / Fail / Conditional** |

### Level 2（Validated）資格判定

| 條件 | 結果 |
|---|---|
| 已達到 Level 1 | ✅ / ❌ |
| 總 Blocker 數 = 0 | ✅ / ❌ |
| 所有維度 Major 失敗合計 ≤ 2 | ✅ / ❌ |
| Major 例外項目已有文件化說明（若有）| ✅ / ❌ / NA |
| 審查者已完成完整審查並填寫意見 | ✅ / ❌ |
| **Level 2 最終判定** | **Pass / Fail / Conditional** |

---

## Major 例外說明（若有）

> 若有 Major 項目填入「例外」而非修正，必須在此說明原因、風險評估與改善計劃。

| 項目 ID | 例外原因 | 風險評估 | 預計修正版本 |
|---|---|---|---|
| | | | |

---

## 審查者總體意見

> 整體評估：設計的優點、主要問題摘要、最重要的改進建議。

（填入）

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：9 個維度、33 個驗證項目、Level 1 + Level 2 晉升判定 |
