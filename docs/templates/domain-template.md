---
doc_type: template
doc_id: TMPL-001
title: Domain Design Template
status: accepted
version: "1.1"
date: 2026-06-29
stability: experimental
related: [GLOSS-001, ADR-0008, ADR-0009, ADR-0010, ARCH-001, ARCH-003, GOVR-006, GOVR-007, GOVR-008]
tags: [template, domain, design]
---

# Domain Design Template

> **使用說明**：複製此文件至 `docs/architecture/domains/{domain-name}.md`，  
> 將所有 `{佔位符}` 替換為實際內容，刪除所有 `>` 引用說明文字。  
> 每個 Domain 文件都必須完整填寫所有 Section。

> ⚠️ **v1.1 穩定度：Experimental**  
> 本版本的新增區塊（§7、§8、§11、§14、§16）來自 Marketplace 的實戰驗證（REV-MKT-001），  
> 但尚未被第二個 Domain 驗證。依 GOVR-008 的 Template 演進政策，需待第二個 Domain（預計 Stocks）  
> 也證明這些區塊有價值後，才能升級為 **Stable**。在此之前，這些區塊允許依新 Domain 的回饋調整。

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
CREATE TABLE {domain}_{table_name} (
  id TEXT PRIMARY KEY,
  {field1} {SQL_TYPE} NOT NULL,
  {field2} {SQL_TYPE},
  status TEXT CHECK(status IN ('{s1}', '{s2}')) NOT NULL DEFAULT '{s1}',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_{table}_{field} ON {domain}_{table_name}({field});
```

> Table 名稱必須以 `{domain}_` 前綴開頭（COMPAT-02）。

---

## 7. Repository Interfaces（資料存取介面）

> **v1.1 新增**（來源：Marketplace REV-MKT-001 ARCH-03）。  
> 對應 P-05（Repository Abstraction）：業務邏輯永不直接寫 SQL，所有資料存取透過 Repository 介面。  
> 為 Section 6 的每個主要 Entity 定義一個 Repository（方法簽名層級即可，不需實作）。  
> 命名規則：`{Entity}Repository`

| Repository | 負責 Entity | 關鍵方法 |
|---|---|---|
| `{Entity}Repository` | `{Entity}` | `findById` / `save` / `findBy{Condition}` / `updateStatus` |

### `{Entity}Repository` 方法簽名

```typescript
interface {Entity}Repository {
  findById(id: string): Promise<{Entity} | null>
  save(entity: {Entity}): Promise<void>
  findBy{Condition}(criteria: {CriteriaType}): Promise<{Entity}[]>
  updateStatus(id: string, status: string): Promise<void>
}
```

> **規則**：
> - Repository 只負責資料存取，不含業務邏輯（業務邏輯在 Core / Analyzer）。
> - Repository 一律不得跨 Domain 查詢（P-03）。跨 Domain 需求走 Knowledge Service 或 Event Bus。
> - 切換資料庫後端（SQLite → PostgreSQL）只需替換 Repository 實作，介面不變。

---

## 8. Entity Status Lifecycle（實體狀態生命週期）

> **v1.1 新增**（來源：Marketplace REV-MKT-001 §3.4）。  
> 用狀態機描述每個帶 `status` 欄位的主要 Entity 的生命週期：合法狀態、合法轉換、觸發條件。  
> 防止「狀態被任意改寫」造成的不一致。

### {EntityName} 狀態轉換

```
{initial} ──{trigger}──▶ {active}
{active}  ──{trigger}──▶ {terminal_1}
{active}  ──{trigger}──▶ {terminal_2}
```

| 從 | 到 | 觸發條件 / Event | 發出的 Event |
|---|---|---|---|
| {s_initial} | {s_active} | {條件} | `{domain}.{entity}_{verb}` |
| {s_active} | {s_terminal} | {條件} | `{domain}.{entity}_{verb}` |

> **規則**：
> - 終態（terminal status）不可再轉回非終態。
> - 每一次狀態變更都必須寫入 Audit Log（見 Section 14）。
> - 每一次狀態變更若需要通知其他模組，必須透過 Event（在 Section 16 登記）。

---

## 9. Collectors（資料收集器）

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

## 10. Parsers（資料解析器）

> Parser 將 Collector 的原始資料轉換成符合 Data Model 的結構化格式。  
> Parser 不使用 AI，只做確定性的格式轉換。  
> 標準化映射（如狀況、幣別、分類）一律從 Normalization Rules（Section 11）載入，不在 Parser 中硬編碼。  
> 命名規則：`{Domain}{Source}Parser`

| Parser 名稱 | 輸入來源 | 輸出 Entity | 關鍵欄位提取邏輯 |
|---|---|---|---|
| `{Name}Parser` | `{Collector}` 輸出 | `{Entity}[]` | {說明} |

### `{Name}Parser` 詳細規格

**輸入**：`{ raw: string, source: string, fetched_at: string }`  
**輸出**：`{Entity}[]`（符合 Section 6 Data Model）  
**無效資料處理**：欄位缺失 → `null`（非必填）或丟棄整筆（必填欄位缺失）  
**標準化依賴**：使用 Section 11 定義的哪些 Normalization Rules  
**已知格式問題**：{列出已知的格式特殊情況}

---

## 11. Normalization Rules（標準化規則）

> **v1.1 新增**（來源：Marketplace REV-MKT-001 EXT-02，ConditionNorm 雙重定義問題）。  
> Domain 特有的「原始值 → 標準值」映射（如 ConditionNorm、CurrencyNorm、CategoryNorm）。  
>
> **關鍵決策**：這些映射是 **Knowledge 驅動**（可熱更新）還是 **Parser 內建**（需版本升級）？  
> **PAOS 預設原則**：凡是「會隨外部平台格式變動的映射」一律放 Knowledge 層，Parser 從 Knowledge 載入，  
> **不得硬編碼**。只有確實永久穩定的映射（如語言代碼）才可內建於 Parser，並在此註明原因。

| 映射規則 | 來源值範例 | 標準值 | 儲存位置 | 更新方式 |
|---|---|---|---|---|
| {NormName} | {原始文字} | {標準列舉} | Knowledge `{domain}/norm/{name}` | 使用者指令 / 版本更新 |

### {NormName} 映射內容

```
{原始值 A} → {標準值}
{原始值 B} → {標準值}
無法映射  → {unknown / 預設值}
```

> **規則**：同一個 Normalization Rule 只能有一個權威位置（Knowledge 或 Parser），不可兩處並存。

---

## 12. Analyzers（AI 分析器）

> Analyzer 是 AI 介入的地方。輸入是已解析的結構化資料，輸出是洞察、評分或分類。  
> 每個 Analyzer 都必須指定：使用的 AI 模型偏好、Prompt 策略、輸出 Schema。  
> 命名規則：`{Domain}{Function}Analyzer`（以 Domain 名稱為前綴，不以實體名稱為前綴）。

> ⚠️ **架構約束（P-07）**：Analyzer 的所有 AI 呼叫必須透過 `AIProvider` 介面，  
> **不得直接 import Anthropic / OpenAI SDK**。`packages/ai-provider/` 是唯一允許 import AI SDK 的地方。

| Analyzer 名稱 | 輸入 | 輸出 | AI 模型偏好 | Prompt 策略 |
|---|---|---|---|---|
| `{Domain}{Function}Analyzer` | `{Entity}` | `{AnalysisResult}` | {claude-haiku / claude-sonnet} | {zero-shot / few-shot / CoT} |

### `{Domain}{Function}Analyzer` 詳細規格

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

## 13. Validators（驗證器）

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

## 14. Auditable Operations（可審計操作）

> **v1.1 新增**（來源：Marketplace REV-MKT-001 ARCH-06）。  
> 對應 P-09（Audit Everything）與 ADR-0009。
>
> **重要分工**：Audit Log 的「記錄格式、儲存機制、append-only 保證」由 **Core 統一提供**，  
> Domain **不自訂 Audit 格式**。Domain 在此只負責「**宣告哪些有副作用的操作需要寫入 Audit Log**」，  
> 並提供領域特定的 metadata 欄位。

| 操作 | 類型 | 必須審計？ | metadata 關鍵欄位 |
|---|---|---|---|
| {外部 API 呼叫} | `external_call` | ✅ | endpoint, status_code, rate_limited |
| {通知發送} | `notification` | ✅ | rule_id, priority, channel, recipient_ref |
| {Knowledge 寫入} | `knowledge_write` | ✅ | knowledge_key, old→new, approved_by |
| {Entity 狀態變更} | `status_change` | ✅ | entity_id, from, to, trigger |

> **Core 提供的標準 Audit 欄位（所有 Domain 共用，由 Core 自動填入）**：  
> `operation_type, domain, entity_id, action, actor, timestamp, result, metadata`  
> Domain 只需填 `metadata` 內的領域特定欄位。
>
> **絕對禁止（P-09）**：AI 不能自動刪除資料、自動購買、自動在社群媒體發文。

---

## 15. Notification Rules（通知規則）

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

## 16. Event Catalogue（事件目錄）

> **v1.1 新增**（來源：Marketplace REV-MKT-001 NAME-04）。  
> 列出本 Domain 發出的所有 Event。對應 COMPAT-01（Event namespace 前綴）與命名規範（SYS-002）。  
> 每個 Workflow 步驟之間、每個狀態變更，若透過 Event 通訊，都必須在此登記名稱。  
> 防止實作者各自發明 Event 名稱。

| Event 名稱 | 觸發時機 | Payload 關鍵欄位 | 訂閱者 |
|---|---|---|---|
| `{domain}.{subject}_{past_verb}` | {何時發出} | {欄位} | {誰關心} |

> **命名規則（SYS-002）**：`{namespace}.{subject}_{past_tense_verb}`，動詞必須用過去式。  
> 所有 Event 名稱最終定義為常數，存放於 `packages/core/events.ts`（ADR-0014）。

---

## 17. Workflows（工作流程）

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
  → 錯誤處理：{error policy}

Step 3: {AnalyzerName}       [Analyzer Worker]
  → 輸入：Step 2 輸出
  → 輸出：{output}
  → 若 confidence < 0.7 → 觸發 L2 驗證
  → 錯誤處理：{error policy}

Step 4: {ValidatorName}      [Validator]
  → 輸入：Step 3 輸出
  → 輸出：validated results

Step 5: Notification         [Notification Dispatcher]
  → 依 Notification Rules 發送
```

> **規則**：每一個步驟都必須註明失敗行為（retry / skip / abort workflow）。  
> 可並行的步驟標記為 parallel，有序列依賴的步驟說明依賴關係。

---

## 18. Knowledge（知識庫）

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

> Knowledge key 格式必須為 `{domain}/{topic}/...`（COMPAT-03）。

---

## 19. Test Cases（測試案例）

> 驗證 Domain 正確性的測試場景。每個重要的 Business Rule 都應有測試案例。

> **v1.1 變更**（來源：Marketplace REV-MKT-001 TEST-01 / MF-02）：  
> Parser 與 Analyzer 的測試**不再各自從零撰寫**，而是套用**共用測試模板**，  
> 確保每個 Parser / Analyzer 的測試覆蓋一致、不遺漏。Domain 只需填入該元件的具體輸入與預期輸出。

### Parser Test Template（所有 Parser 共用骨架）

每個 Parser 都必須涵蓋以下固定測試類型（至少各 1 筆，總計 ≥ 3）：

| 測試類型 | 驗證目標 | 範例 |
|---|---|---|
| **正常解析** | 標準輸入 → 完整 Entity | `TC-{XXX}-U01` |
| **必填缺失丟棄** | 缺少必填欄位 → 丟棄整筆 | `TC-{XXX}-U02` |
| **Normalization 對應** | 原始值正確映射到標準值（Section 11）| `TC-{XXX}-U03` |
| **格式邊界** | 特殊字元 / 極端值 / 空白處理 | `TC-{XXX}-U04` |

### Analyzer Test Template（所有 Analyzer 共用骨架）

| 測試類型 | 驗證目標 |
|---|---|
| **分數範圍** | score / confidence 落在 0.0–1.0 |
| **verdict 合法性** | verdict 必為定義的列舉值之一 |
| **confidence 門檻** | confidence < 門檻 → 正確觸發 L2 |
| **Golden Sample Replay** | 對 Golden Sample（Section 20）輸入產生符合標注的輸出 |

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

## 20. Golden Sample（黃金樣本）

> **v1.1 升級**（來源：Marketplace REV-MKT-001 MF-03）。  
> 範例資料不再只是孤立的 JSON 片段，而是**完整管線的 Golden Sample**：  
> 捕捉同一筆資料流經**每一層**的快照，使 Replay 可以從任一層直接重跑。

### Golden Sample 管線快照

一筆 Golden Sample 必須保存資料流經各層的完整快照：

```
原始輸入（平台 HTML / RSS / FB 貼文 / 圖片）
  → [OCR / 前處理]（若適用，如圖片轉文字）
  → Parser 輸出（結構化 JSON，符合 Section 6）
  → Analyzer 輸出（評分 + verdict + reason + confidence）
  → Notification（最終發送給使用者的訊息）
```

全部保存。這讓 Golden Sample 同時是：
1. **開發範例**：實作者對照每一層的預期輸入輸出
2. **回歸測試輸入**（GOVR-007 Replay）：可直接餵給 Analyzer 重跑
3. **Golden Dataset 種子**（GOVR-006）：加上人工標注後成為評估基準

### Golden Sample 結構

```json
{
  "sample_id": "{domain}-gs-001",
  "stage_0_raw": {
    "source": "{source_name}",
    "raw": "{原始資料片段}",
    "fetched_at": "2026-06-29T10:00:00Z"
  },
  "stage_1_preprocessed": {
    "note": "若無 OCR / 前處理則為 null",
    "content": null
  },
  "stage_2_parsed": {
    "{field1}": "{value}",
    "{field2}": "{value}"
  },
  "stage_3_analyzed": {
    "score": 0.85,
    "verdict": "{verdict}",
    "reason": "{AI 推理說明範例}",
    "confidence": 0.92
  },
  "stage_4_notification": {
    "priority": "P1",
    "rendered_message": "{最終通知訊息}"
  }
}
```

> **規則**：每個主要 Entity 至少要有一筆完整 Golden Sample。  
> 至少包含一筆「正常情境」與一筆「異常 / 邊界情境」（如疑似詐騙、無法映射）。

---

## 21. Future Extensions（未來擴充）

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

| 版本 | 日期 | 穩定度 | 說明 |
|---|---|---|---|
| 0.1 | {YYYY-MM-DD} | — | 初稿（每個新 Domain 文件從這裡開始）|
| 1.0 | 2026-06-27 | Stable | 初版：16 個必填區塊 |
| 1.1 | 2026-06-29 | Experimental | 來自 Marketplace 實戰驗證（REV-MKT-001）。新增 §7 Repository Interfaces、§8 Entity Status Lifecycle、§11 Normalization Rules、§14 Auditable Operations、§16 Event Catalogue；§12 Analyzers 加入 AIProvider 約束；§19 Test Cases 改用共用測試模板；§15→§20 Sample Data 升級為 Golden Sample。完整演進記錄見 GOVR-008。待第二個 Domain 驗證後升級為 Stable。|
