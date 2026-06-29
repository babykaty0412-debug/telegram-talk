---
doc_type: governance
doc_id: GOVR-006
title: Golden Dataset Specification
status: accepted
version: "1.0"
date: 2026-06-27
related: [GOVR-004, GOVR-005, GOVR-007]
tags: [golden-dataset, ground-truth, annotation, evaluation, quality]
---

# Golden Dataset Specification

> Golden Dataset 是評估 AI 準確性的**不可移動基準**。  
> 它是人工標注的真實資料集，記錄「正確答案是什麼」。  
> AI 輸出與 Golden Dataset 的差距，就是 AI 需要改進的方向。

---

## 一、什麼是 Golden Dataset？

Golden Dataset 不是一般的測試資料——它有三個特性：

| 特性 | 說明 |
|---|---|
| **真實性**（Real）| 來自真實世界的資料，不是人工捏造的 |
| **標注性**（Annotated）| 每筆資料都有人工標注的「正確答案」，作為 Ground Truth |
| **穩定性**（Stable）| 建立後不輕易修改；任何修改都必須版本化並記錄原因 |

Golden Dataset 的用途：
1. 評估 AI 準確性（Replay，見 GOVR-007）
2. 偵測 AI 版本退化（Regression，見 GOVR-007）
3. 作為系統「共同語言」：什麼樣的商品算「好交易」，由 Dataset 定義

---

## 二、Golden Dataset 的通用結構

每個 Domain 的 Golden Dataset 由以下三部分組成：

### 2.1 Input Data（輸入資料）
真實世界的原始資料（例如商品列表、股票資訊、職缺資料）。  
這是 AI 系統的輸入——AI 看到的就是這些。

### 2.2 Annotations（人工標注）
人工專家對每筆資料的「正確答案」：
- **分類標注**：這筆資料屬於哪個類別？（例：good_deal / fair_price / suspicious）
- **數值標注**：這筆資料的正確分數是多少？（例：DealScore = 0.82）
- **標注理由**：為什麼這樣標注？（防止標注不一致，也是 AI 學習材料）
- **信心等級**：標注者對這個判斷有多確定？（影響 Regression 計算的權重）

### 2.3 Metadata（元資料）
追蹤 Dataset 品質的管理資訊：
- 標注者
- 標注日期
- Dataset 版本
- 難度等級（Easy / Medium / Hard）

---

## 三、Dataset 品質要求

### 3.1 規模要求

| 階段 | 最小規模 | 說明 |
|---|---|---|
| V1 初版（Level 3 前）| ≥ 30 筆 | 足以計算基礎統計指標 |
| V1 成熟（Level 4 前）| ≥ 100 筆 | 足以計算分類別、分難度的指標 |
| Level 5 Golden Domain | ≥ 200 筆 | 後繼 Domain 的對照標準 |

### 3.2 分布要求（Balanced Dataset）

Dataset 必須均勻覆蓋不同類型的案例，避免「只有簡單案例」的偏差：

| 難度等級 | 比例 | 說明 |
|---|---|---|
| **Easy**（明顯案例）| 40% | 任何人都能立即判斷的案例（極低價好書、明顯詐騙）|
| **Medium**（需要判斷）| 40% | 需要對比市場行情才能判斷的案例 |
| **Hard**（邊界案例）| 20% | 理性人可能有不同意見的案例（例：九成新但無照片）|

正負樣本分布：

| 類別 | 建議比例 | 說明 |
|---|---|---|
| 好交易（Positive）| 30–40% | 真正值得購買的 |
| 一般價格（Neutral）| 20–30% | 公平定價，不特別好也不特別差 |
| 偏貴/overpriced | 15–20% | 明顯溢價 |
| 可疑/suspicious | 15–20% | 詐騙風險、描述不實、異常低價 |

### 3.3 覆蓋要求

Dataset 必須覆蓋 Domain 定義的所有主要維度（以 Marketplace 為例）：

- **平台覆蓋**：Shopee、Yahoo Auctions、Ruten 各至少 10 筆
- **類別覆蓋**：books、lego、electronics、cameras、furniture 各至少 5 筆
- **狀態覆蓋**：new、like_new、good、fair、poor 各至少 3 筆
- **邊界案例必含**：至少 3 筆「明顯詐騙」、至少 3 筆「令人疑惑的低價」

---

## 四、Marketplace Domain Golden Dataset 規格

### 4.1 資料結構

```typescript
interface GoldenListing {
  // === Input Data（這是 AI 看到的）===
  id: string                    // Dataset 內唯一 ID（非平台 ID）
  platform: 'shopee' | 'yahoo_auction' | 'ruten'
  title: string
  description: string | null
  price: number                 // TWD，已完成換算（Shopee ×100 已處理）
  shipping_cost: number
  total_price: number
  condition_raw: string         // 平台原始文字（如「九成新」）
  category: 'books' | 'lego' | 'electronics' | 'cameras' | 'furniture' | 'other'
  seller_rating: number | null
  image_count: number
  listed_at: string | null
  
  // === Annotations（這是「正確答案」）===
  annotated_condition: 'new' | 'like_new' | 'good' | 'fair' | 'poor' | 'unknown'
  annotated_deal_score: number  // 0.0–1.0，人工給的 DealScore
  annotated_deal_verdict: 'great_deal' | 'good_deal' | 'fair_price' | 'overpriced' | 'suspicious'
  is_good_deal: boolean         // 簡化版：這筆值得通知使用者嗎？
  risk_flags: RiskFlag[]        // 人工識別的風險標記
  annotation_reason: string     // 為什麼這樣標注？（必填，≥ 20 字）
  market_price_reference: number | null  // 標注時查到的市場參考價
  
  // === Metadata（Dataset 管理）===
  annotator: string             // 標注者（user / claude）
  annotation_date: string
  annotation_confidence: 'high' | 'medium' | 'low'
  difficulty: 'easy' | 'medium' | 'hard'
  dataset_version: string       // 加入時的 Dataset 版本號
  notes: string | null          // 標注者補充說明
}

type RiskFlag = 
  | 'price_suspiciously_low'
  | 'vague_description'
  | 'new_seller'
  | 'no_images'
  | 'condition_mismatch'
  | 'possible_replica'
```

### 4.2 資料集 V1.0 目標分布

| 平台 | 筆數 | 比例 |
|---|---|---|
| Shopee | 15 | 50% |
| Yahoo Auctions | 10 | 33% |
| Ruten | 5 | 17% |
| **合計** | **30** | 100% |

| Verdict | 筆數 | 比例 |
|---|---|---|
| great_deal | 6 | 20% |
| good_deal | 6 | 20% |
| fair_price | 6 | 20% |
| overpriced | 6 | 20% |
| suspicious | 6 | 20% |
| **合計** | **30** | 100% |

### 4.3 必含的困難案例（Mandatory Hard Cases）

V1 Dataset 必須包含以下難度類型，避免 Dataset 過度簡單導致評估失真：

| 類型 | 最少筆數 | 描述 |
|---|---|---|
| 明顯詐騙 | 3 | 價格極低、描述模糊、賣家評分為零或無評分 |
| 令人疑惑的低價 | 3 | 價格比市場低 60%，但描述合理（可能是搶手貨也可能是問題品）|
| 描述與照片不符 | 2 | 描述說九成新，但照片中有明顯損壞 |
| 無照片商品 | 2 | condition 聲稱 like_new，但無照片佐證 |
| 新賣家好價格 | 2 | 價格吸引人，但賣家評價數 < 5（高風險 + 高吸引力的衝突）|

---

## 五、標注流程

### 5.1 標注前準備

```
步驟 1：研究市場行情
  → 在淘寶、PChome、蝦皮搜尋相同或類似商品
  → 記錄市場參考價（market_price_reference）

步驟 2：閱讀完整商品描述
  → 包含買家評論、問答、賣家其他商品

步驟 3：查看所有商品圖片
  → 圖片與描述是否一致？有無明顯損傷？
```

### 5.2 標注決策樹

```
商品價格是否明顯低於市場 50% 以上？
  ↓ 是
  是否有合理解釋（型號較舊、有小瑕疵、清倉）？
    ↓ 是 → 考慮 good_deal 或 great_deal（視狀況）
    ↓ 否 → suspicious（異常低價無合理解釋）
  ↓ 否
商品狀況描述是否與照片一致？
  ↓ 否 → suspicious 或 condition_mismatch 風險旗標
  ↓ 是
Price Ratio = total_price / market_price_reference
  ≤ 50%    → great_deal
  51–70%   → good_deal
  71–90%   → fair_price
  91–110%  → fair_price（市場正常定價）
  > 110%   → overpriced
```

### 5.3 標注信心等級定義

| 信心等級 | 說明 | 對 Regression 的影響 |
|---|---|---|
| `high` | 有市場參考價，判斷確定 | 權重 1.0（Regression 計算完整計入）|
| `medium` | 市場行情不明確，但判斷有依據 | 權重 0.7 |
| `low` | 邊界案例，理性人可能不同意 | 權重 0.4（Regression 計算時降低影響）|

### 5.4 Annotation Reason 必填規則

標注理由不能是泛泛之詞，必須具體說明：

- ❌ 不接受："這個太貴了"
- ✅ 接受："蝦皮同款 LEGO 42083 市售均價約 NT$3,500，此賣家標價 NT$5,200，溢價約 49%，且賣家無評分，標記為 overpriced + new_seller"

---

## 六、Dataset 版本管理

### 版本號規則

```
v{major}.{minor}

minor bump（v1.0 → v1.1）：新增資料筆數（不修改現有標注）
major bump（v1.x → v2.0）：
  - 修正現有標注的錯誤
  - 新增或修改資料欄位定義
  - 大幅調整分布結構
```

### 版本管理規則

1. **只增不刪**（Append-only 原則）：Dataset 中的條目一旦加入就不刪除，即使後來發現標注有誤
2. **錯誤修正**：發現標注錯誤時，加入新版本的修正標注，並在原條目的 `notes` 中標記 "superseded by {id}"
3. **每次 Regression**：記錄使用的 Dataset 版本號，確保可以復現
4. **版本 Changelog**：每個 Dataset 版本有對應的 CHANGELOG 記錄新增和修改

### Dataset 存放路徑

```
docs/governance/golden-datasets/
├── marketplace/
│   ├── golden-dataset-v1.0.json    ← 機器可讀的標注資料
│   ├── golden-dataset-v1.0.md      ← 人類可讀的說明與統計
│   └── CHANGELOG.md                ← 版本歷史
├── stocks/
│   └── ...（未來）
```

---

## 七、Golden Dataset 的維護責任

| 責任 | 說明 |
|---|---|
| **建立**：Domain Author 或 AI Architect 負責初版（V1.0）|
| **標注**：建議 User 親自標注至少 50% 的條目（確保反映真實使用者判斷）|
| **審查**：Final Approver 抽樣審查標注品質（至少審查 20% 的條目）|
| **維護**：每季度審視 Dataset 是否需要更新（市場行情變化、發現新困難案例）|

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：通用結構、Marketplace 資料規格、標注流程、版本管理規則 |
