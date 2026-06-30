# Marketplace Golden Dataset v1.0 — 說明與標註指南

> **狀態：待標註（pending_annotation）** — `golden-dataset-v1.0.json` 的 `entries[]` 目前為空。  
> 這是**刻意**的：Golden Dataset 的 Ground Truth 必須由**人工**標註，不能由 AI 產生（否則準確率量測無意義）。  
> 規格依 GOVR-006；建立流程依 GOVR-PV-MKT-002 §五。

---

## 一、這份資料集要做什麼

評估 Marketplace 的 AI 分析（DealScore、verdict、risk_flags）有多準——方法是把**已知正確答案**（人工標註）的真實 listing 餵給 AI，比對 AI 的輸出與正確答案。

- 用於 **Replay**（GOVR-007）：量測準確率
- 用於 **Regression**：偵測 AI 版本退化
- 用於 **Price Analysis Accuracy**（GOVR-PV-MKT-002 驗證 #6）

---

## 二、目標分布（30 筆）

| 平台 | 筆數 |
|---|---|
| Shopee | 15 |
| Yahoo Auctions | 10 |
| Ruten | 5 |

| Verdict | 筆數 |
|---|---|
| great_deal | 6 |
| good_deal | 6 |
| fair_price | 6 |
| overpriced | 6 |
| suspicious | 6 |

- 類別：books / lego / electronics / cameras / furniture 各 ≥ 6 筆
- 難度：Easy 40% / Medium 40% / Hard 20%
- 必含 hard cases ≥ 11 筆（3 明顯詐騙 / 3 疑惑低價 / 2 描述照片不符 / 2 無照片 / 2 新賣家好價）

---

## 三、標註欄位（每筆，依 GOVR-006 §4.1）

**Input（AI 會看到）**：platform, title, description, price, shipping_cost, total_price, condition_raw, category, seller_rating, image_count, listed_at

**Annotations（正確答案，人工填）**：
- `annotated_condition`：new / like_new / good / fair / poor / unknown
- `annotated_deal_score`：0.0–1.0
- `annotated_deal_verdict`：great_deal / good_deal / fair_price / overpriced / suspicious
- `is_good_deal`：true / false（值得通知嗎）
- `risk_flags`：[]（人工識別的風險）
- `annotation_reason`：**必填，≥ 20 字，具體**
- `market_price_reference`：標註時查到的市場行情價

**Metadata**：annotator, annotation_date, annotation_confidence(high/medium/low), difficulty(easy/medium/hard), dataset_version

---

## 四、標註決策樹（GOVR-006 §5.2）

```
價格明顯低於市場 50%+ ?
  是 → 有合理解釋(舊型號/小瑕疵/清倉)? 是→good/great_deal；否→suspicious
  否 → 狀況描述與照片一致?
        否 → suspicious 或 condition_mismatch
        是 → price_ratio = total_price / market_price
              ≤50% great_deal｜51–70% good_deal｜71–90% fair_price
              91–110% fair_price｜>110% overpriced
```

---

## 五、標註範例（⚠️ 僅供教學示範，不是真實資料，不可放入 entries）

> 以下兩筆是**示範如何標註**，幫助標註者理解格式。它們是構造的教學例，**不得**當成真實 Ground Truth 寫入 `golden-dataset-v1.0.json`。

```jsonc
// 示範 A（教學用，非真實）：good_deal
{
  "id": "EXAMPLE-do-not-use",
  "platform": "shopee",
  "title": "LEGO 60197 城市系列 客運火車 二手 九成新",
  "price": 890, "shipping_cost": 0, "total_price": 890,
  "condition_raw": "九成新", "category": "lego",
  "seller_rating": 4.8, "image_count": 3,
  "annotated_condition": "like_new",
  "annotated_deal_score": 0.80,
  "annotated_deal_verdict": "good_deal",
  "is_good_deal": true,
  "risk_flags": [],
  "annotation_reason": "蝦皮同款 60197 全新均價約 NT$1,499，此件 NT$890（約 59%），九成新含盒，賣家 4.8 分，值得購買。",
  "market_price_reference": 1499,
  "annotation_confidence": "high", "difficulty": "easy"
}

// 示範 B（教學用，非真實）：suspicious
{
  "id": "EXAMPLE-do-not-use",
  "platform": "ruten",
  "title": "Canon EF 50mm f/1.8 鏡頭 便宜出清",
  "price": 450, "shipping_cost": 0, "total_price": 450,
  "condition_raw": null, "category": "cameras",
  "seller_rating": null, "image_count": 0,
  "annotated_condition": "unknown",
  "annotated_deal_score": 0.10,
  "annotated_deal_verdict": "suspicious",
  "is_good_deal": false,
  "risk_flags": ["price_suspiciously_low", "no_images", "new_seller", "vague_description"],
  "annotation_reason": "市場行情約 NT$3,000，此件僅 NT$450（15%），無照片、描述模糊、賣家無評分，高度疑似詐騙。",
  "market_price_reference": 3000,
  "annotation_confidence": "high", "difficulty": "hard"
}
```

---

## 六、完成檢查清單

- [ ] 蒐集 30 筆**真實** listing（非構造）
- [ ] 分布符合 §二
- [ ] hard cases ≥ 11 筆
- [ ] 每筆 annotation_reason ≥ 20 字且具體
- [ ] Final Approver 抽查 ≥ 20%
- [ ] 寫入 `golden-dataset-v1.0.json`，status 改為 `published`
- [ ] 更新 `CHANGELOG.md`
