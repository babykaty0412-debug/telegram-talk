---
doc_type: governance
doc_id: GOVR-004
title: Product Validation Framework
status: accepted
version: "1.0"
date: 2026-06-27
related: [GOVR-001, GOVR-002, GOVR-003, GOVR-005, GOVR-006, GOVR-007]
tags: [product, validation, user-stories, kpi, acceptance-criteria, quality]
---

# Product Validation Framework

> 架構驗證（GOVR-001/002）回答「系統有沒有建對？」  
> 產品驗證（本框架）回答「我們是否在建正確的東西，且它確實為使用者創造了價值？」  
>
> **任何 Domain 在進入 Level 3（Implemented）之前，必須先定義並通過 Product Validation Gate。**

---

## 一、為什麼需要 Product Validation？

架構驗證確保系統「建得正確」（事件走 Event Bus、資料有 Repository 抽象）。  
但「建得正確」不等於「建了有用的東西」。

下面這個反例說明問題：

> Marketplace Domain 架構完美——Collector 可插拔、Analyzer 通過所有架構原則、Workflow 設計優雅。  
> 但如果 AI 的 DealScore 判斷精確度只有 40%（十個推薦有六個是爛的），使用者會直接關掉通知。  
> 這個 Domain 在架構層面是 Level 2，但在產品層面是零價值。

Product Validation 在實作之前就定義「什麼叫成功」，確保實作完成後有客觀標準可以判斷是否達標。

---

## 二、架構驗證 vs 產品驗證

| 維度 | 架構驗證（GOVR-001/002）| 產品驗證（本框架）|
|---|---|---|
| 核心問題 | 設計是否符合架構原則？ | 是否為使用者創造真實價值？ |
| 評估對象 | 文件設計、原則合規性 | 使用者行為、AI 準確性、效率 |
| 評估方式 | 清單核查、原則比對 | KPI 測量、Benchmark 比較、Dataset 驗證 |
| 何時執行 | Level 1 → Level 2 | Level 2 → Level 3（必要前置）|
| 失敗結果 | 退回設計修正 | 重新定義 User Stories 或調整設計 |
| 相關文件 | GOVR-001、GOVR-002 | GOVR-004（本）、GOVR-005、GOVR-006、GOVR-007 |

---

## 三、Product Validation Gate（Level 2 → Level 3 前置條件）

Domain 在進入 Level 3 實作前，必須完成以下所有項目：

| # | 項目 | 文件 | 說明 |
|---|---|---|---|
| PV-G1 | 定義 User Stories（≥ 3 個，含 Acceptance Criteria）| GOVR-004（本）| 明確使用者需求 |
| PV-G2 | 定義 Success Criteria | GOVR-004（本）| 「成功」的書面定義 |
| PV-G3 | 定義 KPI 與目標值 | GOVR-004（本）| 可量測的成功指標 |
| PV-G4 | 建立 Manual Baseline（人工操作基準）| GOVR-005 | AI 的對照組 |
| PV-G5 | 定義 Benchmark 方法與勝出條件 | GOVR-005 | AI 如何「贏」過手動？ |
| PV-G6 | 建立 Golden Dataset（≥ 30 筆，V1）| GOVR-006 | 評估 AI 準確性的黃金標準 |
| PV-G7 | 設定 Regression 衰退門檻 | GOVR-007 | 何時算「效能退步」？ |
| PV-G8 | 定義 Acceptance Criteria for Level 3 | GOVR-004（本）| 實作完成的判斷標準 |

所有 PV-G1 ~ PV-G8 完成後，Final Approver 批准 → Domain 可以進入 Level 3 實作。

---

## 四、Product Validation 九個組成元素

### 4.1 User Stories（使用者故事）

**格式**：
```
As a [使用者角色], I want to [行動], so that [預期效益].

Acceptance Criteria:
- AC-1: [具體可驗證的條件]
- AC-2: [...]
```

**要求**：
- 每個 Domain ≥ 3 個 User Stories
- 每個 Story 必須有 ≥ 2 個 Acceptance Criteria
- Criteria 必須可驗證（可以說「這個通過了」或「這個沒通過」）
- 涵蓋 Happy Path + 至少 1 個 Edge Case

**禁止寫法**：
- "As a user, I want the system to be fast" → 太模糊，無法驗證
- "As a user, I want good recommendations" → 「好」未定義

**好的寫法**：
- "As a user, I want to receive alerts only for listings matching my WatchRule criteria, so that I don't waste time reviewing irrelevant items."
  - AC-1: Alert is triggered only when listing.total_price ≤ WatchRule.max_total_price
  - AC-2: Alert is triggered only when listing.condition ≥ WatchRule.min_condition
  - AC-3: No alert is sent for listings I have already seen in the past 7 days

---

### 4.2 Success Criteria（成功標準）

**定義**：以使用者角度描述「這個 Domain 被視為成功」的條件。

**格式**：
```
SC-01: [可驗證的成功條件]
SC-02: [...]
```

**要求**：
- ≥ 3 個 Success Criteria
- 每個 Criteria 與至少 1 個 KPI 對應
- 使用者能直接感受到的結果（而非技術指標）

**好的範例**：
- SC-01：使用者每週因 AI 推薦節省 ≥ 25 分鐘的手動搜尋時間
- SC-02：使用者收到的通知中 ≥ 70% 被認為「值得查看」（不是廢棄訊息）
- SC-03：AI 找到的好機會中，至少有 50% 是使用者手動搜尋時會錯過的

---

### 4.3 KPI（關鍵績效指標）

**要求**：每個 KPI 必須有：目標值、測量方式、測量頻率

**標準 KPI 維度**：

| 維度 | 說明 | 典型指標 |
|---|---|---|
| **Accuracy**（準確性）| AI 判斷有多正確？ | Precision、Recall、F1 Score |
| **Efficiency**（效率）| AI 省了多少時間？ | Time Saved / Week、Automation Rate |
| **Coverage**（覆蓋率）| AI 找到了多少人工找不到的？ | Coverage vs Manual |
| **Alert Quality**（通知品質）| 通知是否讓使用者信任？ | Alert Acceptance Rate、False Positive Rate |
| **Reliability**（可靠性）| 系統是否穩定運行？ | Workflow Success Rate、Uptime |

---

### 4.4 Evaluation Metrics（評估指標）

AI 準確性的標準評估指標：

**分類指標**（用於 deal_verdict）：
```
Precision = TP / (TP + FP)
  → 所有 AI 標記為「好交易」的商品中，真正是好交易的比例

Recall = TP / (TP + FN)
  → 所有真正的好交易中，AI 成功找到的比例

F1 Score = 2 × (Precision × Recall) / (Precision + Recall)
  → 綜合指標，當 Precision 和 Recall 都重要時使用
```

**回歸指標**（用於 DealScore 這類連續分數）：
```
MAE（Mean Absolute Error）= 平均預測誤差
  → 平均每個 listing 的 DealScore 與 Golden Dataset 標注值差多少

Spearman Correlation = AI 排名與人工排名的相關性
  → AI 是否能正確區分好交易和差交易的相對順序？
```

---

### 4.5 Benchmark（AI vs 手動基準）

→ 詳見 GOVR-005（Benchmark Strategy）

核心原則：定義「人工操作基準」，再衡量 AI 相對於基準的提升。

---

### 4.6 Golden Dataset（黃金資料集）

→ 詳見 GOVR-006（Golden Dataset Specification）

核心原則：收集真實資料，由人工標注「正確答案」，作為評估 AI 準確性的不可移動基準。

---

### 4.7 Replay（重播）

→ 詳見 GOVR-007（Replay & Regression Strategy）

核心原則：將 Golden Dataset 輸入 AI 流程，取得 AI 輸出，與人工標注比較。

---

### 4.8 Regression Testing（退化測試）

→ 詳見 GOVR-007（Replay & Regression Strategy）

核心原則：在任何 AI 模型或 Prompt 變更後，確認系統沒有退步。

---

### 4.9 Acceptance Criteria for Level 3（Level 3 驗收標準）

**格式**：
```
Level 3 Acceptance Criteria for {Domain}:
- AC-L3-01: [具體可測量的標準]
- AC-L3-02: [...]
```

**要求**：
- 必須引用 KPI 的具體數字
- 必須可以自動測量（不依賴主觀判斷）
- 所有 AC 通過 → Domain 才能從 Level 3 進入 Level 4 觀察期

---

## 五、Per-Domain Product Validation Spec（域別 PV 規格）

每個 Domain 在申請 Level 3 之前，必須建立一份 **Domain PV Spec 文件**：

**路徑**：`docs/governance/product-validation/{domain}-pv-spec.md`

**文件模板**（需填入的內容）：

```markdown
---
doc_type: governance
doc_id: GOVR-PV-{DOMAIN}-001
title: {Domain} Product Validation Spec
status: draft
version: "1.0"
date: YYYY-MM-DD
related: [GOVR-004, GOVR-005, GOVR-006, GOVR-007, DOMAIN-XXX]
---

# {Domain} Product Validation Spec

## 一、User Stories

### US-01: {標題}
As a {使用者角色}, I want to {行動}, so that {效益}.

Acceptance Criteria:
- AC-1: ...
- AC-2: ...

### US-02: {標題}
...

## 二、Success Criteria

| ID | 成功條件 | 對應 KPI |
|---|---|---|
| SC-01 | ... | KPI-01 |
| SC-02 | ... | KPI-02 |

## 三、KPI

| ID | 指標名稱 | 目標值 | 測量方式 | 測量頻率 |
|---|---|---|---|---|
| KPI-01 | ... | ≥ X% | ... | 每次 Replay |

## 四、Manual Baseline

{描述不使用 AI 時，使用者如何完成同樣任務}
{估計手動操作所需時間、找到結果的品質、覆蓋範圍}

## 五、Benchmark 勝出條件

{AI 在哪些指標上必須優於 Manual Baseline，才算「有價值」}

## 六、Golden Dataset 需求

- 最小規模: N 筆
- 分類分布: {各類別比例}
- 平台分布: {各平台比例}
- 必含的困難案例: {描述}

## 七、Regression 門檻

| 指標 | 基準值（首次 Replay）| 衰退門檻（觸發 Regression Fail）|
|---|---|---|
| Precision | 建立後填入 | 基準 - 5% |
| Recall | 建立後填入 | 基準 - 8% |

## 八、Level 3 Acceptance Criteria

| ID | 驗收條件 | 測量方式 |
|---|---|---|
| AC-L3-01 | ... | Replay on Golden Dataset |
| AC-L3-02 | ... | ... |
```

---

## 六、Product Validation 在成熟度模型中的位置

```
Level 2: Validated（架構正確）
  ↓
  ┌─────────────────────────────────────────────┐
  │ Product Validation Gate（PV-G1 ~ PV-G8）    │
  │  PV-G1: User Stories 定義完成               │
  │  PV-G2: Success Criteria 定義完成           │
  │  PV-G3: KPI 與目標值確定                    │
  │  PV-G4: Manual Baseline 建立               │
  │  PV-G5: Benchmark 勝出條件定義              │
  │  PV-G6: Golden Dataset 建立（≥ 30 筆）      │
  │  PV-G7: Regression 門檻設定                 │
  │  PV-G8: Level 3 Acceptance Criteria 定義   │
  └─────────────────────────────────────────────┘
  ↓ Final Approver 批准
Level 3: Implemented（實作完成，通過 AC-L3 所有條件）
```

**重要**：Product Validation Gate 的輸出是「定義清楚了什麼叫成功」，而不是「成功已達成」。  
實際的 AI 準確性測量（Replay）在 Level 3 實作完成後才執行，用來決定是否可以進入 Level 4。

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：定義 9 個 Product Validation 元素、PV Gate（PV-G1~G8）、Domain PV Spec 模板 |
