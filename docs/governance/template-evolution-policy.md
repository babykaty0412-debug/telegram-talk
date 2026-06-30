---
doc_type: governance
doc_id: GOVR-008
title: Template Evolution Policy & Validation History
status: accepted
version: "1.0"
date: 2026-06-29
related: [TMPL-001, GOVR-001, GOVR-002, GOVR-003, REV-MKT-001]
tags: [template, evolution, validation-history, governance, stability]
---

# Template Evolution Policy & Validation History

> Domain Template（TMPL-001）不是一次設計完成的文件，而是**由實戰持續演進**的活文件。  
> 每個新 Domain 在套用 Template 時，都會暴露 Template 的不足；這些不足回饋到 Template，使它越來越成熟。  
>
> 本文件定義 Template 的演進政策（什麼時候改、怎麼標記穩定度），並記錄完整的 **Validation History**——  
> 每一次 Template 修改是由哪個 Domain 的實戰驗證觸發、為什麼改、對未來 Domain 有什麼影響。

---

## 一、核心理念

| 理念 | 說明 |
|---|---|
| **實戰驅動** | Template 的修改必須來自真實 Domain 的套用，不是憑空想像的「可能需要」 |
| **持續演進** | Template 沒有「最終版本」；每個新 Domain 都是一次驗證機會 |
| **多方驗證** | 一個修改若只被一個 Domain 證明有用，可能只是該 Domain 的特殊需求，不足以成為通用基礎 |

---

## 二、Template 穩定度生命週期

每個 Template **版本**都有一個穩定度標記：

```
Experimental ──（第二個 Domain 驗證通過）──▶ Stable
```

### 穩定度定義

| 穩定度 | 意義 | 允許的操作 |
|---|---|---|
| **Experimental** | 修改來自單一 Domain 的實戰回饋，尚未被第二個 Domain 驗證 | 允許依後續 Domain 的回饋調整新增區塊（可能再改版）|
| **Stable** | 修改已被**至少 2 個不同 Domain** 驗證有價值 | 視為 PAOS 通用基礎，修改需走完整 review |

### 核心原則（GOVR-008-P1）

> **任何 Template 的修改，都必須至少由兩個不同 Domain 驗證過，才能標記為 Stable。**

**為什麼是 2 個 Domain？**

- 第一個 Domain（**Originator**）：發現缺口、提出修改 → 版本標記為 **Experimental**
- 第二個 Domain（**Validator**）：證明同一個修改對它也有價值 → 版本升級為 **Stable**

這避免 Template 因為第一個 Domain 的特殊需求而過度偏向它（例如過度偏向 Marketplace 的二手商品邏輯），  
確保 Template 真正成為整個 PAOS 的通用基礎，而非單一 Domain 的投影。

### 穩定度判定流程

```
Domain A 套用 Template，發現缺口
  ↓
修改 Template → 新版本標記 Experimental
  ↓
Domain A 對齊新版本（Originator 驗證：修改在 A 身上可用）
  ↓
[等待第二個 Domain]
  ↓
Domain B 套用 Template
  ↓
Domain B 是否也從這些修改獲益，且無需為 B 再大改？
  ↓ 是 → 版本升級 Stable（Validator 驗證通過）
  ↓ 否 → 依 B 的回饋調整 → 仍為 Experimental，等待下一個 Domain
```

---

## 三、Template Validation History

> 這不是 Changelog（「改了什麼」），而是 Validation History（「這個修改被哪些 Domain 驗證過」）。

### 演進路徑圖

```
TMPL-001 v1.0  (Stable)
   │
   │  套用於 ▶ Marketplace（第一個 Domain）
   │
   ▼
發現 4 個區塊缺口 + 1 個架構缺口（REV-MKT-001）
   │   · Repository Interfaces 未定義
   │   · Entity Status Lifecycle 未描述
   │   · Normalization Rules 位置矛盾
   │   · Event Catalogue 不完整
   │   · Auditable Operations 未宣告（架構 ARCH-06）
   ▼
TMPL-001 v1.1  (Experimental)  ◀── 你在這裡
   │   新增 §7 §8 §11 §14 §16；§12 加 AIProvider 約束；
   │   §19 改共用測試模板；§20 升級 Golden Sample
   │
   │  Originator 驗證 ▶ Marketplace 對齊 v1.1（進行中）
   │
   │  套用於 ▶ Stocks（第二個 Domain，預計）
   │
   ▼
Stocks 驗證這些區塊是否通用
   │   · 若全部通用且無需大改 → 升級
   │   · 若發現新缺口（預估 1–2 個）→ 調整後仍 Experimental
   ▼
TMPL-001 v1.2  (Stable)  ◀── 目標
   │   被 Marketplace + Stocks 雙重驗證的區塊正式成為通用基礎
   │
   │  套用於 ▶ Jobs / AI News / Real Estate ...
   ▼
持續演進（每個新 Domain 都可能觸發新版本）
```

### 版本驗證狀態表

| 版本 | 穩定度 | Originator | Validator | 驗證狀態 |
|---|---|---|---|---|
| v1.0 | Stable | （初版設計）| — | 基準版本 |
| v1.1 | **Experimental** | Marketplace（REV-MKT-001）| Stocks（待進行）| 等待第二個 Domain |
| v1.2 | （目標 Stable）| Marketplace | Stocks | 未開始 |

---

## 四、v1.1 變更明細（實戰驗證來源 + 原因 + 影響）

每一個 v1.1 的修改都可追溯到 Marketplace 的具體實戰發現。

### 變更 1：新增 §7 Repository Interfaces

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，ARCH-03（Minor）|
| **發現** | Marketplace 在 Workflow 中暗示了 Repository 模式（WatchRuleLoader），但從未正式定義 Repository 介面，實作者可能跳過抽象直接寫 SQL |
| **修改原因** | 沒有介面層級的規格，P-05（Repository Abstraction）無法在文件層級被驗證 |
| **對未來 Domain 的影響** | **全部受益**。任何持久化資料的 Domain 都需要 Repository 介面定義。Stocks（StockRepository）、Jobs（JobPostingRepository）等可直接套用 |

### 變更 2：新增 §8 Entity Status Lifecycle

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，§3.4 Template 缺口 |
| **發現** | Listing 有 active → sold/removed/unknown 的狀態流，但 Template 沒有地方正式描述狀態機 |
| **修改原因** | 狀態轉換是業務正確性的核心，缺少狀態機定義會導致「狀態被任意改寫」 |
| **對未來 Domain 的影響** | **部分受益**。有明確生命週期的 Entity 受益（Jobs：open→closed→expired；Real Estate：listed→sold）。純讀取型 Domain（AI News）可能標記為「無狀態流」 |

### 變更 3：新增 §11 Normalization Rules

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，EXT-02（Minor）+ R-02（高風險）|
| **發現** | ConditionNorm 同時出現在 Parser（硬編碼表）和 Knowledge（可更新 Rule），兩者矛盾 |
| **修改原因** | 必須明確定義映射規則的唯一權威位置；確立「會隨平台變動的映射放 Knowledge」原則 |
| **對未來 Domain 的影響** | **部分受益**。有「原始值→標準值」映射的 Domain 受益（Jobs：薪資範圍正規化；Real Estate：坪數/平方公尺換算）。無映射需求的 Domain 可標記 NA |

### 變更 4：新增 §14 Auditable Operations（Core 擁有格式）

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，ARCH-06（**Major**）+ MF-01 |
| **發現** | 外部 API 呼叫、通知發送、Knowledge 寫入、狀態變更等副作用操作沒有 Audit Log 規格 |
| **修改原因** | P-09（Audit Everything）的 Major 違反。**且 Audit 格式應由 Core 統一定義，不由各 Domain 自訂**——避免每個 Domain 的審計格式不一致 |
| **對未來 Domain 的影響** | **全部受益**。所有 Domain 都有副作用操作。此設計讓 Domain 只宣告「審計哪些操作」，格式與儲存由 Core 提供，未來新增 Domain 無需重新設計審計 |

### 變更 5：新增 §16 Event Catalogue

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，NAME-04（Minor）|
| **發現** | 只有 `marketplace.listing_status_changed` 正式命名，其他 Workflow 步驟間的 Event 隱含存在但未登記 |
| **修改原因** | COMPAT-01 要求 Event 用 Domain 前綴；缺少 catalogue 會讓實作者各自發明 Event 名稱 |
| **對未來 Domain 的影響** | **全部受益**。所有透過 Event Bus 通訊的 Domain（即全部）都需要登記 Event，避免命名衝突 |

### 變更 6：§12 Analyzers 加入 AIProvider 約束

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，ARCH-04（Minor）|
| **發現** | Analyzer 只說「模型偏好 claude-haiku」，未明確「必須透過 AIProvider 介面，不得直接 import SDK」|
| **修改原因** | P-07（No Direct AI SDK Calls）的約束對實作者不夠顯眼 |
| **對未來 Domain 的影響** | **全部受益**。所有使用 AI 的 Domain 都受此約束 |

### 變更 7：§19 Test Cases 改用共用測試模板

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，TEST-01（**Major**）+ MF-02 |
| **發現** | YahooAuctionParser、RutenListingParser、兩個 Analyzer 完全沒有測試；且測試覆蓋偏向 Shopee |
| **修改原因** | 每個 Parser / Analyzer 各自寫測試會遺漏覆蓋。改用 **Parser Test Template / Analyzer Test Template** 固定測試骨架，所有同類元件共用 |
| **對未來 Domain 的影響** | **全部受益**。Parser / Analyzer 是每個 Domain 的標準元件，共用測試骨架確保測試覆蓋一致、不遺漏 |

### 變更 8：§15→§20 Sample Data 升級為 Golden Sample

| 項目 | 內容 |
|---|---|
| **來源** | Marketplace REV-MKT-001，DATA-01/04（**Major**）+ MF-03 |
| **發現** | 範例資料只有孤立的 JSON，且 WatchRule 完全沒有範例 |
| **修改原因** | 升級為**完整管線 Golden Sample**（原始→前處理→Parser→Analyzer→Notification 全部保存），使 Replay 可直接重跑，同時作為 Golden Dataset 種子 |
| **對未來 Domain 的影響** | **全部受益**。完整管線快照讓 GOVR-007 Replay 與 GOVR-006 Golden Dataset 有一致的資料來源；含 OCR 前處理層特別利於未來圖片型來源（如 FB 貼文截圖）|

---

## 五、待 Stocks 驗證的問題清單

當第二個 Domain（Stocks）套用 v1.1 時，必須回答以下問題以決定能否升級 Stable：

| 驗證問題 | 對應區塊 | 通過標準 |
|---|---|---|
| Repository 介面定義方式對 Stocks 也適用？ | §7 | StockRepository 可用同樣的方法簽名風格定義 |
| Stocks 的 Entity 有明確狀態流可填入？ | §8 | 能填，或合理標記為「無狀態流」|
| Stocks 有 Normalization 需求且能放 Knowledge？ | §11 | 能填（如交易所代碼正規化），或合理標記 NA |
| Auditable Operations 宣告方式對 Stocks 也適用？ | §14 | Stocks 能用同樣方式宣告審計操作 |
| Event Catalogue 格式對 Stocks 也適用？ | §16 | StockEvent 能用同樣命名登記 |
| 共用測試模板對 Stock Parser/Analyzer 也適用？ | §19 | 測試骨架不需為 Stocks 大改 |
| Golden Sample 管線對 Stocks 也適用？ | §20 | 能捕捉 Stocks 的完整管線快照 |

> **若以上多數通過且 Stocks 無需為這些區塊大改 → v1.2 升級 Stable。**  
> 若 Stocks 暴露新缺口（預估 1–2 個），則調整後產出新的 Experimental 版本，等待下一個 Domain。

---

## 六、本政策對既有治理文件的關係

| 文件 | 關係 |
|---|---|
| TMPL-001 | 本政策管理 TMPL-001 的版本穩定度；TMPL-001 front matter 的 `stability` 欄位由本政策驅動 |
| GOVR-001（驗證清單）| Domain Review 發現的 Template 缺口，回饋到本政策的 Validation History |
| GOVR-002（審查流程）| Domain Review 是觸發 Template 演進的機制 |
| GOVR-003（成熟度模型）| Domain 的成熟度與 Template 的穩定度是兩條獨立的軸線 |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-29 | 初版：Template 穩定度生命週期（Experimental→Stable，2-Domain 驗證原則）、Validation History、v1.1 八項變更明細、Stocks 驗證問題清單 |
