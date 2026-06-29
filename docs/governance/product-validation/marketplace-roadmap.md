---
doc_type: governance
doc_id: GOVR-PV-MKT-001
title: Marketplace Domain Lifecycle Roadmap
status: accepted
version: "1.0"
date: 2026-06-27
related: [DOMAIN-001, GOVR-001, GOVR-002, GOVR-003, GOVR-004, GOVR-005, GOVR-006, GOVR-007]
tags: [marketplace, roadmap, lifecycle, product-validation, golden-domain]
---

# Marketplace Domain Lifecycle Roadmap

> 本文件是 Marketplace Domain 從初始設計到 Golden Domain 的完整生命週期規格。  
> 它是可執行的——每個 Exit Criteria 都是一個可驗證的事實，不是一份文件的存在。  
>
> **設計原則**：每個階段的晉升，必須靠「展示」（demonstration），不是「說明」（documentation）。

---

## 一、生命週期概覽

```
[現在] Phase 1: Design Validation（Level 2）
            架構正確性 + Template 通用性驗證
            ↓
       Phase 2: Product Validation Gate
            Golden Dataset 建立 + KPI 定義
            ↓
       Phase 3: Prototype
            5 個核心元件的端對端驗證
            ↓
       Phase 4: Performance Validation
            速度、延遲、資源用量達標
            ↓
       Phase 5: Full Implementation（Level 3）
            完整實作 + Replay 通過
            ↓
       Phase 6: Production（Level 4）
            穩定 30 天 + 使用者確認有價值
            ↓
       Phase 7: Golden Domain（Level 5）
            第二個 Domain 套用成功 + Core 無修改
```

---

## 二、Phase 1：Design Validation（Level 2）

**目標**：證明 Marketplace 設計符合架構原則，且 Domain Template 足夠通用，可讓未來 Stocks、Jobs 等 Domain 直接套用。

### 2.1 架構合規驗證

對照 GOVR-001 執行完整 9 維度審查（見 GOVR-002 Level 2 審查流程）。

**Entry Criteria**：已達到 Level 1（GOVR-001 TMPL + NAME + GLOSS 三維度通過）

---

### 2.2 Template Reusability Assessment（模板通用性評估）

這是 Design Validation 的核心新增項目。目標：**用 Stocks Domain 做乾跑（Dry-Run），在不參考 Marketplace 的情況下只用模板設計 Stocks，看模板是否夠用。**

#### 2.2.1 Marketplace 元素分類

以下將 Marketplace 所有設計元素分為三類：

| 設計元素 | 類型 | 模板對應章節 | Stocks 等效物 | 模板是否覆蓋？ |
|---|---|---|---|---|
| ShopeeListingCollector | Platform-specific | Collectors | TWSECollector | ✅ `{Domain}Collector` 模式 |
| YahooListingParser | Platform-specific | Parsers | YahooFinanceParser | ✅ `{Domain}Parser` 模式 |
| MarketplaceValueAnalyzer | Domain-specific（名稱）| Analyzers | StocksOpportunityAnalyzer | ✅ `{Domain}Analyzer` 模式 |
| DealScore（0.0–1.0）| Domain-specific（名稱）| Analyzers | OpportunityScore | ✅ AI 評分模式已在模板 |
| WatchRule.max_total_price | Domain-specific（欄位）| Data Model | WatchRule.min_pe_ratio | ✅ WatchRule 欄位可依 Domain 定義 |
| marketplace_listings | Domain-specific（資料表名）| Data Model | stocks_prices | ✅ Domain 前綴命名慣例 |
| marketplace.listing_matched | Domain-specific（事件 namespace）| Workflows | stocks.signal_triggered | ✅ Event 命名規範 |
| CategoryThresholds（具體數值）| Domain-specific（內容）| Knowledge | SectorBenchmarks | ✅ Knowledge config 模式 |
| ConditionNorm（九成新→like_new）| Domain-specific（概念）| Parsers | N/A | ⚠️ 模板未明確有「正規化對照表」章節 |
| Sold Detection（偵測已售出）| Domain-specific（概念）| Workflows | N/A（Stocks 沒有「售出」概念）| ⚠️ 模板沒有「狀態追蹤」optional 章節 |
| Shopee 價格 ×100 格式 | Platform-specific（實作細節）| Parsers Notes | 無對等 | ✅ Parser Notes 欄位可記錄 |
| 每 30 分鐘掃描 | Domain-specific（頻率）| Workflows cron | 0 6 * * 1-5 盤前掃描 | ✅ cron expression 欄位 |

**發現的模板缺口（需回饋到 TMPL-001）**：

| 缺口 | 說明 | 建議修正 |
|---|---|---|
| 無「Domain-specific Normalization Rules」| Marketplace 需要 ConditionNorm，Jobs 可能需要 SeniorityNorm，但模板沒有此章節 | 在 Parsers 區塊加入「Normalization Table（可選）」 |
| 無「Entity Status Tracking」| 商品可以「售出」，職缺可以「已關閉」，但模板沒有狀態追蹤的標準位置 | 在 Data Model 區塊加入「Status Lifecycle（可選）」 |

#### 2.2.2 Dry-Run：Stocks Domain 套用測試

**方法**：不參考 marketplace.md，僅用 domain-template.md，嘗試填寫 Stocks Domain 的 16 個區塊。

**通過標準**：
- 所有 16 個區塊均可填寫，無需在模板之外創造新章節
- 所有 Marketplace 的通用架構模式（Collector/Parser/Analyzer/WatchRule/Score）在 Stocks 都有直接對應
- 發現的任何模板缺口已記錄，並在此次 Design Validation 結束前回饋到 TMPL-001

**Dry-Run 結果記錄**：完成後記錄於 `docs/governance/reviews/stocks-dryrun-v0.1.md`

---

### 2.3 Design Validation Exit Criteria

> ✅ = 通過；❌ = 未通過（需修正後重審）

| ID | Exit Criteria | 驗證方式 | 負責人 |
|---|---|---|---|
| DV-01 | GOVR-001 所有 9 個維度通過，零 Blocker | 填寫完整 GOVR-001 清單 | Claude（Reviewer）|
| DV-02 | Marketplace 所有設計元素已分類（Platform/Domain/Generic）| 2.2.1 分類表完成 | Claude |
| DV-03 | Stocks Dry-Run：16 個章節全部可填寫 | Dry-Run 結果記錄存在 | User（Final Approver）|
| DV-04 | 發現的模板缺口已記錄並回饋 TMPL-001（若有）| TMPL-001 更新 commit | Claude |
| DV-05 | Final Approver 確認 Level 2 通過 | 簽核 | User |

**Level 2 晉升需要**：DV-01 ~ DV-05 全部通過。

---

## 三、Phase 2：Product Validation Gate（Pre-Level 3）

**目標**：在開始任何實作之前，定義「成功」的標準，並建立 Golden Dataset——AI 準確性的不可移動基準。

### 3.1 Marketplace User Stories

**US-01：即時好物警報**
> As a 二手商品買家, I want to 在好機會出現後 15 分鐘內收到通知, so that 我能在其他人搶先之前看到好價格。

Acceptance Criteria:
- AC-1：列表符合 WatchRule 條件後，Telegram 通知在 ≤ 60 秒內送達
- AC-2：通知包含：商品名稱、總價格、DealScore、成色、平台、AI 理由、商品連結
- AC-3：同一件商品在 7 天內不重複通知

**US-02：精準過濾，減少雜訊**
> As a 二手商品買家, I want to 只收到 DealScore ≥ 0.6 且符合我的成色要求的通知, so that 我不需要自己再篩選。

Acceptance Criteria:
- AC-1：DealScore < WatchRule.min_deal_score 的商品絕對不發送通知
- AC-2：condition < WatchRule.min_condition 的商品絕對不發送通知
- AC-3：每天收到的通知數量 ≤ 10 則（避免通知疲勞）

**US-03：多平台覆蓋，不錯過機會**
> As a 二手商品買家, I want to AI 同時監控蝦皮、Yahoo 拍賣、露天拍賣, so that 我不需要分別去每個平台搜尋。

Acceptance Criteria:
- AC-1：每次掃描覆蓋至少 2 個平台（V1 允許部分平台暫時不可用時降級）
- AC-2：跨平台的同類商品使用相同的評分標準（DealScore 可比較）
- AC-3：使用者在 WatchRule 中可以指定只監控特定平台

**US-04：可疑商品的風險提示**
> As a 二手商品買家, I want to 在 AI 發現可疑商品時收到明確的風險警告, so that 我不會因為低價而衝動購買有問題的商品。

Acceptance Criteria:
- AC-1：risk_flags 中包含任何標記的商品，通知中必須明確顯示風險警告
- AC-2：`suspicious` 類商品的通知使用不同的格式（⚠️ 警告圖示）
- AC-3：AI 必須在 reason 欄位具體說明懷疑的原因

---

### 3.2 Success Criteria

| ID | 成功條件 | 量化目標 | 對應 KPI |
|---|---|---|---|
| SC-01 | 使用者每週省下大量手動搜尋時間 | 節省 ≥ 25 分鐘/週 | KPI-03 |
| SC-02 | 通知品質讓使用者信任並主動查看 | Alert Acceptance Rate ≥ 70% | KPI-01 |
| SC-03 | AI 找到人工容易錯過的好機會 | 跨平台覆蓋量 ≥ 手動的 50× | KPI-04 |
| SC-04 | 使用者不會因為 AI 誤導而做出錯誤判斷 | False Positive Rate ≤ 25% | KPI-02 |
| SC-05 | 系統穩定運行，不讓使用者擔心掉通知 | Workflow 成功率 ≥ 95% | KPI-05 |

---

### 3.3 KPI

| ID | 指標名稱 | 目標值 | 硬下限（低於此值重新審視設計）| 測量方式 | 測量頻率 |
|---|---|---|---|---|---|
| KPI-01 | Alert Acceptance Rate | ≥ 70% | < 40% | 使用者點擊商品連結 / 總通知數 | 每月 |
| KPI-02 | AI Precision（DealScore 準確率）| ≥ 65% | < 50% | Replay on Golden Dataset | 每次 Replay |
| KPI-03 | Time Saved / Week | ≥ 25 分鐘 | < 10 分鐘 | Manual Baseline 比較 | 首次 + 季度 |
| KPI-04 | Coverage vs Manual | ≥ 50× | < 5× | AI 掃描量 / 手動瀏覽量（同時間）| 每月 |
| KPI-05 | Workflow Success Rate | ≥ 95% | < 80% | 成功完成 / 觸發次數 | 每日 |
| KPI-06 | Recall（不錯過好機會）| ≥ 50% | < 30% | Replay on Golden Dataset | 每次 Replay |

---

### 3.4 Manual Baseline（人工操作基準）

**建立方式**：在 Prototype 開始前，使用者實際手動搜尋 2 週，記錄數據。

**目標**：量化「不使用 AI 時，使用者能做到什麼程度」。

**記錄格式**：

```
Manual Baseline 建立期：{開始日期} 至 {結束日期}（14 天）

測量項目：
- 每週手動搜尋時間：__ 分鐘/週（__ 次/週 × __ 分鐘/次）
- 平台覆蓋：__ 個平台（列出名稱）
- 每次搜尋查看商品數：~__ 個
- 每週找到「值得進一步查看」的商品：~__ 個
- 這些商品中，最後真正是「好價格」的：~__ 個（主觀判斷）
- 最長錯過機會的案例：商品在看到時已售出，估計多久前上架：__ 小時
```

**Manual Precision 計算**：從手動「值得查看」的商品中，對照 Golden Dataset 的標注，計算實際 Precision。（若沒有 overlap，使用主觀估計值）

---

### 3.5 Golden Dataset 建立計畫（Marketplace V1.0）

#### 3.5.1 建立流程

```
Step 1：資料收集（7 天）
  → 從蝦皮、Yahoo 拍賣、露天拍賣各搜尋 3 個關鍵字
  → 關鍵字選擇：各 Category 各 1 個（books/lego/electronics/cameras/furniture）
  → 每個平台收集 ~15 個 listings（原始格式，截圖 + JSON）
  → 目標：~45 個原始候選資料
         ↓
Step 2：篩選（2 天）
  → 從 45 個候選中選取 30 個：
      - 覆蓋所有 5 個 Category
      - 覆蓋所有 3 個平台
      - 包含 Easy/Medium/Hard 各難度
      - 包含必要的困難案例（見 3.5.2）
         ↓
Step 3：標注（5 天）
  → 使用者親自標注每一筆資料（不依賴 AI 標注 Golden Dataset）
  → 對照 GOVR-006 的標注決策樹
  → 為每筆資料填寫：annotated_condition、annotated_deal_score、
    annotated_deal_verdict、is_good_deal、annotation_reason
         ↓
Step 4：審查（2 天）
  → Claude 抽樣審查 20% 的標注（6 筆）
  → 找出標注理由不足的條目（< 20 字 → 請使用者補充）
  → 找出明顯矛盾的條目（annotated_deal_verdict 和 DealScore 不一致 → 討論後修正）
         ↓
Step 5：發布
  → 存放於 docs/governance/golden-datasets/marketplace/golden-dataset-v1.0.json
  → 附上 golden-dataset-v1.0.md（分布統計、標注說明）
  → 記錄 Dataset v1.0 的 SHA256 hash（用於版本追蹤）
```

#### 3.5.2 必含的困難案例（Hard Cases）

| 類型 | 必須筆數 | 描述 |
|---|---|---|
| 明顯詐騙 | ≥ 3 | 價格異常低（< 20% 市場價）、描述模糊、賣家新帳號 |
| 令人疑惑的低價 | ≥ 3 | 價格 30–50% 市場價，但描述合理（需判斷）|
| 新賣家好商品 | ≥ 2 | 吸引人的價格，但賣家評價數 < 5（高風險 + 高吸引力的衝突）|
| 描述誇大成色 | ≥ 2 | 描述說「九成新」但照片明顯有損傷 |
| 無照片高價商品 | ≥ 1 | condition 聲稱 like_new，但無任何照片 |

#### 3.5.3 V1.0 目標分布

| 維度 | 目標分布 |
|---|---|
| **Verdict** | great_deal × 6、good_deal × 6、fair_price × 6、overpriced × 6、suspicious × 6 |
| **Platform** | Shopee × 15、Yahoo × 10、Ruten × 5 |
| **Category** | books × 6、lego × 6、electronics × 6、cameras × 6、furniture × 6 |
| **Difficulty** | Easy × 12、Medium × 12、Hard × 6 |
| **Confidence** | high × 20、medium × 7、low × 3 |

#### 3.5.4 Marketplace 標注指引（具體化版本）

**市場行情查詢來源**（標注前必查）：
- LEGO：Bricklink.com 均價、蝦皮已售出篩選
- 電子產品/相機：PChome、Yahoo 購物中心新品價
- 書籍：博客來、誠品定價
- 家具：IKEA 定價（若適用）或蝦皮已售出篩選

**DealScore 對應表（作為標注參考）**：

| price_ratio（total_price / market_price）| 基礎 DealScore | 調整因素 |
|---|---|---|
| ≤ 0.40 | 0.85–0.95 | 有 risk_flags → -0.1 ~ -0.2 |
| 0.41–0.60 | 0.70–0.84 | 無照片 → -0.1；新賣家 → -0.05 |
| 0.61–0.75 | 0.55–0.69 | 成色差一級 → -0.05 |
| 0.76–0.90 | 0.35–0.54 | — |
| 0.91–1.10 | 0.20–0.34 | — |
| > 1.10 | 0.05–0.19 | — |

**annotation_reason 必須包含**：
1. 市場參考價（來源 + 數字）
2. 計算出的 price_ratio
3. 任何影響判斷的特殊因素（賣家評價、照片品質、描述可信度）

#### 3.5.5 Dataset 版本更新策略

| 版本 | 觸發條件 | 規則 |
|---|---|---|
| v1.x（minor）| 新增 ≤ 20 筆，不修改現有標注 | Append-only；原有條目不修改 |
| v2.0（major）| 發現系統性標注錯誤，或市場行情大幅偏移（≥ 3 個月後）| 可以更新標注，需記錄修改理由 |
| 任何版本 | 發現個別標注錯誤 | 在原條目加入 `superseded_by: {id}` 注記，新增正確版本條目 |

**Append-Only 規則**：任何已進入 Golden Dataset 的條目，不刪除。這確保所有歷史 Replay 結果可以復現。

#### 3.5.6 Golden Dataset 如何支援 Replay 與 Regression

**Replay 的使用方式**：
1. 讀取 `golden-dataset-v{X.Y}.json` 中的所有 Input Data
2. 跳過 Collector 和 Parser，直接將正規化後的 Listing 輸入 Analyzer
3. 比較 AI 輸出（`deal_verdict`、`deal_score`、`risk_flags`）與 Annotation（`annotated_deal_verdict`、`annotated_deal_score`）
4. 計算 Precision、Recall、F1、MAE（DealScore 誤差）

**Regression 的觸發邏輯**（對照 GOVR-007）：
- 建立 Golden Dataset 後，**第一次 Replay 的結果作為 Baseline**
- 後續每次 Replay 與 Baseline 比較
- Precision 衰退 > 5% 或 F1 衰退 > 0.05 → Regression Warning
- Precision < 50% → Regression Fail（立即停止晉升）

---

### 3.6 Product Validation Gate Exit Criteria

| ID | Exit Criteria | 驗證方式 |
|---|---|---|
| PV-01 | User Stories US-01~US-04 全部定義，每個有 ≥ 2 個 Acceptance Criteria | 文件審查 |
| PV-02 | KPI-01~KPI-06 全部定義目標值和硬下限 | 文件審查 |
| PV-03 | Manual Baseline 建立：至少 14 天的手動搜尋記錄 | 數據記錄 |
| PV-04 | Golden Dataset V1.0 建立完成（≥ 30 筆，符合 3.5.3 分布）| Dataset 存在 + 統計驗證 |
| PV-05 | 每筆 Golden Dataset 條目有完整的 annotation_reason（≥ 20 字）| 抽樣審查 |
| PV-06 | Hard Cases 覆蓋（≥ 3 種類型，≥ 11 筆）| 統計驗證 |
| PV-07 | Regression 門檻設定（Precision 基準 = 第一次 Replay 後設定）| 第一次 Prototype Replay 後完成 |
| PV-08 | Level 3 Acceptance Criteria 定義（引用 KPI 具體數字）| 文件審查 |

---

## 四、Phase 3：Prototype

**目標**：用最小的實作代價，端對端驗證每個核心元件可以工作。不追求完整性，追求**可行性的概念驗證**（Proof of Concept）。

### 4.1 Prototype 原則

- **單一平台優先**：Prototype 只實作蝦皮（Shopee）；Yahoo 和露天等到 Full Implementation
- **固定 WatchRule**：不實作 WatchRule 動態載入；Prototype 用硬編碼的一個 WatchRule
- **不需要完整錯誤處理**：Prototype 允許崩潰，Full Implementation 才需要 retry/fallback
- **不需要排程**：Prototype 手動觸發，不接 Scheduler
- **必須用真實 API**：AI Analyzer 必須呼叫真實的 claude-haiku-4-5，不是 mock

---

### 4.2 Collector Prototype

**目標**：證明可以從蝦皮取得真實商品資料。

**實作範圍**：
- 一個 `ShopeeListingCollector.prototype_run()` 方法
- 輸入：一個關鍵字（如 "LEGO 42083"）
- 輸出：至少 10 筆原始蝦皮 API/HTML 資料

**Success Criteria**：

| 標準 | 通過條件 |
|---|---|
| SC-COL-01 | 成功取得 ≥ 10 筆蝦皮商品資料 |
| SC-COL-02 | 每筆資料包含：title、raw_price、condition_raw、url、seller_id |
| SC-COL-03 | 在網路正常的情況下完成時間 ≤ 30 秒 |
| SC-COL-04 | 不使用任何 Core 或 Event Bus（Prototype 允許直接呼叫）|

**失敗情況定義**：取得 0 筆資料，或 > 50% 資料缺少必要欄位。

---

### 4.3 Parser Prototype

**目標**：證明可以將蝦皮原始資料正規化為 `Listing` 介面。

**實作範圍**：
- 一個 `ShopeeListingParser.parse()` 方法
- 輸入：Collector 取得的 10 筆原始資料
- 輸出：10 筆 `Listing` 物件

**Success Criteria**：

| 標準 | 通過條件 |
|---|---|
| SC-PAR-01 | 10 筆原始資料全部成功解析（0 個解析錯誤）|
| SC-PAR-02 | Shopee 價格 ×100 換算正確（raw 89000 → NT$890）|
| SC-PAR-03 | condition_raw 正確映射至 5 級標準（九成新→like_new、八成新→like_new、七成新→good…）|
| SC-PAR-04 | total_price = price + shipping_cost（計算正確）|
| SC-PAR-05 | 無法識別的 condition_raw 設為 `unknown`（不拋出錯誤）|

**驗證方式**：
```
針對 10 筆蝦皮資料，人工核對：
1. 3 筆隨機資料的價格換算是否正確
2. 所有 condition_raw 的映射結果是否符合 ConditionNorm 對照表
3. 有無任何 Parser 錯誤或 undefined 欄位
```

---

### 4.4 Price Analysis Prototype

**目標**：證明 AI（claude-haiku-4-5）能產出有意義的 DealScore 和 deal_verdict。

**實作範圍**：
- 一個 `MarketplaceValueAnalyzer.analyze()` 方法
- 輸入：解析後的 `Listing`（包含 category 和 total_price）
- 輸出：`ListingAnalysis`（deal_score、deal_verdict、reason）
- 需要：從 Knowledge 讀取 CategoryThresholds（或 Prototype 階段用硬編碼）

**Success Criteria**：

| 標準 | 通過條件 |
|---|---|
| SC-ANA-01 | 10 筆 Listing 全部成功分析（0 個 API 錯誤）|
| SC-ANA-02 | 所有 deal_score 在 0.0–1.0 之間 |
| SC-ANA-03 | 所有 reason 長度 ≥ 30 字，且明確提到價格資訊 |
| SC-ANA-04 | AI DealScore 排名與人工直覺排名的 Spearman 相關係數 ≥ 0.6（對 10 筆資料）|
| SC-ANA-05 | confidence 欄位 ≥ 0.5（AI 對自己的判斷有基本信心）|

**SC-ANA-04 驗證方式**：
1. 人工把 10 筆資料按「主觀覺得多好」排名（1 = 最好）
2. 把 AI 的 DealScore 由高到低排名（1 = 最高分）
3. 用 Spearman 公式計算兩組排名的相關係數
4. 相關係數 ≥ 0.6 → Pass（表示 AI 和人的判斷方向一致）

---

### 4.5 Sold Detection Prototype

**目標**：證明可以偵測商品從「上架」到「已售出/下架」的狀態變化。

**實作範圍**：
- 在 Collector 中加入 `check_status()` 方法
- 輸入：已收集商品的 URL 清單
- 輸出：每個 URL 的當前 `status`（active / sold / removed / unknown）

**Success Criteria**：

| 標準 | 通過條件 |
|---|---|
| SC-SOLD-01 | 在 48 小時內，至少有 1 筆商品狀態從 `active` 變為 `sold` 或 `removed`（自然發生）|
| SC-SOLD-02 | 狀態變化被正確記錄，`last_seen_at` 更新 |
| SC-SOLD-03 | 已售出商品不再觸發 WatchRule 匹配（不重複通知）|

**注意**：SC-SOLD-01 依賴自然市場行為（商品被售出），可能需要等待 24–48 小時。若 10 筆資料在 48 小時內無任何售出，使用「手動標記一筆為 sold 並驗證系統行為」作為替代驗證。

---

### 4.6 Notification Prototype

**目標**：證明 AI 分析結果可以轉化為使用者實際收到的 Telegram 訊息。

**實作範圍**：
- 一個 `NotificationDispatcher.send_deal_alert()` 方法
- 輸入：一筆 P1 通知（deal_score ≥ 0.75，符合 WatchRule）
- 輸出：Telegram Bot 發送訊息到指定 chat_id

**Success Criteria**：

| 標準 | 通過條件 |
|---|---|
| SC-NOT-01 | Telegram 訊息在 ≤ 60 秒內收到 |
| SC-NOT-02 | 訊息格式包含：🔥 標題、商品名稱（截斷至 50 字）、總價、成色、DealScore（百分比）、平台、AI 理由（截斷至 100 字）、商品連結 |
| SC-NOT-03 | 帶有 risk_flags 的商品，訊息包含 ⚠️ 警告區塊 |
| SC-NOT-04 | Bot Token 從環境變數讀取（不硬編碼）|

---

### 4.7 Prototype 整體 Acceptance Criteria

**所有以下條件通過，Prototype 階段完成**：

| ID | 條件 | 嚴重度 |
|---|---|---|
| PRO-AC-01 | SC-COL-01、SC-PAR-01、SC-ANA-01、SC-NOT-01 全部通過（零崩潰）| Blocker |
| PRO-AC-02 | 端對端流程可以手動執行：從「輸入關鍵字」到「收到 Telegram 通知」，不需人工干預 | Blocker |
| PRO-AC-03 | SC-ANA-04：AI 排名與人工排名 Spearman ≥ 0.6 | Blocker |
| PRO-AC-04 | SC-PAR-02：蝦皮價格換算正確 | Blocker |
| PRO-AC-05 | SC-NOT-02：訊息格式正確（包含所有必要欄位）| Major |
| PRO-AC-06 | SC-PAR-03：ConditionNorm 映射全部正確 | Major |
| PRO-AC-07 | 在 Prototype 過程中沒有發現需要修改 Core Architecture 的需求 | Blocker |
| PRO-AC-08 | 首次 Golden Dataset Replay：在 Prototype 的 10 筆資料中，若有與 Dataset 重疊的條目，Spearman ≥ 0.6 | Major |

**Prototype 的時間目標**：端對端手動執行，10 筆資料從收集到通知送達，≤ 30 分鐘。

---

## 五、Phase 4：Performance Validation

**目標**：確認 Full Implementation 的系統效能達到使用者可以接受的標準，不會影響日常 Windows 使用。

### 5.1 Performance KPIs

| KPI | 目標值（Target）| 硬下限（Fail if worse）| 測量工具 |
|---|---|---|---|
| **Parsing Speed** | ≤ 500 ms / listing | > 2,000 ms / listing | 計時器 + 日誌 |
| **AI Analysis Speed** | ≤ 8 秒 / listing（串列）| > 20 秒 / listing | API 回應時間日誌 |
| **Batch Analysis Throughput** | ≤ 15 分鐘 / 100 listings（10 並行）| > 30 分鐘 / 100 listings | 端對端計時 |
| **Notification Latency（P1）** | ≤ 60 秒（偵測到 → 通知送達）| > 300 秒 | 時間戳記比較 |
| **Notification Latency（P2 Digest）** | ≤ 5 分鐘（09:00 觸發 → 摘要送達）| > 15 分鐘 | 觸發時間 vs 收到時間 |
| **Memory Usage（Peak）** | ≤ 512 MB（掃描期間）| > 1,024 MB | Windows Task Manager |
| **CPU Usage（Average）** | ≤ 40%（掃描期間）| > 80% | Windows Task Manager |
| **SQLite DB Growth** | ≤ 100 MB / 月 | > 500 MB / 月 | 資料庫大小監控 |
| **Workflow Success Rate** | ≥ 95% | < 80% | Workflow 完成日誌 |

### 5.2 Performance 測試場景

**場景 A：標準掃描壓力測試**
- 輸入：100 筆 Listing（分布：蝦皮 50、Yahoo 30、露天 20）
- 測量：Parsing Speed、Analysis Throughput、Memory/CPU
- 執行次數：3 次（取平均）

**場景 B：通知延遲測試**
- 方法：手動插入一筆觸發 WatchRule 的 Listing 到佇列，計時到 Telegram 收到通知
- 測量：Notification Latency
- 執行次數：5 次

**場景 C：長時間運行穩定性測試**
- 讓系統正常運行 24 小時（期間自動執行 24×2 = 48 次 marketplace-scan）
- 測量：Memory 是否隨時間成長（記憶體洩漏？）、Workflow 成功率
- 通過標準：記憶體沒有持續上升趨勢、Workflow 成功率 ≥ 95%

### 5.3 Performance Validation Exit Criteria

| ID | Exit Criteria | 通過標準 |
|---|---|---|
| PERF-01 | Parsing Speed | 場景 A：平均 ≤ 500 ms/listing |
| PERF-02 | Batch Analysis Throughput | 場景 A：100 listings ≤ 15 分鐘 |
| PERF-03 | P1 Notification Latency | 場景 B：5 次中 ≥ 4 次 ≤ 60 秒 |
| PERF-04 | Memory Usage | 場景 A：Peak ≤ 512 MB |
| PERF-05 | CPU Usage | 場景 A：Average ≤ 40% |
| PERF-06 | Long-run Stability | 場景 C：無記憶體洩漏，Workflow 成功率 ≥ 95% |
| PERF-07 | No API Rate Limit Errors | 場景 A：0 個 rate limit 錯誤 |

---

## 六、Phase 5：Full Implementation（Level 3）

**目標**：完整實作所有 3 個平台的 Collectors + Parsers，完整錯誤處理，排程整合，通過 Full Replay。

### 6.1 Entry Criteria

| 必要條件 |
|---|
| Phase 3（Prototype）全部 Blocker AC 通過 |
| Phase 4（Performance Validation）全部 PERF Exit Criteria 通過 |
| Golden Dataset V1.0 存在且通過品質審查 |

### 6.2 Full Implementation 範圍

相對於 Prototype 的額外工作：
- 擴展至 Yahoo Auctions Collector + Parser
- 擴展至 Ruten Collector + Parser
- 加入完整的 retry/backoff 機制（網路失敗時）
- 整合 Scheduler（cron `*/30 * * * *`）
- 實作完整的 WatchRuleLoader（從資料庫讀取，不硬編碼）
- 完整的 Audit Log（P-09 合規）
- 所有 Unit Tests 通過（≥ 80%）
- 部署至 D1（Windows 本機）並持續運行 7 天

### 6.3 Full Implementation Exit Criteria（Level 3）

| ID | Exit Criteria | 驗證方式 |
|---|---|---|
| L3-01 | Full Replay on Golden Dataset V1.0：Precision ≥ 65%，Recall ≥ 50% | GOVR-007 Replay |
| L3-02 | F1 Score ≥ 0.56 | Replay 計算 |
| L3-03 | Suspicious 類 Precision ≥ 70%（不誤導使用者）| Replay 計算（按類別）|
| L3-04 | Unit Tests 通過率 ≥ 80% | 測試執行 |
| L3-05 | 3 個平台的 Collector 全部正常收集資料 | 整合測試 |
| L3-06 | marketplace-scan Workflow 在 D1 成功執行 ≥ 3 次 | 執行日誌 |
| L3-07 | 使用者收到至少 1 次真實的 P1 通知 | Telegram 訊息確認 |
| L3-08 | Performance KPIs 全部達標（同 Phase 4 Exit Criteria）| 效能測試 |
| L3-09 | 無 Blocker 級別的架構違反 | 程式碼審查 |

---

## 七、Phase 6：Production（Level 4）

### 7.1 Entry Criteria

| 必要條件 |
|---|
| Level 3 的所有 L3 Exit Criteria 通過 |
| 使用者明確表示「可以開始依賴此系統」|

### 7.2 Production Exit Criteria（Level 4）

| ID | Exit Criteria | 驗證方式 |
|---|---|---|
| L4-01 | 穩定運行 ≥ 30 天（連續，不包括預期的維護停機）| 運行日誌 |
| L4-02 | P1 Bug 數量 = 0（30 天內）| Bug 追蹤 |
| L4-03 | P2 Bug 數量 ≤ 3（30 天內，且已全部修復）| Bug 追蹤 |
| L4-04 | Workflow 成功率 ≥ 95%（30 天平均）| 日誌統計 |
| L4-05 | Alert Acceptance Rate ≥ 70%（使用者點進去查看的比例）| KPI 測量 |
| L4-06 | 月度 Full Replay：無 Regression Fail，Warning ≤ 1 個 | GOVR-007 Replay |
| L4-07 | 使用者主動確認「AI 找到了至少 1 個我會錯過的好機會」| 使用者確認 |

---

## 八、Phase 7：Golden Domain（Level 5）

**目標**：Marketplace 成為 PAOS 第一個 Golden Domain，證明整個設計框架（Template + Governance）在第二個 Domain 的設計中是可重用的。

### 8.1 Golden Domain 必要條件

Golden Domain 的認定，需要 **以下所有條件都成立**：

| ID | 條件 | 驗證方式 |
|---|---|---|
| GD-01 | 第二個 Domain（Stocks 或其他）成功使用 domain-template.md 完成設計，**無需修改模板的核心結構** | 比對 TMPL-001 版本號 |
| GD-02 | 實作 Marketplace 未觸發任何 Core Architecture 變更（Event Bus、Memory、Knowledge Service 無修改）| git diff Core 模組 |
| GD-03 | TMPL-001（Domain Template）在 Marketplace 完成 Level 4 後，沒有需要 major version bump 的修改 | TMPL-001 版本歷史 |
| GD-04 | 第二個 Domain 的設計者（User 或 AI）能夠在**僅閱讀 Marketplace + Template 文件**的前提下設計新 Domain | Dry-Run 結果 |
| GD-05 | Marketplace 的所有設計決策（「為什麼這樣設計」）有文件化說明，可供後來者學習 | marketplace.md Changelog + Decision History |
| GD-06 | Marketplace 在 Level 5 認定時，Level 4 的所有 Exit Criteria 仍然滿足（效能未退化）| 月度 Replay 確認 |
| GD-07 | Marketplace Prototype 和 Implementation 過程中，GOVR-001~007 的改進建議已回饋並更新 | 各 GOVR 文件 Changelog |

### 8.2 Golden Domain 的意義

當 Marketplace 成為 Golden Domain 後：

1. **設計參考**：新 Domain 的 Reviewer（GOVR-002 角色）會問「這個 Domain 的設計和 Marketplace 的差距在哪？為什麼不同？」
2. **性能基準**：Marketplace 的 Precision/Recall/Latency 成為後繼 Domain 的參考起點
3. **Template 品質保證**：任何對 domain-template.md 的修改，都需要說明「是否會影響 Marketplace 這個 Golden Domain 的設計」
4. **反饋閉環**：Marketplace 實作時發現的所有設計問題，都要回饋到 TMPL-001 和 GOVR-001~007，讓整個系統持續改進

---

## 九、Exit Criteria 完整摘要

| 階段 | Entry Criteria（進入條件）| Exit Criteria（離開條件）| 關鍵交付成果 |
|---|---|---|---|
| **Level 0**（Draft）| 建立 domain.md 檔案 | 16 個章節標題存在，設計方向確立 | marketplace.md（部分）|
| **Level 1**（Defined）| Level 0 完成 | GOVR-001 TMPL+NAME+GLOSS 三維度 0 Blocker | marketplace.md（完整）+ Level 1 Review |
| **Level 2**（Validated）| Level 1 | GOVR-001 全 9 維度、DV-01~DV-05 通過（含 Stocks Dry-Run）| Level 2 Review + Template Reusability Report |
| **PV Gate** | Level 2 | PV-01~PV-08：User Stories、KPI、Manual Baseline、Golden Dataset V1.0 | Domain PV Spec + Golden Dataset V1.0 |
| **Prototype** | PV Gate | PRO-AC-01~PRO-AC-08：5 個元件全部 PoC 通過，Spearman ≥ 0.6 | 可運行的 Prototype 程式碼 |
| **Performance**（驗收）| Prototype | PERF-01~PERF-07：速度、延遲、資源用量全部達標 | Performance Test Report |
| **Level 3**（Implemented）| Performance 驗收 | L3-01~L3-09：Full Replay Precision ≥ 65%，3 平台、全部測試通過，使用者收到 P1 通知 | 完整生產程式碼 + Replay Report |
| **Level 4**（Production）| Level 3 | L4-01~L4-07：穩定 30 天、Bug KPI、Alert Acceptance ≥ 70%、使用者確認有價值 | 穩定運行系統 + 月度 Replay |
| **Level 5**（Golden Domain）| Level 4 | GD-01~GD-07：第二 Domain 套用成功、Core 無修改、文件可轉移知識 | Golden Domain 認定 + 改進後的 Template/Governance |

---

## 十、風險登記（Risk Register）

| 風險 | 影響階段 | 可能性 | 影響 | 緩解策略 |
|---|---|---|---|---|
| 蝦皮/Yahoo 反爬蟲機制 | Prototype + Level 3 | 高 | 高 | 使用官方 API 優先；準備 rate limiting + backoff；Prototype 可接受手動觸發 |
| AI DealScore Spearman < 0.6（Prototype 失敗）| Prototype | 中 | 高 | Prompt Engineering 改進；考慮加入 few-shot 範例；允許 2 次 Prototype 重試 |
| Golden Dataset 標注者偏差 | PV Gate | 中 | 中 | 使用者親自標注 ≥ 80%；Claude 交叉驗證 20%；記錄標注理由作為透明度 |
| 市場行情快速變化導致 Golden Dataset 過時 | Level 3~4 | 中 | 中 | 季度 Dataset 審查；V2.0 major update 規則 |
| claude-haiku-4-5 API 停用/升版 | Level 4~5 | 低 | 高 | P-07 原則（AIProvider 抽象層）確保模型切換不影響業務邏輯；升版後必須 Full Replay |
| Windows 環境 SQLite 鎖定問題 | Level 3 | 中 | 中 | 使用 WAL mode；Workflow 步驟序列化 DB 寫入；Level 3 長時間測試覆蓋此情況 |
| 通知過多導致使用者關閉 Bot | Level 3~4 | 中 | 高 | 每日通知上限（KPI-02 + US-02 AC-3 ≤ 10 則/天）；Prototype 驗收前確認機制 |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：完整 7 個 Phase、Entry/Exit Criteria、Prototype 5 元件成功標準、Performance KPIs、Golden Domain 7 個必要條件 |
