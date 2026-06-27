---
doc_type: system
doc_id: SYS-001
title: PAOS Documentation System
status: accepted
version: "1.0"
date: 2026-06-27
audience: [self, ai, engineer, automation]
---

# PAOS Documentation System

> 本文件定義所有 PAOS 文件的格式標準、目錄規範與演進原則。  
> **本文件本身是第一個符合規範的文件。**

---

## 一、設計原則

PAOS 的文件系統有四個讀者，設計必須同時滿足所有人：

| 讀者 | 需求 |
|---|---|
| 我自己（半年後） | 能快速理解「當初為什麼這樣決定」 |
| 未來的 AI | 結構一致、格式可解析、脈絡完整 |
| 未來的工程師 | 知道從哪裡開始、如何找到負責的文件 |
| 自動化工具 | Front matter 可機器讀取，連結可追蹤 |

**核心設計原則**：

1. **Single Source of Truth**：每個概念只在一個地方定義，其他地方引用它
2. **Progressive Disclosure**：摘要在前，細節在後；不需要讀完才能理解重點
3. **Living Documents**：文件隨系統演進，每次更新附上 changelog
4. **AI-Readable Structure**：標題層次明確，前置元資料完整，定義清晰
5. **Decision Traceability**：每個重要決定都有對應的 ADR，可追溯為什麼

---

## 二、目錄結構

```
docs/
├── index.md                    ← 總索引（所有文件的入口）
│
├── system/                     ← 文件系統本身的規範
│   ├── documentation-system.md ← 本文件
│   └── glossary.md             ← 全局術語表
│
├── decisions/                  ← Architecture Decision Records (ADR)
│   ├── ADR-template.md         ← ADR 模板
│   ├── ADR-0001-*.md
│   └── ADR-000N-*.md
│
├── architecture/               ← 系統架構文件
│   ├── platform-blueprint.md   ← 平台藍圖（高層次）
│   ├── component-map.md        ← 元件地圖
│   └── [domain]-architecture.md
│
├── guides/                     ← 操作指南（How-to）
│   ├── setup.md
│   ├── add-new-domain.md
│   └── add-new-channel.md
│
└── vision-scope.md             ← 願景與範圍（整個平台的北極星）
```

---

## 三、Front Matter 規範

每份文件的第一個區塊必須是 YAML front matter，格式如下：

### 必填欄位

```yaml
---
doc_type: vision | system | adr | architecture | guide
doc_id: 唯一識別碼（如 ADR-0001、SYS-001、ARCH-001）
title: 文件標題
status: draft | proposed | accepted | deprecated | superseded
version: "1.0"
date: YYYY-MM-DD（最後更新日）
---
```

### 選填欄位

```yaml
---
# 以下依文件類型選用
supersedes: [ADR-0002]          # 本文件取代哪份文件
related: [ADR-0003, ADR-0005]   # 相關文件
audience: [self, ai, engineer, automation]
tags: [memory, knowledge, strategy]
authors: [user, claude-sonnet-4-6]
---
```

### doc_type 說明

| 類型 | 說明 | 位置 |
|---|---|---|
| `vision` | 願景與範圍文件 | `docs/` 根目錄 |
| `system` | 文件系統規範、術語表 | `docs/system/` |
| `adr` | Architecture Decision Record | `docs/decisions/` |
| `architecture` | 架構說明文件 | `docs/architecture/` |
| `guide` | 操作指南 | `docs/guides/` |

---

## 四、ADR 格式規範

ADR（Architecture Decision Record）是記錄重要技術決策的標準格式。

### 命名規則

```
ADR-{4位數序號}-{kebab-case-標題}.md
例：ADR-0001-repo-strategy.md
    ADR-0010-domain-expansion.md
```

### 標準結構

```markdown
---
(front matter)
---

# ADR-XXXX: 標題

## 狀態
[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

## 背景（Context）
[為什麼需要做這個決定？當前的問題或需求是什麼？]

## 考慮的選項

### 選項 A：...
**優點**：...  
**缺點**：...

### 選項 B：...

## 決策（Decision）
[選擇了什麼，用一句話說清楚]

## 決策依據（Rationale）
[為什麼選這個？針對 PAOS 的具體原因]

## 後果（Consequences）
### 正面影響
### 負面影響 / 需接受的取捨
### 風險

## 實施原則
[這個決策如何影響日後的實作？任何人接手都必須知道的事]

## 開放問題
[尚未解決、需要未來決定的子問題]
```

---

## 五、版本控制規則

### 文件版本號

文件版本號獨立於 git commit 之外，遵循：

```
major.minor
1.0 → 首次 Accepted
1.1 → 非破壞性修改（澄清、補充）
2.0 → 重大修改（改變了決策方向）
```

### Changelog 慣例

每次修改在文件最底部附上 changelog：

```markdown
---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
| 1.1 | 2026-07-XX | 補充 AI-readable 格式規範 |
```

---

## 六、AI 讀取指南

當 AI（Claude、GPT、Gemini 等）接手這個系統時，建議的閱讀順序：

```
1. docs/index.md              ← 總覽，了解整個文件地圖
2. docs/vision-scope.md       ← 理解為什麼這個系統存在
3. docs/system/glossary.md    ← 統一術語定義
4. docs/architecture/platform-blueprint.md  ← 理解系統結構
5. docs/decisions/ADR-000*.md ← 理解所有重要決策的來龍去脈
6. 對應的 guide 或 architecture 文件（視任務而定）
```

**AI 接手原則**：
- 不要猜測任何沒有文件記錄的設計意圖
- 遇到不確定的決策，查詢對應的 ADR
- 所有新的架構決策都必須產出 ADR，不能只寫在 code comment

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，建立 PAOS 文件系統規範 |
