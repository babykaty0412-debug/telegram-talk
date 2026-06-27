---
doc_type: adr
doc_id: ADR-0010
title: Domain Expansion Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0004, ADR-0005, ADR-0007]
tags: [domain, extensibility, plugin]
---

# ADR-0010: Domain Expansion Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 預計支援多個 Domain：股票、二手商品、AI 新聞、房地產、工作機會等。每個 Domain 都有自己的：
- 資料來源
- 知識規則
- 分析邏輯
- 通知條件

如果每次新增 Domain 都需要修改 Platform Core，系統很快就會變成難以維護的一坨義大利麵。

---

## 決策（Decision）

**每個 Domain 是一個獨立的模組（Domain Module），Platform Core 不包含任何 Domain-specific 邏輯。新增 Domain 只需新增一個模組，不需要修改 Core。**

---

## Domain Module 結構

每個 Domain 模組必須包含以下標準元素：

```
domains/
└── stocks/
    ├── domain.json              # Domain 宣告（元資料、能力宣告）
    ├── knowledge-schema.json    # 這個 Domain 的知識資料結構定義
    ├── data-sources.json        # 資料來源清單（RSS、API 等）
    ├── workflows/
    │   ├── daily-digest.yaml    # 每日摘要 Workflow
    │   └── price-alert.yaml    # 價格警示 Workflow
    ├── notification-rules.json  # 通知規則（什麼條件觸發哪個優先級）
    └── prompts/
        ├── analyze.md           # 分析用的 AI Prompt 模板
        └── summarize.md
```

---

## domain.json 標準格式

```json
{
  "id": "stocks",
  "name": "股票追蹤",
  "version": "1.0",
  "status": "active",
  "capabilities": ["data-collection", "ai-analysis", "notification", "knowledge"],
  "data_sources": ["taiwan-stock-api", "rss-finance-news"],
  "knowledge_schema": "knowledge-schema.json",
  "workflows": ["daily-digest", "price-alert"],
  "notification_rules": "notification-rules.json"
}
```

---

## Platform Core 的責任

Platform Core **不知道** 任何 Domain 的細節。它只做：

1. **Domain Registry**：掃描 `domains/` 目錄，載入所有 `domain.json`
2. **Workflow Execution**：執行 Domain 定義的 Workflow
3. **Knowledge Management**：依照 Domain Schema 儲存和檢索知識
4. **Notification Dispatch**：依照 Domain 的規則分配通知優先級

---

## 新增 Domain 的流程

1. 在 `domains/` 建立新目錄
2. 撰寫 `domain.json`（宣告 Domain 能力）
3. 定義 `knowledge-schema.json`
4. 設定資料來源（`data-sources.json`）
5. 撰寫 Workflow 定義（YAML）
6. 撰寫 AI Prompt 模板
7. 測試，完成

**不需要改動 Platform Core 任何程式碼。**

---

## 計畫中的 Domain 清單

| Domain | 優先級 | 說明 |
|---|---|---|
| `secondhand` | V1 | 二手商品追蹤（Shopee、FB） |
| `stocks` | V1 | 台股 / 美股追蹤 |
| `ai-news` | V1 | AI 產業動態 |
| `legal` | V2 | 法律常識知識庫 |
| `real-estate` | V2 | 房地產資訊 |
| `jobs` | V3 | 工作機會追蹤 |

---

## 後果（Consequences）

### 正面影響
- 新增 Domain 完全獨立，不影響其他 Domain 和 Core
- Domain 可以單獨版本控制、單獨停用
- 未來甚至可以讓使用者自行安裝第三方 Domain

### 負面影響（需接受的取捨）
- Domain Module 的格式需要嚴格定義，任何格式錯誤都可能導致載入失敗
- Platform Core 的 Domain Registry 需要完善的錯誤處理

---

## 實施原則

1. Platform Core 只透過 `domain.json` 的宣告了解 Domain，不直接 import Domain 的程式碼
2. Domain 的 Prompt 模板以 Markdown 儲存，不寫死在程式碼中
3. 每個 Domain 的 Workflow 必須是自描述的（看 YAML 就能理解流程），不需要查 code
4. Domain 停用時，只需將 `domain.json` 中的 `status` 改為 `disabled`

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | Domain 之間是否允許知識共享？（例如 stocks Domain 引用 ai-news Domain 的資料） | Open |
| 2 | Domain Module 是否需要支援自訂 Step（Workflow Step 的 Domain 擴充）？ | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
