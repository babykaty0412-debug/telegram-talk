---
doc_type: governance
doc_id: GOVR-007
title: Replay & Regression Strategy
status: accepted
version: "1.0"
date: 2026-06-27
related: [GOVR-004, GOVR-005, GOVR-006]
tags: [replay, regression, testing, ai-evaluation, quality]
---

# Replay & Regression Strategy

> Replay 問：「AI 現在的表現有多好？」  
> Regression 問：「AI 有沒有變得比上次更差？」  
>
> 這兩個問題合起來保護 PAOS 不會在 AI 模型升級、Prompt 調整、或程式碼修改後，悄悄地讓系統品質退步。

---

## 一、核心概念

### Replay（重播）

**定義**：將 Golden Dataset 的 Input Data 輸入現有 AI Analyzer，取得 AI 輸出，再與 Golden Dataset 的 Annotations 比較。

**目的**：
- 知道「目前的 AI 準確率是多少」
- 得到一個可以比較的基準數字

**比喻**：Replay 就像「把已知答案的考卷給 AI 做，看它考幾分」。每次做 Replay，就知道 AI 目前的分數。

### Regression（退化偵測）

**定義**：比較「本次 Replay 的分數」與「上次 Replay 的分數」，判斷是否有顯著退步。

**目的**：
- 確保 AI 模型升級、Prompt 修改、程式碼重構後，系統沒有變差
- 在退化到使用者能感受到之前，提前在技術層面偵測

**比喻**：Regression 就像「同一本考卷做了兩次，看第二次有沒有比第一次考差」。如果差距超過門檻，就需要查原因。

---

## 二、Replay 執行規格

### 2.1 Replay Pipeline

Replay 繞過 Collector 和 Parser，直接將 Golden Dataset 的資料輸入 Analyzer：

```
Golden Dataset（JSON）
  ↓
[GoldenDatasetLoader]
  → 讀取 golden-dataset-v{X}.json
  → 轉換為 Analyzer 需要的 Input 格式
  ↓
[Analyzer]（Domain Analyzer，例：MarketplaceValueAnalyzer）
  → 使用真實的 AI 模型和 Prompt
  → 不使用任何 cached 結果
  ↓
[ResultCollector]
  → 收集所有 AI 輸出
  ↓
[MetricsCalculator]
  → 比較 AI 輸出 vs Golden Dataset Annotations
  → 計算所有評估指標
  ↓
[ReplayReport]
  → 輸出完整報告（見第三節）
```

**重要約束**：
- Replay 必須使用**真實的 AI 模型**（不是 mock），確保評估真實效能
- Replay 必須記錄使用的 AI 模型版本號（`model_used`）
- 每次 Replay 的所有 AI 輸出必須完整儲存（用於後續分析和比較）

### 2.2 Replay 執行模式

| 模式 | 說明 | 何時使用 |
|---|---|---|
| **Full Replay** | 整個 Golden Dataset | 正式評估（Level 3/4 晉升）|
| **Quick Replay** | 隨機抽取 30% 資料 | 日常開發驗證、快速健康檢查 |
| **Category Replay** | 只評估特定類別 | 新增某類別資料後的定向驗證 |
| **Hard Cases Replay** | 只執行難度 hard 的條目 | 評估 AI 處理困難案例的能力 |

### 2.3 Replay 觸發時機

| 觸發條件 | Replay 模式 | 強制？ |
|---|---|---|
| Domain 申請 Level 3 晉升 | Full Replay | ✅ 強制 |
| Domain 申請 Level 4 晉升 | Full Replay | ✅ 強制 |
| AI 模型版本升級（如 haiku-4-5 → haiku-5.0）| Full Replay | ✅ 強制 |
| Analyzer Prompt 重大修改（改變判斷邏輯）| Full Replay | ✅ 強制 |
| Analyzer Prompt 小幅修改（措辭優化）| Quick Replay | ✅ 強制 |
| Golden Dataset 新增 ≥ 10 筆資料 | Category Replay | ✅ 強制 |
| Production 月度健康檢查 | Full Replay | ✅ 強制 |
| 開發時的自我驗證 | Quick Replay | 建議 |

---

## 三、Replay 報告格式

每次 Full Replay 必須輸出一份報告，存放於：  
`docs/governance/product-validation/{domain}-replay-{date}-{model}.md`

```markdown
# {Domain} Replay Report

## 執行資訊
| 欄位 | 值 |
|---|---|
| 執行日期 | YYYY-MM-DD HH:MM |
| Domain 版本 | v{X.Y} |
| Golden Dataset 版本 | v{X.Y}（共 N 筆）|
| AI 模型 | {model_id} |
| Replay 模式 | Full / Quick / Category / Hard |
| 執行者 | {user / claude} |

## 評估指標

### 分類準確性
| 指標 | 值 | 較上次 Replay |
|---|---|---|
| Overall Precision | X% | ↑/↓ X% |
| Overall Recall | X% | ↑/↓ X% |
| F1 Score | X.XX | ↑/↓ X.XX |

### 分類別精確率
| 類別 | Precision | Recall | 筆數 |
|---|---|---|---|
| great_deal | | | |
| good_deal | | | |
| fair_price | | | |
| overpriced | | | |
| suspicious | | | |

### DealScore 誤差（若適用）
| 指標 | 值 |
|---|---|
| MAE（Mean Absolute Error）| |
| Spearman Correlation | |

### 難度分析
| 難度 | Precision | 筆數 |
|---|---|---|
| Easy | | |
| Medium | | |
| Hard | | |

## 失敗案例分析

> 列出所有 AI 判斷錯誤的案例（限 Top 10 最嚴重錯誤）

| ID | 商品標題 | AI 判斷 | 正確答案 | AI 的 DealScore | 正確 DealScore | 分析 |
|---|---|---|---|---|---|---|

## Regression 判定

[見第四節的 Regression 判定結果]

## 結論與建議

[整體評估、主要問題、是否達到 Level Acceptance Criteria]
```

---

## 四、Regression 偵測規格

### 4.1 Regression 門檻

Regression 比較「本次 Replay」與「最後一次 accepted Replay」的指標。

**硬門檻（Hard Threshold）——觸發立即失敗**：

| 指標 | 絕對最低值 | 說明 |
|---|---|---|
| Overall Precision | < 50% | 低於此值 AI 對使用者是負擔而非幫助 |
| F1 Score | < 0.45 | 精確率與召回率的綜合指標太低 |
| Hard Cases Precision | < 35% | AI 完全無法處理困難案例 |

**軟門檻（Soft Threshold）——觸發 Regression Warning**：

| 指標 | 衰退警告門檻 | 說明 |
|---|---|---|
| Overall Precision | 較基準 ↓ > 5% | 例：70% → 64% 觸發警告 |
| Overall Recall | 較基準 ↓ > 8% | 召回率允許較大波動 |
| F1 Score | 較基準 ↓ > 0.05 | |
| Hard Cases Precision | 較基準 ↓ > 10% | 困難案例的精確率允許較大波動 |

### 4.2 Regression 判定流程

```
取得本次 Replay 指標
  ↓
觸發任何 Hard Threshold？
  ↓ 是 → Regression FAIL（嚴重）
           → 必須立即停止晉升流程
           → 回滾到上個版本的 AI 模型 / Prompt
           → 找出根本原因後重新 Replay
  ↓ 否 → 繼續
         ↓
觸發任何 Soft Threshold？
  ↓ 是 → Regression WARNING（警告）
           → 記錄警告，不阻止晉升
           → 必須在 Replay 報告中分析原因
           → 下次 Replay 若繼續退步則升級為 FAIL
  ↓ 否 → No Regression（通過）
           → 更新 Accepted Replay 基準
```

### 4.3 Regression 基準更新規則

「Accepted Replay 基準」是 Regression 比較的對照點，更新規則：

| 條件 | 動作 |
|---|---|
| Replay 通過，無 Regression | 更新基準為本次 Replay 指標 |
| Replay 有 Regression WARNING | **不更新**基準（基準保持不變）|
| Replay 有 Regression FAIL | **不更新**基準，且必須修正後重做 |
| 手動認定某次 Replay 為新基準 | Final Approver 可以手動設定（需文件化原因）|

---

## 五、Level Acceptance Criteria（各等級的 Replay 通過標準）

### Level 3 入場標準（Product Validation Gate 的一部分）

Domain 在進入 Level 3 之前，Replay 結果必須達到：

| 指標 | 最低要求 | 說明 |
|---|---|---|
| Overall Precision | ≥ 65% | AI 推薦中至少 65% 是正確的 |
| Overall Recall | ≥ 50% | 至少找到一半的好機會 |
| F1 Score | ≥ 0.56 | 綜合指標 |
| Suspicious 類 Precision | ≥ 70% | 對可疑商品的識別不能太差（關係到使用者安全）|
| No Hard Threshold Breach | 必需 | 不能觸發任何硬門檻 |

**注意**：Level 3 入場的 Replay 標準是基於**設計原型的評估**，不是實際程式碼。  
如果 Level 2 → Level 3 的 Product Validation Gate 需要執行 Quick Replay，可以使用 Domain 設計文件中定義的 Analyzer Prompt，透過 API 直接呼叫，不需要完整實作。

### Level 4 入場標準（實際程式碼的效能）

| 指標 | 最低要求 |
|---|---|
| Overall Precision | ≥ 68% |
| Overall Recall | ≥ 55% |
| F1 Score | ≥ 0.61 |
| No Regression vs Level 3 Baseline | 必需 |

### Level 5 Golden Domain 標準

| 指標 | 最低要求 |
|---|---|
| Overall Precision | ≥ 72% |
| Hard Cases Precision | ≥ 55% |
| No Regression（6 個月內）| 必需 |

---

## 六、Replay 失敗的根因分析框架

當 Replay 顯示 AI 準確率偏低時，使用以下框架找出根本原因：

### 失敗模式分類

| 失敗模式 | 症狀 | 根本原因 | 修復方向 |
|---|---|---|---|
| **Prompt 描述不清**| AI 在「邊界案例」大量失敗 | Prompt 沒有說清楚邊界條件 | 在 Prompt 中加入具體的判斷規則 |
| **市場行情過時**| AI 對「overpriced」判斷準確但 DealScore 偏高 | Knowledge 中的市場參考價過舊 | 更新 CategoryThresholds 和 MarketPrice Knowledge |
| **模型能力不足**| Hard Cases 全部失敗，Easy Cases 正常 | AI 模型理解能力的上限 | 升級 AI 模型（如從 haiku 改為 sonnet）|
| **訓練資料偏差**| 特定類別（如 cameras）準確率明顯偏低 | Golden Dataset 該類別樣本太少 | 擴充 Dataset 的該類別樣本 |
| **平台格式變化**| 某個平台的所有商品判斷錯誤 | 平台 Condition 文字格式改變，Parser 未更新 | 更新 Parser 的 ConditionNorm 對應表 |

### 根因分析步驟

```
步驟 1：按難度分析（Easy / Medium / Hard 分別看）
  → Easy 也失敗？→ 基礎問題（Prompt 定義或資料格式）
  → 只有 Hard 失敗？→ AI 能力上限或邊界規則不清
         ↓
步驟 2：按類別分析（各 verdict 的 Precision 分開看）
  → 某個 verdict 特別差？→ 可能是 Prompt 對這個類別描述不足
         ↓
步驟 3：按平台分析（各平台分開看）
  → 某個平台特別差？→ 可能是 Parser 或平台特有格式問題
         ↓
步驟 4：檢查失敗案例的 AI 理由
  → AI 給的 reason 欄位是否顯示出 AI 誤解了什麼？
         ↓
步驟 5：決定修復方向（Prompt / Knowledge / Dataset / Model）
```

---

## 七、Regression 報告存放

```
docs/governance/product-validation/{domain}-replay-{YYYYMMDD}-{model-short}.md

例：
  marketplace-replay-20260901-haiku45.md
  marketplace-replay-20260930-haiku45.md  ← 月度 Production 檢查
  marketplace-replay-20261001-sonnet46.md ← 模型升級後的驗證
```

**Replay 歷史清單**：每個 Domain 在 `docs/governance/product-validation/` 目錄下維護一份 `{domain}-replay-index.md`，列出所有歷史 Replay 的日期、模型、指標摘要和結論。

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：Replay Pipeline、Regression 門檻、Level Acceptance Criteria、根因分析框架 |
