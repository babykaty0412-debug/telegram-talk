---
doc_type: governance
doc_id: REV-MKT-001
title: Marketplace Domain Level 2 Review Report
status: accepted
version: "1.0"
date: 2026-06-29
domain: marketplace
domain_doc: docs/architecture/domains/marketplace.md
domain_version: "1.0"
target_level: 2
reviewer: claude
final_approver: user
related: [DOMAIN-001, GOVR-001, GOVR-002, GOVR-003, TMPL-001, ARCH-003, SYS-002]
---

# Marketplace Domain — Level 2 Review Report

> **目的**：正式審查 Marketplace Domain（DOMAIN-001 v1.0）能否晉升至 Level 2（Validated），  
> 並評估其作為 PAOS 所有未來 Domain 參考架構（Golden Domain 候選）的適用性。
>
> **審查者**：claude（AI Architect）  
> **Final Approver**：user（System Owner）  
> **審查日期**：2026-06-29

---

## 審查元資料

| 欄位 | 值 |
|---|---|
| Domain 名稱 | Marketplace |
| Domain 文件路徑 | `docs/architecture/domains/marketplace.md` |
| 審查基準版本 | v1.0 |
| 目標晉升等級 | Level 2（Validated）|
| 審查者 | claude |
| Final Approver | user |
| 審查日期 | 2026-06-29 |
| 前次審查 | 無（首次正式審查）|

---

## 1. Executive Summary

### 整體評估

Marketplace Domain（DOMAIN-001 v1.0）是一份高品質的域設計文件，展示了清晰的業務邊界、完整的技術規格、以及對 PAOS 架構原則的整體遵循。16 個必填區塊全部填寫完整，沒有空洞章節。核心業務邏輯（Listing 生命週期、WatchRule 匹配、DealScore 計算、三層驗證）的設計具有足夠深度，可以直接指導實作。

這是一份**通過 Level 1（Defined）但尚未完全通過 Level 2（Validated）**的文件。審查發現 **3 個 Major 問題**，超過 GOVR-001 允許的 2 個上限。這些問題不涉及根本性設計錯誤，均可透過修補解決，因此建議為 **Conditional Pass**。

作為未來 Golden Domain 的候選，Marketplace 的 Workflow 骨架、Analyzer 模式和 Knowledge Schema 已具備足夠的抽象性；但 ConditionNorm、DealScore 邏輯和 WatchRule 結構仍高度綁定二手商品領域，需要在 domain-template.md 中明確區分「平台通用」與「Domain 特有」的設計元素。

### 是否建議進入 Level 2

**Conditional Pass** — 滿足以下 3 項修補後，可正式晉升 Level 2，無需重新全面審查。

### 目前最大的風險

1. **Audit Log 缺口（ARCH-06）**：外部 API 呼叫、通知發送、Knowledge 寫入等有副作用的操作，沒有明確的 Audit Log 規格。這是安全架構原則 P-09 的 Major 違反，若進入實作階段未補救，將在生產環境埋下不可追蹤的操作記錄。

2. **ConditionNorm 的位置模糊**：文件同時在 Parser（硬編碼表格）和 Knowledge（Rule 類型條目）中定義了 ConditionNorm，造成實作時可能的不一致——到底是 Parser 內建邏輯還是可更新的 Knowledge？這個模糊性在多個 Domain 套用模板時會被放大。

3. **測試覆蓋缺口**：YahooAuctionParser、RutenListingParser、ListingValueAnalyzer、ListingRiskAnalyzer 完全沒有設計層級的 Unit Test Cases，違反 TEST-01 Major 要求。

---

## 2. GOVR-001 九大維度 Review

---

### 維度一：Template Compliance（TMPL）

**評分：5 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| TMPL-01：16 個必填區塊全部存在 | ✅ Pass | 所有章節均有實質內容，無空白區塊 |
| TMPL-02：無模板佔位符殘留 | ✅ Pass | 全文無 `{佔位符}` 或 `{XXX}` 等未替換文字 |
| TMPL-03：Front matter 必填欄位完整 | ✅ Pass | doc_type, doc_id, title, status, version, date 全部填入 |
| TMPL-04：doc_id 格式正確 | ✅ Pass | `DOMAIN-001`，符合三位數字格式，全域唯一 |
| TMPL-05：Changelog 存在且有效 | ✅ Pass | 初版 1.0 記錄存在，日期格式正確 |

**評分理由**：Marketplace 文件是 domain-template.md 的完整實例化，每個區塊都有超過最低要求的內容深度。Template 驗證維度完全通過。

**Blockers: 0 / Majors: 0 / Minors: 0**

---

### 維度二：Naming Compliance（NAME）

**評分：3.5 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| NAME-01：實體名稱使用 PascalCase | ✅ Pass | Listing、WatchRule、ListingAnalysis、RiskFlag 全部 PascalCase |
| NAME-02：元件名稱遵循 `{Domain}{Role}` 模式 | ⚠️ Minor | 見下方說明 |
| NAME-03：Workflow ID 使用 kebab-case | ✅ Pass | marketplace-scan、listing-status-check、marketplace-daily-digest 均正確 |
| NAME-04：Event 命名遵循規範 | ⚠️ Minor | 見下方說明 |
| NAME-05：無禁止命名模式 | ✅ Pass | 無 Manager、Helper、XxxUtils、XxxBot 等禁止模式 |

**發現的問題**：

**NAME-02（Minor）**：Analyzer 命名不一致。Collectors 和 Parsers 使用來源名稱作前綴（`ShopeeSearchCollector`、`YahooAuctionParser`），而 Analyzers 使用實體名稱（`ListingValueAnalyzer`、`ListingRiskAnalyzer`）。兩種模式都合理，但在同一個 Domain 內混用降低了一致性。建議統一為 `MarketplaceValueAnalyzer`、`MarketplaceRiskAnalyzer`（與 Golden Dataset Specification GOVR-006 中 `MarketplaceValueAnalyzer` 的引用一致）。

**NAME-04（Minor）**：全文只正式命名了一個 Domain Event：`marketplace.listing_status_changed`。`workflow.triggered` 是 Core 事件（可接受），但 Domain 缺少正式的 **Event Catalogue**。Workflow 步驟間的其他 Event（如 `marketplace.listing_matched`、`marketplace.analysis_completed`）隱含存在但未命名，未來實作者需要自行發明名稱，可能造成不一致。

**WatchRuleLoader / WatchRuleMatcher（Minor）**：這兩個名稱不在 naming-convention.md 的命名決策樹中。`WatchRuleLoader` 語義上應是 Repository 查詢，`WatchRuleMatcher` 應是 Core Logic。建議在說明中明確其架構層（Repository / Domain Logic），避免被誤解為新的 Worker 類型。

**改善建議**：
1. 將 Analyzer 重命名為 `MarketplaceValueAnalyzer` / `MarketplaceRiskAnalyzer`（與 GOVR-006 一致）
2. 新增 **§4.5 Event Catalogue** 或類似小節，列出所有 Domain 發出的 Event 名稱

**是否符合 Acceptance Criteria**：Minor 問題，不影響 Level 2 晉升。

**Blockers: 0 / Majors: 0 / Minors: 3**

---

### 維度三：Glossary Compliance（GLOSS）

**評分：4.5 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| GLOSS-01：Glossary 已定義術語使用正確 | ✅ Pass | Worker、Event、Task、Agent 等核心術語使用符合 GLOSS-001 定義 |
| GLOSS-02：Domain 新術語在 Core Concepts 中定義 | ✅ Pass | Listing、WatchRule、DealScore、ConditionNorm 等 8 個域術語均有定義 |
| GLOSS-03：未使用廢棄名稱 | ✅ Pass | 無 XxxBot、XxxManager、StockBot 等廢棄模式 |
| GLOSS-04：提供相關 ADR 交叉參考 | ✅ Pass | front matter 含 7 個相關文件（ADR-0004/0005/0007/0008/0010/0011）|

**發現的問題**：

**GLOSS-04（Minor）**：文件內文中的 ADR 引用主要集中在 front matter，正文各區塊的設計決策未內嵌對應的 ADR 說明。例如 Section 9 提到 confidence 0.65 閾值，未解釋為何選此值或引用 ADR-0008；Section 12 的 Event Bus 觸發方式未引用 ADR-0014。雖然整體 ADR 覆蓋率通過，但內文層級的追蹤可以更強。

**是否符合 Acceptance Criteria**：通過。

**Blockers: 0 / Majors: 0 / Minors: 1**

---

### 維度四：Architecture Compliance（ARCH）

**評分：3 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| ARCH-01：Event Bus 作為跨模組通訊骨幹 | ✅ Pass | Scheduler 透過 `workflow.triggered` 啟動；狀態變更透過 `marketplace.listing_status_changed` |
| ARCH-02：Domain 隔離 | ✅ Pass | 無跨 Domain 直接呼叫；Finance Domain 邊界明確區分 |
| ARCH-03：Repository 抽象 | ⚠️ Minor | 見下方說明 |
| ARCH-04：不直接呼叫 AI SDK | ⚠️ Minor | 見下方說明 |
| ARCH-05：AI 輸出必須通過驗證 | ✅ Pass | L1/L2/L3 三層驗證完整定義，觸發條件和失敗處理明確 |
| ARCH-06：所有 Action 可審計 | ❌ Major | 見下方說明 |
| ARCH-07：安全預設 | ✅ Pass | 明確禁止自動出價/購買；L3 人工確認機制完整 |
| ARCH-08：單一所有權 | ✅ Pass | Listing、WatchRule、ListingAnalysis 均由 Marketplace 唯一管理 |

**發現的問題**：

**ARCH-06（Major）——Audit Log 缺口**：

文件中 Audit Log 只在 Collector 錯誤處理中偶爾提及（Section 7：「記錄到 Audit Log」），但對以下有副作用的操作**沒有明確的 Audit Log 規格**：

| 操作類型 | 操作 | 當前狀態 |
|---|---|---|
| 外部 API 呼叫 | 每次 Shopee/Yahoo/Ruten HTTP 請求 | 未規定是否記錄 |
| 通知發送 | P1/P2 Telegram 通知 | 未規定是否記錄 |
| Knowledge 寫入 | 新增/更新 MarketPrice、CategoryThresholds | 未規定是否記錄 |
| Listing 狀態變更 | active → sold/removed | 未規定是否記錄 |

根據 P-09（Audit Everything）和 ADR-0009，所有有副作用的操作必須寫入 Audit Log。這是對架構原則優先級最高的 P-09 的 Major 違反。

**ARCH-03（Minor）——Repository 介面未正式定義**：

文件在 Workflow 中用「WatchRuleLoader [Repository Query]」暗示了 Repository 模式，但沒有正式定義 `ListingRepository`、`WatchRuleRepository`、`ListingAnalysisRepository` 等介面。在文件層級未規定 Repository 邊界，實作者可能跳過 Repository 抽象直接寫 SQL，違反 P-05。

**ARCH-04（Minor）——AIProvider 介面約束未明確**：

Section 9 Analyzers 只說「AI 模型偏好: claude-haiku-4-5」，未明確說明 `ListingValueAnalyzer` 和 `ListingRiskAnalyzer` 必須透過 `AIProvider` 介面呼叫，不能直接 import Anthropic SDK。對於將此文件作為實作參考的工程師，這個約束不夠顯眼。

**改善建議**：
1. **必須修正（ARCH-06）**：新增 **§4.6 Audit Log 規格** 或在各相關區塊明確列出哪些操作必須寫入 Audit Log，包含格式建議（operation_type, domain, entity_id, action, actor, timestamp, result）
2. **建議改善（ARCH-03）**：在 Section 6 Data Model 後新增 Repository Interface 概要（至少列出方法簽名）
3. **建議改善（ARCH-04）**：在 Section 9 Analyzers 加入一行警告：「實作必須透過 AIProvider 介面，不得直接 import Anthropic SDK（P-07）」

**是否符合 Acceptance Criteria**：**不符合（1 Major fail）**。ARCH-06 必須修正。

**Blockers: 0 / Majors: 1（ARCH-06）/ Minors: 2（ARCH-03、ARCH-04）**

---

### 維度五：Workflow Reusability（FLOW）

**評分：4 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| FLOW-01：每步驟有明確 Input/Output 型別 | ✅ Pass | marketplace-scan 的 7 個步驟均有輸入輸出說明；listing-status-check 稍簡略但可接受 |
| FLOW-02：觸發類型明確指定 | ✅ Pass | 三個 Workflow 均有 Scheduled 觸發 + 完整 cron expression |
| FLOW-03：每步驟有失敗行為說明 | ⚠️ Minor | 見下方說明 |
| FLOW-04：並行與序列步驟明確區分 | ✅ Pass | Step 2、3、5 明確標示「並行執行」 |

**發現的問題**：

**FLOW-03（Minor）**：`marketplace-scan` 的 Step 3（Parsers）、Step 4（WatchRuleMatcher）、Step 6（L1 Validator）、Step 7（Notification Dispatcher）缺少失敗行為描述。只有 Step 2（Collectors）明確說明了失敗後「繼續其他平台」的行為。若 Parser 失敗或 WatchRuleMatcher 拋出異常，Workflow 是中止還是跳過該 Listing？這個模糊性在實作時必須填補。

**正面評價**：

`marketplace-scan` 的 7 步驟結構（Load → Collect → Parse → Match → Analyze → Validate → Notify）是一個優秀的可重用骨架。這個模式可以被其他任何「監控型 Domain」直接套用，只需替換 Collector/Parser/Analyzer/Matcher 的具體實作。

**Blockers: 0 / Majors: 0 / Minors: 1**

---

### 維度六：Extensibility（EXT）

**評分：4 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| EXT-01：新資料來源可插拔 | ✅ Pass | 新增 Collector + Parser 即可接入新平台，設計清晰 |
| EXT-02：業務規則透過 Knowledge 管理 | ⚠️ Minor | 見下方說明 |
| EXT-03：版本邊界定義清楚 | ✅ Pass | V1/V2/V3 功能表完整，邊界清晰，包含「永不做」的明確說明 |
| EXT-04：Future Extensions 具體可執行 | ✅ Pass | Section 16 的 V2/V3 計劃和已知限制均有足夠具體描述 |

**發現的問題**：

**EXT-02（Minor）——ConditionNorm 位置模糊**：

文件在兩個地方定義了 ConditionNorm：
- Section 8（Parsers）：以靜態表格形式定義，看起來是 Parser 的內建邏輯
- Section 13（Knowledge）：列為 Rule 類型知識條目，更新方式為「版本更新」

這個矛盾導致關鍵問題：ConditionNorm 是**可更新的 Knowledge（當蝦皮改變描述格式時，使用者可修改）**，還是**硬編碼在 Parser 裡的映射表（只能透過版本升級更新）**？這個模糊性是設計債，在實作時必須選一個方向。

> **建議**：明確定義 ConditionNorm 屬於 Knowledge 層（可更新），Parser 從 Knowledge 載入映射，而非硬編碼。

**Blockers: 0 / Majors: 0 / Minors: 1**

---

### 維度七：Test Coverage（TEST）

**評分：2.5 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| TEST-01：核心元件有足夠 Unit Tests | ❌ Major | 見下方說明 |
| TEST-02：有端對端整合測試 | ✅ Pass | TC-MKT-I01~I05 覆蓋完整 Workflow、去重、通知觸發、Cooldown、Collector 失敗 |
| TEST-03：有 Edge Case 測試 | ✅ Pass | 5 個邊界案例（全平台不可用、AI 超時、特殊字元、零元商品、raw_hash 變更）|
| TEST-04：有失敗情境測試 | ⚠️ Minor | 網路失敗和 AI 超時有覆蓋，但 AI 輸出格式錯誤/解析失敗情境未定義 |

**發現的問題**：

**TEST-01（Major）——多個核心元件缺少 Unit Test Cases**：

| 元件 | 現有 Test Cases | 要求（≥ 3）| 缺口 |
|---|---|---|---|
| `ShopeeListingParser` | TC-U01~U04（4 筆）| ≥ 3 | ✅ 達標 |
| `WatchRuleMatcher` | TC-U05~U07（3 筆）| ≥ 3 | ✅ 達標 |
| `L1 Validator` | TC-U08（1 筆）| ≥ 3 | ❌ 缺 2 筆 |
| `YahooAuctionParser` | 0 筆 | ≥ 3 | ❌ 完全缺失 |
| `RutenListingParser` | 0 筆 | ≥ 3 | ❌ 完全缺失 |
| `ListingValueAnalyzer` | 0 筆 | ≥ 3 | ❌ 完全缺失 |
| `ListingRiskAnalyzer` | 0 筆 | ≥ 3 | ❌ 完全缺失 |

測試覆蓋率嚴重偏向 Shopee 平台，YahooAuction、Ruten 的解析邏輯和 AI 分析器完全沒有設計層級的測試規格。這對一個目標成為 Golden Domain 的設計文件是重大缺口。

**TEST-04（Minor）**：沒有測試 AI 回傳非預期格式（如 JSON schema 不符合、缺少必填欄位）的情境。L1 Validator 的 schema 驗證邏輯無對應測試。

**改善建議**：
1. 必須補充 `YahooAuctionParser`、`RutenListingParser` 各至少 3 個 Unit Test Cases
2. 必須補充 `ListingValueAnalyzer`（測試 DealScore 計算）、`ListingRiskAnalyzer`（測試 risk_flags 識別）各至少 3 個 Unit Test Cases
3. 補充 `L1 Validator` 至少 2 個 Unit Tests（confidence < 0.65、price_suspiciously_low 邊界值）

**是否符合 Acceptance Criteria**：**不符合（1 Major fail）**。TEST-01 必須修正。

**Blockers: 0 / Majors: 1（TEST-01）/ Minors: 1（TEST-04）**

---

### 維度八：Sample Data Quality（DATA）

**評分：3 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| DATA-01：每個核心實體至少 1 筆完整範例 | ❌ Major | WatchRule 實體完全缺少範例資料 |
| DATA-02：平台特定格式正確反映 | ✅ Pass | Shopee price ×100 轉換（89000 → NT$890）在原始資料和解析後資料中均有展示，補充說明清楚 |
| DATA-03：邊界案例範例存在 | ⚠️ Minor | 只有正常情境的 happy path 範例，無異常情境（低價商品、condition_raw 無法映射等）|
| DATA-04：所有核心實體都有範例 | ❌ Major | WatchRule 缺失（與 DATA-01 同一問題）|

**發現的問題**：

**DATA-01 / DATA-04（Major）——WatchRule 範例缺失**：

文件提供了 `Listing`（原始格式 + 解析後 + 分析後）的完整三階段範例，但 `WatchRule` 這個重要實體完全沒有範例資料。WatchRule 是驅動整個系統的核心輸入（決定哪些 Listing 被分析、如何通知），缺少範例會讓實作者對使用者介面的預期輸入格式無從參考。

> 注意：DATA-01 和 DATA-04 指向同一缺口（WatchRule 無範例），在計算 Major 數量時視為 **1 個 Major**。

**DATA-03（Minor）**：範例資料都是理想情境。建議補充：
- 一筆 condition_raw 無法映射（`unknown`）的範例
- 一筆 suspicious 情境（price < market_price × 0.35）的 Analyzer 輸出

**改善建議**：
1. 必須新增 WatchRule 的完整範例 JSON（包含 keywords、max_total_price、min_condition、platforms 等所有欄位）
2. 建議補充 1 筆異常情境的 Analyzer 輸出範例

**是否符合 Acceptance Criteria**：**不符合（1 Major fail）**。DATA-01/04 必須修正。

**Blockers: 0 / Majors: 1（DATA-01/04）/ Minors: 1（DATA-03）**

---

### 維度九：Future Domain Compatibility（COMPAT）

**評分：4.5 / 5**

| 項目 | Verdict | 說明 |
|---|---|---|
| COMPAT-01：Event namespace 使用 Domain 前綴 | ✅ Pass | `marketplace.listing_status_changed` 使用正確 namespace |
| COMPAT-02：DB Table 有 Domain 前綴 | ✅ Pass | marketplace_listings、marketplace_watch_rules、marketplace_listing_analyses 均有前綴 |
| COMPAT-03：Knowledge 條目有 Domain namespace | ✅ Pass | `marketplace.{category}.market_price` 格式正確；Schema 中 `domain: 'marketplace'` 欄位存在 |
| COMPAT-04：無單一 Domain 架構假設 | ✅ Pass | 文件不假設 Marketplace 是唯一 Domain；Finance Domain 邊界明確 |

**發現的問題**：無 Major/Blocker 問題。

**COMPAT-03（Minor）**：Knowledge 條目的 namespace 在文件中使用了兩種格式：
- 點分隔：`marketplace.{category}.market_price`（Section 9）
- 斜線分隔：`marketplace/{category}/...`（GOVR-001 COMPAT-03 的 Pass 標準描述）

建議在文件中統一為一種格式並與 GOVR-001 對齊。

**Blockers: 0 / Majors: 0 / Minors: 1**

---

## 總結評分表

| 維度 | 評分 | Blocker | Major | Minor | 結論 |
|---|---|---|---|---|---|
| TMPL Template Compliance | 5 / 5 | 0 | 0 | 0 | ✅ Pass |
| NAME Naming Compliance | 3.5 / 5 | 0 | 0 | 3 | ✅ Pass（有改善空間）|
| GLOSS Glossary Compliance | 4.5 / 5 | 0 | 0 | 1 | ✅ Pass |
| ARCH Architecture Compliance | 3 / 5 | 0 | 1 | 2 | ❌ Conditional |
| FLOW Workflow Reusability | 4 / 5 | 0 | 0 | 1 | ✅ Pass |
| EXT Extensibility | 4 / 5 | 0 | 0 | 1 | ✅ Pass |
| TEST Test Coverage | 2.5 / 5 | 0 | 1 | 1 | ❌ Conditional |
| DATA Sample Data Quality | 3 / 5 | 0 | 1 | 1 | ❌ Conditional |
| COMPAT Future Domain Compatibility | 4.5 / 5 | 0 | 0 | 1 | ✅ Pass |
| **合計** | **3.7 / 5** | **0** | **3** | **11** | **Conditional Pass** |

**Level 2 晉升門檻**：Blocker = 0（✅）、Major ≤ 2（❌ 目前 3 個）

---

## 3. Reusability Assessment

> 評估 Marketplace 作為 Golden Domain 候選的可重用性：哪些設計已夠抽象，哪些仍過度綁定二手商品邏輯。

### 3.1 已足夠抽象的元素

這些元素可以**直接套用**到 Stocks、Jobs、AI News、Real Estate Domain，無需修改 Template。

| 抽象元素 | 可重用性 | 說明 |
|---|---|---|
| **Collector + Parser 分離模式** | ⭐⭐⭐⭐⭐ | 任何 Domain 都需要「取得原始資料」+「解析為結構化格式」的兩層設計，來源無關性強 |
| **Analyzer 三要素（Input/Output Schema + Confidence + Knowledge 依賴）** | ⭐⭐⭐⭐⭐ | AI 分析器的設計模式（模型偏好、Prompt 策略、confidence 門檻、L1/L2 升級）適用所有 AI-driven Domain |
| **L1/L2/L3 三層驗證梯** | ⭐⭐⭐⭐⭐ | 自動驗證 → 交叉驗證 → 人工確認的架構是通用的，可直接套用到任何 Domain |
| **Workflow 骨架（Load → Collect → Parse → Match → Analyze → Validate → Notify）** | ⭐⭐⭐⭐⭐ | 七步驟骨架是「監控型 Domain」的通用模板，只需替換各步的具體元件 |
| **Knowledge Schema 基礎結構** | ⭐⭐⭐⭐ | `{domain}/{topic}/content/confidence/requires_approval` 的知識條目格式是通用的 |
| **Notification Rules 表結構** | ⭐⭐⭐⭐ | P1/P2/P3 優先級 + Cooldown 設計適用所有通知型 Domain |
| **Business Rules ID 命名體系（BR-XXX-NN）** | ⭐⭐⭐⭐ | 資料有效性規則 / 業務邏輯規則 / 限制規則的三分類體系是通用的 |
| **版本邊界表（V1/V2/V3 功能範圍）** | ⭐⭐⭐⭐ | 所有 Domain 都需要版本邊界管理，格式可直接複用 |

### 3.2 過度綁定 Marketplace 的元素

這些元素**不應出現在 domain-template.md**，或應有明確的「Domain-specific，請替換」標記。

| 綁定元素 | 問題 | 影響範圍 |
|---|---|---|
| **ConditionNorm（五級物品狀況）** | new/like_new/good/fair/poor 是二手實物商品的特有概念。股票沒有「物品狀況」，職缺有「緊急程度」不是「狀況」 | 不適用 Stocks、Jobs；Real Estate 需要改版 |
| **DealScore / PriceRatio 計算邏輯** | DealScore 建立在「商品售價 / 市場行情」基礎上。新聞 Domain 的評分基於「重要性 + 可信度」，完全不同 | 不適用 AI News、Jobs |
| **WatchRule 的 min_condition / max_total_price 欄位** | 這兩個欄位是二手商品監控特有的。Stocks WatchRule 應有 target_price、price_change_ratio | 其他 Domain 需要完全替換 WatchRule 欄位定義 |
| **CategoryThresholds（great_deal / good_deal / suspicious_ratio）** | 基於價格比率的類別門檻適用於商品定價，不適用於新聞分析或職缺評估 | 不適用 AI News、Jobs |
| **平台反爬蟲規則（30 秒間隔、隨機 User-Agent）** | Scraping 相關的技術限制是 Marketplace 特有的。使用官方 API 的 Domain（如 Stocks）不需要這些規則 | Stocks（API）、AI News（RSS/API）不需要 |
| **RiskFlag 類型（price_suspiciously_low, condition_mismatch, possible_replica）** | 詐騙偵測邏輯是二手交易特有的。AI News Domain 的風險標記應是 `unverified_claim`、`source_bias` | 其他 Domain 需要定義自己的 RiskFlag 類型 |
| **Sold Detection Workflow** | `listing-status-check` 偵測商品是否售出或下架，是電商列表特有的生命週期管理。股票有不同的失效邏輯 | 不適用 Stocks、AI News |

### 3.3 各 Domain 的可重用率評估

| 未來 Domain | 可重用元素比例 | 需完全重設計的元素 | 整體評估 |
|---|---|---|---|
| **Stocks（股票追蹤）** | ~65% | DealScore 邏輯、ConditionNorm、WatchRule 欄位、Sold Detection | 骨架可用，核心概念需替換 |
| **Jobs（職缺監控）** | ~55% | 所有價格相關邏輯、ConditionNorm、sold detection | 工作流程可用，分析維度不同 |
| **AI News（新聞摘要）** | ~50% | 所有價格邏輯、ConditionNorm、WatchRule、Sold Detection | Collector/Parser 可用，Analyzer 需重新設計 |
| **Real Estate（房地產）** | ~70% | 平台特定爬蟲規則、少量 ConditionNorm 調整 | 最接近，條件評估概念可繼承 |

### 3.4 Template 需要修補的缺口

Marketplace 的開發過程揭示了 domain-template.md 遺漏的兩個區塊，建議在 TMPL-001 中補充：

| 遺漏區塊 | 說明 | 優先級 |
|---|---|---|
| **§X. Domain-specific Normalization Rules（可選）** | 描述 Domain 的標準化映射規則（如 ConditionNorm、CurrencyNorm）以及這些規則是 Knowledge 驅動還是 Parser 內建。若是 Knowledge 驅動，說明 Schema 和更新流程 | 高 |
| **§X. Entity Status Lifecycle（可選）** | 以狀態機圖描述主要 Entity 的狀態轉換（如 active → sold/removed/unknown），以及觸發轉換的 Event | 中 |
| **§X. Event Catalogue（建議）** | 列出 Domain 發出的所有 Event 名稱、payload 結構、觸發條件 | 中 |
| **§X. Repository Interfaces（建議）** | 列出資料存取介面的方法簽名，確保實作者遵循 P-05 | 中 |

---

## 4. Architecture Risks

### 高風險（建議在 Level 2 修補前處理）

| 風險 | 描述 | 影響 | 緩解方向 |
|---|---|---|---|
| **R-01：Audit Log 缺口（P-09 違反）** | 外部 API 呼叫、通知發送、Knowledge 寫入等操作未規定 Audit Log 格式，實作階段可能跳過審計 | 生產環境無法追蹤哪些通知被發送、哪些 Knowledge 被修改，違反安全架構原則 | 在 §4（Business Rules）或新增 §4.6 定義哪些操作寫入 Audit Log，及欄位格式 |
| **R-02：ConditionNorm 雙重定義（EXT-02）** | ConditionNorm 同時存在於 Parser（靜態表）和 Knowledge（可更新 Rule），兩者邏輯衝突 | 實作時選一個，另一個就成為廢棄設計。若選錯（hardcode），蝦皮格式更新後需要版本升級才能修正 | 明確宣告 ConditionNorm 屬於 Knowledge 層（可熱更新），Parser 從 Knowledge Service 載入 |
| **R-03：反爬蟲脆弱性** | Shopee/Yahoo/Ruten 無官方 API，依賴頁面爬蟲。任何平台 UI 更新都會造成 Parser 失效，無 fallback 機制 | Marketplace 的核心價值（多平台監控）可能因平台變動而大幅降低，且無法提前預警 | 建立 Parser 版本偵測機制；設計格式更新 SOP；考慮在 Knowledge 中儲存「Shopee Parser Schema Version」 |

### 中風險（建議在 Level 3 實作前處理）

| 風險 | 描述 | 影響 | 緩解方向 |
|---|---|---|---|
| **R-04：AI 分析成本上限未定義** | BR-MKT-21 限制每個 WatchRule 每次最多 100 筆，但未定義多個 WatchRule × 多平台的總成本上限 | 若使用者設定 10 個 WatchRule，每次掃描可能觸發 3,000 個 AI 呼叫，造成費用失控 | 定義「每次 marketplace-scan Workflow 的最大 AI 呼叫次數」上限（建議 ≤ 500 calls/scan）|
| **R-05：Repository 介面未規定（ARCH-03）** | 文件沒有定義 ListingRepository / WatchRuleRepository 等介面，實作者可能直接寫 SQL | 未來若需要從 SQLite 遷移到其他 DB，需要修改業務邏輯（違反 P-05）| 在 Level 3 進入前，在 Domain 文件或獨立的技術規格中定義 Repository 介面 |
| **R-06：測試覆蓋嚴重偏向 Shopee** | Yahoo、Ruten 的 Parser 和兩個 Analyzer 完全沒有測試設計 | 這些元件在 Prototype 階段可能質量差異很大，且沒有測試基準 | 修補 TEST-01 缺口（見 Section 5）|

### 低風險（可在 Level 4 前監控）

| 風險 | 描述 | 影響 |
|---|---|---|
| **R-07：possible_replica flag 的偽陽性** | AI 判斷「可能是仿製品」沒有定義 confidence 門檻，可能誤傷正當商品 | 使用者信任度下降，通知品質降低 |
| **R-08：Event Catalogue 不完整** | 只有 `marketplace.listing_status_changed` 正式命名，其他 Event 隱含存在 | 實作者各自發明 Event 名稱，未來維護困難 |
| **R-09：WatchRule 無 Sample Data** | 使用者介面的設計缺乏參考（DATA-01/04 缺口）| 前端/Telegram 指令的輸入欄位設計無標準可依循 |

---

## 5. Required Changes

### Must Fix（必須修正，Level 2 Conditional Pass 條件）

這三個問題必須在 DOMAIN-001 更新至 v1.1 後，由 Final Approver 確認，才能正式標記為 Level 2。

| 優先 | 問題 | 修正內容 | 工作量 |
|---|---|---|---|
| **MF-01** | ARCH-06：Audit Log 無規格 | 在 §4 新增 Audit Log 規格表，列出哪些操作（外部 API 呼叫 / 通知發送 / Knowledge 寫入 / Listing 狀態變更）必須寫入 Audit Log，並定義最低欄位：`operation_type`, `entity_id`, `action`, `actor`, `timestamp`, `result` | 小（1–2 小時）|
| **MF-02** | TEST-01：4 個元件缺少 Unit Tests | 補充 `YahooAuctionParser`（≥3 筆）、`RutenListingParser`（≥3 筆）、`ListingValueAnalyzer`（≥3 筆）、`ListingRiskAnalyzer`（≥3 筆）的 Unit Test Cases | 中（設計 12 個新測試案例）|
| **MF-03** | DATA-01/04：WatchRule 無 Sample Data | 新增 WatchRule 的完整 JSON 範例（包含所有欄位），並明確說明 min_deal_score 預設值的選擇理由 | 小（30 分鐘）|

### Should Improve（建議改善，Level 3 實作前完成）

| 優先 | 問題 | 改善內容 |
|---|---|---|
| **SI-01** | ConditionNorm 雙重定義（EXT-02）| 明確宣告 ConditionNorm 的唯一位置（Knowledge 或 Parser 內建），並刪除另一個位置的描述 |
| **SI-02** | Analyzer 命名不一致（NAME-02）| 將 `ListingValueAnalyzer` / `ListingRiskAnalyzer` 重命名為 `MarketplaceValueAnalyzer` / `MarketplaceRiskAnalyzer`（與 GOVR-006 一致）|
| **SI-03** | 缺少 Event Catalogue（NAME-04）| 新增正式 Event 命名列表，至少包含：`marketplace.listing_matched`、`marketplace.listing_analyzed`、`marketplace.notification_sent` |
| **SI-04** | Repository 介面未規定（ARCH-03）| 在 §6 後新增 Repository Interface 概要（方法簽名層級即可）|
| **SI-05** | AIProvider 約束不顯眼（ARCH-04）| 在 §9 Analyzers 加入明確說明：「實作必須透過 AIProvider 介面，不得直接 import Anthropic SDK（P-07）」|
| **SI-06** | FLOW-03：步驟失敗行為不完整 | 補充 Step 3-7 的失敗行為（Parser 解析失敗 → 跳過此 Listing；WatchRuleMatcher 異常 → 記錄 failed 繼續下一筆）|

### Nice to Have（可後續改善，Level 4 前納入）

| 問題 | 改善內容 |
|---|---|
| DATA-03：無邊界案例 Sample Data | 補充一筆 suspicious（低價）和一筆 unknown condition 的範例資料 |
| TEST-04：AI 輸出格式錯誤未測 | 新增一個 L1 Validator 的測試：AI 回傳缺少 `deal_score` 欄位時的處理行為 |
| COMPAT-03：Knowledge namespace 格式不一致 | 統一為點分隔或斜線分隔（擇一）|
| possible_replica confidence 門檻 | 定義此 risk_flag 觸發的 AI confidence 最低要求 |
| Template 修補 | 更新 TMPL-001，新增 Domain-specific Normalization Rules、Entity Status Lifecycle、Event Catalogue 三個可選區塊 |

---

## 6. Recommendation

### 最終判定：Conditional Pass

```
Blocker 數量：0          → ✅
Major 數量：3             → ❌（超過 ≤ 2 的門檻）
Conditional Pass 條件：   → 完成 MF-01 + MF-02 + MF-03 後重新確認
```

### 升級至 Level 2 的條件

Marketplace Domain 在完成以下三項修補、更新文件版本至 v1.1 後，由 Final Approver 確認，即可正式晉升 Level 2（Validated）。**無需重新進行全面 9 維度審查**——只需確認三個修補項目已正確完成。

| 條件 | 修補項目 | 驗收標準 |
|---|---|---|
| **Condition 1** | MF-01：新增 Audit Log 規格 | §4 中有完整的 Audit Log 操作列表和最低欄位定義 |
| **Condition 2** | MF-02：補充 4 個元件的 Unit Tests | YahooAuctionParser、RutenListingParser、ListingValueAnalyzer、ListingRiskAnalyzer 各有 ≥ 3 個 Unit Test Cases |
| **Condition 3** | MF-03：新增 WatchRule Sample Data | §15 有完整的 WatchRule JSON 範例 |

### 整體評價

Marketplace Domain 是一份架構嚴謹、業務邏輯完整的 Domain 設計文件。它在模板遵從、術語一致性、Workflow 設計、可擴充性等核心維度上表現優秀，已具備成為 Golden Domain 候選的基本素質。

三個 Must Fix 問題（Audit Log、Unit Test 缺失、WatchRule Sample Data）都是**補充性缺口，不涉及根本設計修改**，工作量估計總計 3–5 小時。修補後此文件將達到 PAOS Level 2 的完整標準，成為後繼 Domain 設計的正式參考架構。

**作為 Golden Domain 候選的潛力評估**：高。Collector/Parser/Analyzer/Workflow 四個抽象層已是高品質的可重用骨架。建議在 Level 3 實作啟動前，同步修補 domain-template.md（SI-05 所列的 4 個可選區塊），讓 Stocks Domain 的設計可以直接利用這些新增區塊。

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-29 | 初版：首次 Level 2 正式審查。9 維度評分，Conditional Pass，3 個 Must Fix 條件 |
