---
doc_type: adr
doc_id: ADR-0005
title: Workflow Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0003, ADR-0007, ADR-0010]
tags: [workflow, automation, modularity]
---

# ADR-0005: Workflow Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 需要自動化複雜的多步驟任務：爬取資料 → AI 分析 → 優先級評估 → 發送通知。這些任務的步驟可以重複組合，且每個 Domain（股票、二手商品）都會有自己的 Workflow。

如果每個 Domain 都自己寫一套流程，很快就會產生重複邏輯且難以維護。

---

## 決策（Decision）

**Workflow 完全模組化：每個 Workflow 由獨立的 Step 組成，Step 可以跨 Workflow 重用。Workflow 的觸發方式（事件、排程、手動）與執行邏輯完全分離。**

---

## Workflow 模型

### 核心概念

```
Trigger（觸發器）
  └── Workflow（工作流程）
        ├── Step 1（資料收集）
        ├── Step 2（AI 分析）
        ├── Step 3（優先級評估）
        └── Step 4（通知）
```

### Step 結構

```
Step {
  id: string
  name: string
  input_schema: JSONSchema       # 定義此 Step 接收什麼輸入
  output_schema: JSONSchema      # 定義此 Step 產生什麼輸出
  error_policy: retry | skip | abort
  timeout_ms: number
}
```

### Trigger 類型

| 類型 | 範例 |
|---|---|
| Schedule | 每天 08:00 執行「晨報摘要」 |
| Event | 新 Telegram 訊息 → 執行「對話處理」 |
| Manual | 使用者主動呼叫 |
| Threshold | 股價跌破門檻 → 執行「警示 Workflow」 |

---

## 可重用 Step 範例

| Step 名稱 | 功能 | 可用於 |
|---|---|---|
| `fetch-rss` | 爬取 RSS 來源 | 股票新聞、AI 新聞 |
| `ai-summarize` | AI 摘要 | 任何文字輸入 |
| `ai-classify` | AI 分類 | 商品分類、新聞分類 |
| `priority-score` | 計算優先級分數 | 所有需要排序的 Workflow |
| `notify` | 發送通知 | 任何需要通知的 Workflow |

---

## 後果（Consequences）

### 正面影響
- 新增 Domain 只需組合現有 Step，不需要重寫邏輯
- Step 的 input/output schema 讓錯誤提早在設計階段被發現

### 負面影響（需接受的取捨）
- 需要一個 Workflow Engine 來執行和管理 Workflow
- 初期設計 Step schema 需要投入時間

---

## 實施原則

1. Step 必須是**無副作用（pure）**的：相同輸入永遠產生相同輸出
2. 副作用（寫入知識庫、發送通知）只能在最後一個 Step 或專用的 Side-effect Step 中執行
3. 每個 Workflow 的定義以 YAML 或 JSON 儲存（不是程式碼），讓非工程師也能閱讀
4. Workflow 必須可以在不影響其他 Workflow 的前提下獨立停用

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | Workflow Engine 自建還是用現成框架（Temporal、BullMQ）？ | Open（V1 建議自建簡化版） |
| 2 | Workflow 的執行歷史紀錄保留多久？ | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
