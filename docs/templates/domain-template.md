---
doc_type: template
doc_id: TMPL-001
title: Domain Design Template
status: accepted
version: "1.0"
date: 2026-06-27
related: [GLOSS-001, ADR-0010, ARCH-001]
tags: [template, domain, design]
---

# Domain Design Template

> **使用說明**：複製此文件至 `docs/architecture/domains/{domain-name}.md`，  
> 將所有 `{佔位符}` 替換為實際內容，刪除所有 `>` 引用說明文字。  
> 每個 Domain 文件都必須完整填寫所有 Section。

---

## 狀態

`Draft`

生命週期：`draft` → `review` → `accepted` → `superseded` / `deprecated`

---

## 1. Purpose（目的）

> 這個 Domain 存在的理由。用一句話說清楚它解決了什麼問題。  
> 必須回答：使用者為什麼需要這個 Domain？沒有它會怎樣？

**核心目的**：  
{一句話：這個 Domain 是什麼、解決什麼問題}

**使用者價值**：  
{使用者從這個 Domain 獲得什麼價值}

**為什麼不是現有 Domain 的一部分**：  
{說明它為什麼是一個獨立的 Domain，而不應該合併進其他 Domain}

---

## 2. Scope（範圍）

> 明確定義邊界。In Scope = 這個 Domain 負責的事；Out of Scope = 明確不負責。  
> 邊界模糊是 Domain 腐化的根源。

### In Scope（本 Domain 負責）

- {責任 1}
- {責任 2}

### Out of Scope（明確不負責）

- {不負責的事 1}（由哪個 Domain / Service 負責）
- {不負責的事 2}

### 版本邊界

| 功能 | V1 | V2 | V3 |
|---|---|---|---|
| {功能 1} | ✅ 包含 | — | — |
| {功能 2} | ❌ 暫不包含 | ✅ 計劃 | — |
| {功能 3} | ❌ | ❌ | ✅ 考慮 |

---

## 3. Core Concepts（核心概念）

> 這個 Domain 特有的術語，**不在全域 Glossary 中**。  
> 每個概念用一句話定義清楚。如果概念應該加進全域 Glossary，先更新 Glossary，再引用。

| 概念 | 定義 | 說明 |
|---|---|---|
| {Concept1} | {一句話定義} | {補充說明} |
| {Concept2} | {一句話定義} | {補充說明} |

---

## 4. Business Rules（業務規則）

> 決定系統行為的規則。這些規則應該可以被 Validator 執行、被 Analyzer 理解、被 Notification Rules 引用。  
> 業務規則是 Domain 的「法律」——違反就是錯誤，不是例外。

### 資料有效性規則

| 規則 ID | 規則描述 | 錯誤處理 |
|---|---|---|
| BR-{XXX}-01 | {規則描述} | {fail / warn / ignore} |
| BR-{XXX}-02 | {規則描述} | {fail / warn / ignore} |

### 業務邏輯規則

| 規則 ID | 規則描述 | 觸發條件 |
|---|---|---|
| BR-{XXX}-10 | {規則描述} | {何時適用} |

### 限制規則

| 規則 ID | 規則描述 | 原因 |
|---|---|---|
| BR-{XXX}-20 | {規則描述} | {設計原因} |

---

## 5. Data Sources（資料來源）

> 所有外部資料來源必須在此列出。沒有列出的來源不允許在 Collector 中使用。  
> 填寫認證方式、頻率限制、穩定性評估。

| 來源名稱 | 類型 | 認證方式 | 建議頻率 | 穩定性 | 說明 |
|---|---|---|---|---|---|
| {Source1} | API / Scraping / RSS / File | None / API Key / OAuth | {頻率} | High / Medium / Low | {說明} |
| {Source2} | | | | | |

### 頻率設定原則

- 高穩定性 API：最高每 {N} 分鐘一次
- 爬蟲類型來源：最少間隔 {N} 分鐘，避免封鎖
- RSS 類型：每 {N} 分鐘一次

---

## 6. Data Model（資料模型）

> 所有持久化資料的結構。使用 TypeScript Interface 格式定義。  
> 每個 Entity 都必須有：id（UUID）、created_at、updated_at。  
> 外鍵使用 `{entity}_id` 命名。

### 主要 Entity

```typescript
// {EntityName}
interface {EntityName} {
  id: string                    // UUID
  // --- 核心欄位 ---
  {field1}: {type}              // {說明}
  {field2}: {type}              // {說明}
  // --- 狀態欄位 ---
  status: '{status1}' | '{status2}'
  // --- 時間欄位 ---
  created_at: string            // ISO 8601
  updated_at: string
}
```

### 次要 Entity（如有）

```typescript
interface {SecondaryEntity} {
  id: string
  {primary_entity_id}: string  // FK to {EntityName}
  // ...
}
```

### SQLite Table 設計

```sql
CREATE TABLE {table_name} (
  id TEXT PRIMARY KEY,
  {field1} {SQL_TYPE} NOT NULL,
  {field2} {SQL_TYPE},
  status TEXT CHECK(status IN ('{s1}', '{s2}')) NOT NULL DEFAULT '{s1}',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_{table}_{field} ON {table_name}({field});
```

---

## 7. Collectors（資料收集器）

> 每個 Collector 都是一種 Worker，負責從一個資料來源取得原始資料。  
> Collector 不做任何解析或分析，只負責「拿到資料並快取」。  
> 命名規則：`{Domain}{Source}Collector`

| Collector 名稱 | 對應資料來源 | 觸發方式 | 輸出格式 | 逾時設定 | 重試次數 |
|---|---|---|---|---|---|
| `{Name}Collector` | {Source} | Scheduled / Event | Raw JSON / HTML / CSV | {N}s | {N} |

### `{Name}Collector` 詳細規格

**輸入**：`{ query: string, limit?: number, offset?: number }`  
**輸出**：`{ raw: string, source: string, fetched_at: string, metadata: object }`  
**快取**：原始資料存入 SQLite `external_cache` 表，TTL {N} 小時  
**錯誤處理**：
- HTTP 429（Rate limit）→ 指數退避，最多重試 {N} 次
- HTTP 5xx → 記錄錯誤，標記 Task 為 `failed`，不重試
- 逾時 → 標記 Task 為 `failed`

---

## 8. Parsers（資料解析器）

> Parser 將 Collector 的原始資料轉換成符合 Data Model 的結構化格式。  
> Parser 不使用 AI，只做確定性的格式轉換。  
> 命名規則：`{Domain}{Source}Parser`

| Parser 名稱 | 輸入來源 | 輸出 Entity | 關鍵欄位提取邏輯 |
|---|---|---|---|
| `{Name}Parser` | `{Collector}` 輸出 | `{Entity}[]` | {說明} |

### `{Name}Parser` 詳細規格

**輸入**：`{ raw: string, source: string, fetched_at: string }`  
**輸出**：`{Entity}[]`（符合 Section 6 Data Model）  
**無效資料處理**：欄位缺失 → `null`（非必填）或丟棄整筆（必填欄位缺失）  
**已知格式問題**：{列出已知的格式特殊情況}

---

## 9. Analyzers（AI 分析器）

> Analyzer 是 AI 介入的地方。輸入是已解析的結構化資料，輸出是洞察、評分或分類。  
> 每個 Analyzer 都必須指定：使用的 AI 模型偏好、Prompt 策略、輸出 Schema。  
> 命名規則：`{Domain}{Function}Analyzer`

| Analyzer 名稱 | 輸入 | 輸出 | AI 模型偏好 | Prompt 策略 |
|---|---|---|---|---|
| `{Name}Analyzer` | `{Entity}` | `{AnalysisResult}` | {claude-haiku / claude-sonnet} | {zero-shot / few-shot / CoT} |

### `{Name}Analyzer` 詳細規格

**目的**：{這個 Analyzer 做什麼判斷}  
**輸入 Schema**：
```typescript
interface {Name}AnalyzerInput {
  {fields}
}
```
**輸出 Schema**：
```typescript
interface {Name}AnalysisResult {
  score: number             // 0.0 – 1.0
  verdict: '{positive}' | '{negative}' | 'uncertain'
  reason: string            // AI 的推理說明
  confidence: number        // 0.0 – 1.0
  flags: string[]           // 值得注意的警告
}
```
**Prompt 策略**：{few-shot / chain-of-thought / structured output}  
**Knowledge 依賴**：{需要哪些 Knowledge 項目才能分析}  
**最低 Confidence 門檻**：{0.7}（低於此值觸發 L2 驗證）

---

## 10. Validators（驗證器）

> 對應 ADR-0008 的三層驗證：L1 自動、L2 交叉驗證、L3 人工確認。  
> 每個 Validator 都必須說明：驗證什麼、如何驗證、失敗時做什麼。

### L1 自動驗證

| 驗證項目 | 規則 | 失敗處理 |
|---|---|---|
| Schema 完整性 | 所有必填欄位存在 | 丟棄資料 |
| {Domain 特定驗證} | {規則} | {處理} |
| Confidence 篩選 | Analyzer confidence < 0.7 | 升級至 L2 |

### L2 交叉驗證

| 驗證項目 | 方法 | 觸發條件 |
|---|---|---|
| {驗證項目} | {Multi-provider / Rule cross-check / 多次 AI 呼叫} | {何時觸發 L2} |

### L3 人工確認

| 驗證項目 | 通知內容 | 使用者操作 |
|---|---|---|
| {高風險操作} | {通知說明} | 確認 / 拒絕 |

---

## 11. Notification Rules（通知規則）

> 對應 ADR-0007 的四級通知模型（P0–P3）。  
> 每條規則說明：什麼條件觸發、優先級、管道、Cooldown（防止重複通知）。

| 規則 ID | 觸發條件 | 優先級 | 管道 | Cooldown | 格式說明 |
|---|---|---|---|---|---|
| NR-{XXX}-01 | {條件} | P0 / P1 / P2 / P3 | Telegram / Dashboard | {N}小時 | {訊息格式說明} |

### 通知訊息格式

**P1 通知範例**：
```
🔔 {標題}
{主要資訊行}
{次要資訊行}
👉 {連結或操作提示}
```

**P2 批次通知範例**：
```
📊 {摘要標題}（{日期}）
{條目 1}
{條目 2}
...
共 {N} 項，詳見 Dashboard
```

---

## 12. Workflows（工作流程）

> 每個 Workflow 定義一個完整的業務流程。  
> 填寫：觸發方式、步驟序列、每步的 Worker 類型、錯誤處理。  
> Workflow YAML 文件路徑：`domains/{domain}/workflows/{workflow-name}.yaml`

| Workflow 名稱 | 觸發方式 | 排程 | 預估執行時間 |
|---|---|---|---|
| `{name}` | Scheduled / Event / Manual | `{cron}` / — | {N}秒/分鐘 |

### Workflow：`{workflow-name}`

**觸發**：{Trigger 說明}  
**目的**：{這個 Workflow 完成什麼業務目標}

```
Step 1: {CollectorName}      [Collector Worker]
  → 輸出：{output}
  → 錯誤處理：{error policy}

Step 2: {ParserName}         [Parser Worker]
  → 輸入：Step 1 輸出
  → 輸出：{output}

Step 3: {AnalyzerName}       [Analyzer Worker]
  → 輸入：Step 2 輸出
  → 輸出：{output}
  → 若 confidence < 0.7 → 觸發 L2 驗證

Step 4: {ValidatorName}      [Validator]
  → 輸入：Step 3 輸出
  → 輸出：validated results

Step 5: Notification         [Notification Dispatcher]
  → 依 Notification Rules 發送
```

---

## 13. Knowledge（知識庫）

> 這個 Domain 管理的領域知識。對應 ADR-0004。  
> 知識項目是「相對穩定的、需要版本控制的事實」，不是暫時性的資料。  
> 每個知識項目說明：由誰維護、審核流程、預期更新頻率。

### 知識項目清單

| 知識項目 | 類型 | 初始來源 | 更新方式 | 審核要求 |
|---|---|---|---|---|
| {KnowledgeItem1} | Rule / Fact / Reference | 人工輸入 / AI 建議 / API | {更新方式} | L1 自動 / L3 人工 |

### 知識 Schema

```typescript
// Domain-specific Knowledge Item
interface {Domain}KnowledgeItem {
  id: string
  domain: '{domain}'
  topic: '{topic}'         // 知識的主題分類
  content: {ContentType}  // 具體的知識內容
  confidence: number      // 0.0 – 1.0
  source: string
  requires_approval: boolean
  status: 'active' | 'pending_review' | 'deprecated'
  version: number
  created_at: string
  updated_at: string
  approved_by?: string
}
```

---

## 14. Test Cases（測試案例）

> 驗證 Domain 正確性的測試場景。每個重要的 Business Rule 都應有測試案例。

### Unit Test Cases

| 測試案例 | 測試對象 | 輸入 | 預期輸出 | 覆蓋規則 |
|---|---|---|---|---|
| `TC-{XXX}-U01` | `{Component}` | {輸入說明} | {預期} | BR-{XXX}-01 |

### Integration Test Cases

| 測試案例 | 測試流程 | 前置條件 | 驗證點 |
|---|---|---|---|
| `TC-{XXX}-I01` | `{Workflow}` 完整執行 | {前置條件} | {驗證點} |

### Edge Cases（邊界情況）

| 情況描述 | 預期行為 |
|---|---|
| {邊界情況 1} | {應該發生什麼} |
| {資料來源不可用} | Collector 標記 Task 為 failed，Core 繼續運行 |
| {AI API 超時} | Analyzer 標記 Task 為 failed，不阻塞其他 Task |

---

## 15. Sample Data（範例資料）

> 真實或接近真實的資料範例，用於開發和測試。  
> 包含：原始資料（Collector 輸出）、解析後資料（Parser 輸出）、分析後資料（Analyzer 輸出）。

### 原始資料範例（Collector 輸出）

```json
{
  "raw": "{原始資料的範例片段，可以是 JSON/HTML 字串}",
  "source": "{source_name}",
  "fetched_at": "2026-06-27T10:00:00Z"
}
```

### 解析後資料範例（Parser 輸出）

```json
{
  "{field1}": "{value}",
  "{field2}": "{value}",
  "created_at": "2026-06-27T10:00:00Z"
}
```

### 分析後資料範例（Analyzer 輸出）

```json
{
  "score": 0.85,
  "verdict": "{verdict}",
  "reason": "{AI 的推理說明範例}",
  "confidence": 0.92,
  "flags": []
}
```

---

## 16. Future Extensions（未來擴充）

> 目前不做但未來可能需要的功能。記錄在這裡，避免過早設計，也避免遺忘。

### V2 計劃

- {V2 功能 1}：{說明}
- {V2 功能 2}：{說明}

### V3 考慮

- {V3 功能}：{說明}

### 已知限制

| 限制 | 原因 | 可能的解決方案 |
|---|---|---|
| {限制 1} | {設計原因} | {未來方向} |

### 不在計劃中

> 明確說明哪些事情這個 Domain 永遠不會負責，防止 Scope Creep。

- {永遠不做的事}：{原因}

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 0.1 | {YYYY-MM-DD} | 初稿 |
