---
doc_type: system
doc_id: SYS-001
title: PAOS Documentation System
status: accepted
version: "1.4"
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
├── glossary.md                 ← 架構術語表（第一優先讀，GLOSS-001）
├── concept-map.md              ← 概念關係圖（ARCH-002）
├── naming-convention.md        ← 命名規範（SYS-002）
├── architecture-principles.md  ← 架構原則（ARCH-003）
├── decision-log.md             ← 決策變更記錄（SYS-003）
├── vision-scope.md             ← 願景與範圍（整個平台的北極星）
│
├── system/                     ← 文件系統本身的規範
│   └── documentation-system.md ← 本文件（文件格式標準、ADR Lifecycle）
│
├── decisions/                  ← Architecture Decision Records (ADR)
│   ├── ADR-template.md         ← ADR 模板
│   ├── ADR-0001-*.md
│   └── ADR-000N-*.md
│
├── templates/                  ← 文件與設計模板
│   └── domain-template.md      ← Domain 設計模板（TMPL-001，所有 Domain 必用）
│
├── architecture/               ← 系統架構文件
│   ├── platform-blueprint.md   ← 平台藍圖（高層次）
│   ├── component-map.md        ← 元件地圖
│   └── domains/                ← 各 Domain 設計文件
│       └── marketplace.md      ← Marketplace Domain（DOMAIN-001）
│
├── governance/                 ← Domain 治理框架
│   ├── domain-validation-checklist.md  ← 驗證清單（GOVR-001）
│   ├── domain-review-process.md        ← 審查流程（GOVR-002）
│   ├── domain-maturity-model.md        ← 成熟度模型（GOVR-003）
│   └── reviews/                        ← 各 Domain 的審查記錄
│       └── {domain}-v{ver}-level{n}-review.md
│
└── guides/                     ← 操作指南（How-to）
    ├── setup.md
    ├── add-new-domain.md
    └── add-new-channel.md
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
status: draft | review | accepted | superseded | deprecated
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
| `glossary` | 架構術語表（Ubiquitous Language） | `docs/` 根目錄 |
| `vision` | 願景與範圍文件 | `docs/` 根目錄 |
| `system` | 文件系統規範 | `docs/system/` |
| `adr` | Architecture Decision Record | `docs/decisions/` |
| `template` | 設計模板（填入式，不直接使用） | `docs/templates/` |
| `domain` | Domain 設計文件（從 domain-template 產出） | `docs/architecture/domains/` |
| `governance` | Domain 治理文件（驗證清單、審查流程、成熟度模型）| `docs/governance/` |
| `architecture` | 架構說明文件 | `docs/architecture/` |
| `guide` | 操作指南 | `docs/guides/` |

### doc_id 命名慣例

| 前綴 | 說明 | 範例 |
|---|---|---|
| `GLOSS-` | Glossary（術語表） | `GLOSS-001` |
| `SYS-` | 文件系統規範 | `SYS-001` |
| `ARCH-` | 架構文件 | `ARCH-001` |
| `ADR-` | Architecture Decision Record | `ADR-0001` |
| `TMPL-` | 設計模板 | `TMPL-001` |
| `DOMAIN-` | Domain 設計文件 | `DOMAIN-001` |
| `GOVR-` | 治理文件 | `GOVR-001` |
| `GUIDE-` | 操作指南 | `GUIDE-001` |

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

`Accepted`（自 YYYY-MM-DD）

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

## 五、ADR 生命週期（Lifecycle）

每份 ADR 在其生命週期中有五個狀態。狀態必須在 front matter 的 `status` 欄位與文件內的「狀態」段落同步更新。

### 狀態定義

| 狀態 | 說明 | 可轉換至 |
|---|---|---|
| `draft` | 草案：正在起草，尚未準備好討論 | `review` |
| `review` | 審閱中：開放討論，可能仍有變動 | `accepted`、`deprecated` |
| `accepted` | 已採用：正式決策，所有實作必須遵循 | `superseded`、`deprecated` |
| `superseded` | 已取代：被更新的 ADR 取代，連結至新 ADR | — |
| `deprecated` | 已廢棄：不再建議使用，但未被明確取代 | — |

### 狀態轉換圖

```
draft ──→ review ──→ accepted ──→ superseded
                  ↘               ↘
                   deprecated      deprecated
```

### 在文件中標記狀態

```markdown
## 狀態

`Accepted`（自 2026-06-27）
```

若 ADR 被取代，需加上：

```markdown
## 狀態

`Superseded`（自 2026-09-01）  
→ 被 [ADR-0005](./ADR-0005-xxx.md) 取代
```

### 重要規則

1. 狀態變更必須同時更新：front matter `status` + 文件內「狀態」段落 + Changelog
2. `superseded` 狀態的 front matter 必須在 `supersedes` 欄位列出取代它的新 ADR ID
3. `accepted` 的 ADR 在被取代前不可刪除——只能標記為 `superseded`
4. **ADR 永遠保留在 `decisions/` 目錄，不因狀態而刪除**（歷史必須可追溯）
5. 新的 ADR 取代舊的 ADR 時，舊 ADR 的文件內容不需要修改，只更新狀態與指向新 ADR 的連結

---

## 六、版本控制規則

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

## 七、AI 讀取指南

當 AI（Claude、GPT、Gemini 等）接手這個系統時，建議的閱讀順序：

```
1. docs/index.md              ← 總覽，了解整個文件地圖
2. docs/glossary.md           ← 統一術語定義（先建立共同語言）
3. docs/vision-scope.md       ← 理解為什麼這個系統存在
4. docs/architecture/platform-blueprint.md  ← 理解系統結構
5. docs/decisions/ADR-000*.md ← 理解所有重要決策的來龍去脈
6. 對應的 guide 或 architecture 文件（視任務而定）
```

**AI 接手原則**：
- 不要猜測任何沒有文件記錄的設計意圖
- 遇到不確定的決策，查詢對應的 ADR
- 所有新的架構決策都必須產出 ADR，不能只寫在 code comment
- 當 ADR 狀態為 `superseded` 時，閱讀取代它的新 ADR，不依舊版本行動

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，建立 PAOS 文件系統規範 |
| 1.1 | 2026-06-27 | 新增第五節 ADR Lifecycle；status 值從 `proposed` 改為 `review`；舊五、六節改為六、七節 |
| 1.2 | 2026-06-27 | 新增 `glossary` doc_type；新增 doc_id 命名慣例表；glossary 移至 docs/ 根目錄；目錄結構與 AI 讀取順序更新為 Glossary 第一 |
| 1.3 | 2026-06-27 | 新增 `template` 和 `domain` doc_type；新增 TMPL- 和 DOMAIN- doc_id 前綴；目錄結構加入 templates/ 和 architecture/domains/ |
| 1.4 | 2026-06-27 | 新增 `governance` doc_type；新增 GOVR- doc_id 前綴；目錄結構加入 governance/ 和 reviews/ 子目錄 |
