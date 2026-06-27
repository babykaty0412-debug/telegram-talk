---
doc_type: adr
doc_id: ADR-0004
title: Knowledge Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0006, ADR-0010]
tags: [knowledge, data, versioning]
---

# ADR-0004: Knowledge Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 需要管理大量結構化知識：二手商品定價規則、股票分析框架、AI 動態、法律常識等。這些知識有以下特性：
- 需要版本控制（規則會修改）
- 需要信心度管理（AI 提供的 vs 人工確認的）
- 需要跨 Domain 組織（股票知識不應混入二手商品知識）

---

## 決策（Decision）

**採用三層知識分類（Global → Domain → Topic），每個知識項目攜帶完整的元資料，所有修改必須透過審核管線（Approval Pipeline）。**

---

## 知識模型

### 知識項目結構

```
KnowledgeItem {
  id: string                    # 唯一識別碼（UUID）
  domain: string                # 所屬 Domain（stocks, secondhand, ai-news, legal）
  topic: string                 # 主題分類（pricing, rules, watchlist）
  content: string               # 知識內容（Markdown 或結構化 JSON）
  confidence: float             # 信心度 0.0–1.0
  source: string                # 來源（user-defined, ai-suggested, external-api）
  requires_approval: boolean    # 是否需要人工確認才生效
  status: draft | active | deprecated
  version: number               # 版本號，每次修改 +1
  created_at: datetime
  updated_at: datetime
  approved_by: string | null    # 人工確認者
  approved_at: datetime | null
}
```

### 三層分類結構

```
Global Knowledge（跨 Domain 共用）
├── Domain Knowledge（特定領域）
│   ├── stocks/
│   │   ├── pricing-rules/
│   │   ├── watchlist/
│   │   └── analysis-framework/
│   ├── secondhand/
│   │   ├── pricing-rules/
│   │   └── condition-criteria/
│   ├── ai-news/
│   └── legal/
```

---

## 審核管線（Approval Pipeline）

| 來源 | 需要審核？ | 生效時機 |
|---|---|---|
| User 直接建立 | ❌ | 立即 |
| AI 建議新增 | ✅ | 人工確認後 |
| AI 建議修改現有知識 | ✅ | 人工確認後 |
| External API 同步 | ✅（低信心度項目） | 超過閾值自動 / 低於閾值等待確認 |

---

## 後果（Consequences）

### 正面影響
- 知識品質可控，不會因 AI 錯誤而無聲汙染知識庫
- 版本歷史讓規則變更可追溯

### 負面影響（需接受的取捨）
- 知識新增的摩擦稍高（需要確認步驟）
- 需要實作一個輕量的審核 UI 或 CLI 介面

---

## 實施原則

1. `confidence >= 0.9` 且 `source = external-api` 的知識，可設定為自動生效
2. 所有 `requires_approval = true` 的知識必須在 Notification 中通知使用者
3. 廢棄的知識用 `status = deprecated` 標記，不直接刪除（保留可追溯性）
4. 知識庫的儲存格式優先選擇可 git diff 的格式（JSON Lines、Markdown）

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | 知識庫的儲存後端：本地檔案、SQLite、或 Notion？（見 OQ-03） | Open |
| 2 | 不同 Domain 的知識是否需要不同的 Schema？ | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
