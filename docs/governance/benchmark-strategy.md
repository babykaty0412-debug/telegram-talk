---
doc_type: governance
doc_id: GOVR-005
title: Benchmark Strategy
status: accepted
version: "1.0"
date: 2026-06-27
related: [GOVR-004, GOVR-006, GOVR-007]
tags: [benchmark, evaluation, ai-vs-manual, metrics, quality]
---

# Benchmark Strategy

> Benchmark 回答一個核心問題：  
> **AI 是否比「人自己做」更好、更快、或覆蓋更廣？**  
> 如果 AI 帶來的提升不顯著，這個 Domain 就不值得實作。

---

## 一、Benchmark 的設計哲學

### 為什麼需要 AI vs Manual Benchmark？

PAOS 的每個 Domain 都有對應的「使用者原本怎麼做這件事」——

| Domain | Manual 方式 |
|---|---|
| Marketplace | 手動瀏覽蝦皮、Yahoo、露天，判斷哪些是好價格 |
| Stocks（未來）| 手動看財報、新聞，判斷個股走勢 |
| Jobs（未來）| 手動瀏覽 104、Linkedin，篩選符合條件的職缺 |

Benchmark 的目的：
1. **設立對照組（Baseline）**：如果沒有 AI，使用者能做到什麼程度？
2. **定義勝出條件**：AI 需要在哪些維度「贏過」手動才算有價值？
3. **量化 AI 的提升**：AI 到底省了多少時間、找到了多少人工找不到的東西？

### Benchmark 不是「AI 越準越好」

Benchmark 評估的是**相對價值**，不是絕對準確性：

- 人工精確度 70%，AI 精確度 65%：AI 沒有提升精確度，但如果 AI 覆蓋了 10 倍的資料量，仍然有價值
- 人工覆蓋 30 個商品/天，AI 覆蓋 3000 個商品/天：哪怕 AI 精確度只有 55%，找到好機會的絕對數量仍大幅勝出

**多維度評估，才能判斷真實價值。**

---

## 二、Manual Baseline 的建立

在設計 Benchmark 之前，必須先建立 **Manual Baseline**——量化「不使用 AI 時的現狀」。

### Manual Baseline 的四個維度

| 維度 | 說明 | 如何測量 |
|---|---|---|
| **Time Investment**（時間投入）| 手動完成任務需要多少時間？ | 實際計時，或估算（X 分鐘/次 × Y 次/週）|
| **Coverage**（覆蓋範圍）| 手動能覆蓋多少資料？ | 數量：X 個平台、Y 個商品/次 |
| **Accuracy**（判斷準確性）| 手動判斷有多準確？ | 對照 Golden Dataset 標注，計算 Precision/Recall |
| **Cognitive Load**（認知負荷）| 手動搜尋是否累？有無遺漏疲勞？| 主觀評估（高/中/低）|

### Manual Baseline 建立步驟

```
步驟 1：定義 Manual Task（手動任務描述）
  例："每週在蝦皮、Yahoo、露天搜尋 LEGO 好價格"
         ↓
步驟 2：執行 Manual Task（至少 2 週，建立實際數據）
  記錄：每次花費時間、找到幾個「覺得值得看」的商品
         ↓
步驟 3：對照 Golden Dataset 評分（可選，若 Dataset 已建立）
  計算：手動找到的好交易中，有幾個在 Golden Dataset 的標注中也是好交易？
         ↓
步驟 4：記錄 Baseline 數字
  輸出：Manual Baseline 指標表（格式見下方）
```

### Manual Baseline 記錄格式

```
Manual Baseline for {Domain}

測量期間: YYYY-MM-DD 至 YYYY-MM-DD（至少 2 週）
執行者: {User}

| 維度 | 測量值 | 備註 |
|---|---|---|
| Time Investment | X 分鐘/週 | X 次/週 × Y 分鐘/次 |
| Platforms Covered | N 個 | 列出平台名稱 |
| Items Reviewed / Week | ~N 個 | 平均每週手動查看的商品數 |
| "Good Deal" Found / Week | ~N 個 | 平均每週找到的好交易數 |
| Estimated Precision | ~X% | 主觀估計，找到的「好交易」中有多少真的買了或值得買 |
| Cognitive Load | 高/中/低 | 主觀評估 |
```

---

## 三、AI 效能的評估維度

### 維度一：Accuracy（準確性）

AI 的判斷與人工判斷有多一致？

```
Precision（精確率）= 正確的 AI 推薦 / 所有 AI 推薦
  → AI 推薦 10 個，其中 7 個真的是好交易 → Precision = 70%

Recall（召回率）= AI 找到的好交易 / 所有實際好交易
  → Golden Dataset 裡有 20 個好交易，AI 找到 12 個 → Recall = 60%

F1 Score = 2 × (P × R) / (P + R)
  → F1 = 2 × (0.7 × 0.6) / (0.7 + 0.6) ≈ 0.646
```

**說明**：Precision 和 Recall 通常有取捨。PAOS 的取捨原則：
- **優先 Precision**：寧可少推薦，但推薦的都是真正好的（避免 Alert Fatigue）
- **可犧牲 Recall**：遺漏一些好交易是可以接受的，讓使用者看到的每個通知都有價值

### 維度二：Coverage（覆蓋率）

AI 相對於手動操作覆蓋了多少倍的資料？

```
AI Coverage Factor = AI 掃描商品數 / 人工瀏覽商品數（同時間內）

例：AI 每 30 分鐘掃描 500 個商品，每天 = 24,000 個
    人工每天瀏覽 ~50 個商品
    Coverage Factor = 24,000 / 50 = 480×
```

即使 AI 精確度略低於人工，如果 Coverage 是 480 倍，找到好交易的**絕對數量**會遠超人工。

### 維度三：Timeliness（及時性）

AI 能多快找到新出現的好機會？

```
人工：每天瀏覽 1-3 次，最長 24 小時才看到新商品
AI：每 30 分鐘掃描一次，平均 15 分鐘發現新機會
Timeliness Advantage = 人工延遲 / AI 延遲
```

對於「好機會很快就被搶走」的 Domain，及時性是關鍵指標。

### 維度四：Cognitive Load（認知負荷）

AI 幫使用者做了多少「篩選」工作？

```
Noise Reduction Rate = 1 - (Alert 數量 / 掃描商品總數)
  → 掃描 500 個商品，只發送 5 個通知 → Noise Reduction = 99%

Alert Acceptance Rate = 使用者「接受」（點進去看、加入觀察清單）的 Alert / 總 Alert 數
  → 10 個通知，使用者點了 8 個 → Acceptance Rate = 80%
```

---

## 四、Benchmark 勝出條件（AI Win Conditions）

**AI 需要在以下條件中符合 ≥ 3 項，才算「有價值」可以進入 Level 3 實作：**

| # | 勝出條件 | 通用目標 | 說明 |
|---|---|---|---|
| WIN-01 | AI Precision ≥ Manual Precision × 0.85 | 不低於人工精確度的 85% | AI 判斷品質不能比人工差太多 |
| WIN-02 | AI Coverage Factor ≥ 5× | 覆蓋至少 5 倍資料 | AI 的核心優勢是廣度 |
| WIN-03 | Time Saved ≥ 20 分鐘/週 | 節省至少 20 分鐘 | 使用者能感受到的效率提升 |
| WIN-04 | Timeliness Advantage ≥ 3× | 比人工快 3 倍發現 | 對時間敏感的 Domain 重要 |
| WIN-05 | Alert Acceptance Rate ≥ 60% | 6/10 的通知被認為有價值 | 避免通知被忽略 |

**失敗條件（任一觸發 → 重新審視是否值得做這個 Domain）**：

| # | 失敗條件 | 說明 |
|---|---|---|
| FAIL-01 | AI Precision < 50% | AI 推薦有超過一半是廢的，對使用者是負擔而非幫助 |
| FAIL-02 | Time Saved < 10 分鐘/週 | AI 省下的時間不到人工建立 Workflow 的維護成本 |
| FAIL-03 | Alert Acceptance Rate < 40% | 使用者開始忽視通知，AI 系統失去信任 |

---

## 五、Benchmark 實驗設計

### A/B 實驗設計（推薦方式）

當 Domain 實作完成後（Level 3），進行正式 Benchmark：

```
Phase 1（Baseline Period，2 週）
  → 不使用 AI，手動操作並記錄數據
  → 對照 Golden Dataset 計算手動 Precision/Recall

Phase 2（AI Period，2 週）
  → 使用 AI，記錄所有 Alert 和使用者反應
  → 對照 Golden Dataset 計算 AI Precision/Recall

比較 Phase 1 vs Phase 2 的所有指標
```

**注意**：Phase 1 和 Phase 2 必須在類似的時間條件下執行（例如同樣是平日）。

### 快速 Benchmark（使用 Golden Dataset，無需等待）

在 Golden Dataset 建立後，可以立即進行離線 Benchmark：

```
步驟 1：將 Golden Dataset 的 Listing 輸入 Analyzer（Replay）
步驟 2：比較 AI 輸出的 deal_verdict 與 Golden Dataset 的 annotated_deal_verdict
步驟 3：計算 Precision、Recall、F1
步驟 4：對照 Benchmark 勝出條件評估
```

快速 Benchmark 不能替代真實 A/B 實驗，但可以在 Level 2 → Level 3 的 Product Validation Gate 階段提前評估 AI 設計的可行性。

---

## 六、Benchmark 記錄格式

每次完整 Benchmark 必須產出記錄文件：

**路徑**：`docs/governance/product-validation/{domain}-benchmark-{version}.md`

**必填欄位**：

```markdown
# {Domain} Benchmark Report

## 執行資訊
- 類型: Quick（Golden Dataset）/ Full A/B
- 執行日期: 
- Domain 版本:
- AI 模型:

## Manual Baseline
[填入 Manual Baseline 指標]

## AI 效能
[填入 AI 各維度指標]

## 勝出條件評估
| 條件 | 目標 | 實際 | 通過？ |
| WIN-01 | ... | ... | ✅/❌ |
...

## 結論
[AI 是否達到 Product Validation 勝出條件？通過幾項？]
```

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：Manual Baseline 建立方法、四個評估維度、五個勝出條件、Benchmark 實驗設計 |
