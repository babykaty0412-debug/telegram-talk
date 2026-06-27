---
doc_type: glossary
doc_id: GLOSS-001
title: PAOS Architecture Glossary
status: accepted
version: "2.0"
date: 2026-06-27
priority: "00"
audience: [self, ai, engineer, automation]
tags: [ubiquitous-language, ddd, glossary, naming, single-source-of-truth]
---

# PAOS Architecture Glossary

> **第一優先閱讀文件。**  
> 在讀任何 ADR、架構文件或程式碼之前，先讀這份文件。  
> PAOS 的所有設計決策都使用這裡定義的語言。

---

## 為什麼這份文件存在？

大型系統失敗最常見的原因之一，是不同的人用相同的詞描述不同的事，或者用不同的詞描述相同的事。

這份文件的功能是 DDD（Domain-Driven Design）中的**通用語言（Ubiquitous Language）**：讓人、AI、工程師都在說同一種語言。

### Single Source of Truth（唯一真實來源）

**這是整個 PAOS 文件系統最重要的規則：**

1. 新增任何概念，必須先更新本文件。
2. 修改任何術語名稱，必須先更新本文件。
3. 任何 ADR、架構文件、Domain 文件，只能引用本文件中已定義的術語，**不能自行創造新名詞**。
4. 程式碼中的類別名、模組名、事件名，必須與本文件的 Canonical Name 一致。

違反此規則的後果：不同文件開始各自發明名詞，系統失去一致性，無法長期維護。

### 術語的生命週期

新術語被引入時狀態為 `Experimental`，在設計穩定後升為 `Evolving`，架構定稿後升為 `Stable`。  
任何 `Stable` 術語的更名需要對應的 Decision History 記錄與 ADR 引用。

---

## 八個概念層（Concept Layers）

每個術語只歸屬一個主要 Layer：

| Layer | 說明 | 主要術語 |
|---|---|---|
| **Platform Layer** | 系統最高層抽象 | Platform, Core, Service, Provider |
| **Application Layer** | 使用者介面與外部 Channel | Application, Dashboard, Adapter, Project |
| **Domain Layer** | 業務領域知識與規則 | Domain, Plugin |
| **Workflow Layer** | 流程編排與觸發 | Workflow, Pipeline, Job, Trigger |
| **Execution Layer** | 任務執行單元 | Worker, Collector, Parser, Analyzer, Reporter, Validator, Agent, Tool, Action, Skill |
| **Knowledge Layer** | 領域知識管理 | Knowledge |
| **Memory Layer** | 狀態與上下文管理 | Memory, Context |
| **Infrastructure Layer** | 跨層基礎設施 | Event, Task, Scheduler, Notification |

---

## 術語詞典（A–Z）

---

### Action

| | |
|---|---|
| **Canonical Name** | Action |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | Permission Model（ADR-0009）／ Workflow Engine |
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 瞬間執行，完成即結束 |

**Why does it exist?**  
系統需要區分「描述事情」（Event）和「做一件事」（Action）。Action 有副作用——它改變系統狀態。因為有副作用，Action 必須受到 Permission 模型管控，並記入 Audit Log。

**Definition**  
一個有副作用的原子操作——執行後會改變系統狀態（寫入資料庫、發送訊息、呼叫外部 API）。

**Anti-Definition — 不是什麼**  
不是 Event（已發生的事實，無副作用）；  
不是 Task（待執行的工作單元，包含 payload 和狀態）；  
不是 Workflow（多步驟流程）。  
→ Action 是有副作用的單一原子操作。

**Responsibility**  
代表「現在要做的一件具體事情」，帶有明確執行對象和預期結果。

**Out of Scope**  
不包含決策邏輯（由 Agent 決定）；不包含排程（由 Scheduler 決定）；純讀取操作不算 Action。

**Relationships**
- **Parent**: Workflow / Agent（Action 的發起者）
- **Children**: 各種具體操作（`send_telegram_message`, `write_knowledge`, `call_api`）
- **Depends On**: Permission Model, Audit Log
- **Used By**: Agent, Workflow Engine

**Examples**  
`send_telegram_message`、`write_knowledge`、`create_task`、`call_external_api`

**Cross References**  
- ADR-0009: Security & Permission Strategy（Permission 等級定義）  
- ADR-0012: Execution Model（Action 作為觸發結果）

**Decision History**  
— 無變更記錄

---

### Adapter

| | |
|---|---|
| **Canonical Name** | Adapter |
| **Layer** | Application Layer |
| **Stability** | Stable |
| **Owner** | 各個 Application（apps/ 目錄下）|
| **Aliases** | — |
| **Deprecated Names** | Connector（避免使用）|
| **Lifecycle** | 與 Application 同生命週期 |

**Why does it exist?**  
外部系統（Telegram、Discord、GitHub）各有自己的 API 格式。Adapter 讓 PAOS Core 不需要知道 Telegram 的 API——Core 只說「發一條訊息」，Adapter 負責翻譯。

**Definition**  
在 PAOS 內部介面與外部系統介面之間雙向轉換的元件。

**Anti-Definition — 不是什麼**  
不是 Provider（單向服務接口，用於 AI）；  
不是 Service（長期運行的共用服務）；  
不是 Plugin（第三方擴充）。  
→ Adapter 是 PAOS 與外部 Channel 的雙向橋梁。

**Responsibility**  
接收外部輸入，轉換成 PAOS 標準 `UserMessage` 格式；接收 PAOS 輸出，轉換成外部系統格式。

**Out of Scope**  
不包含業務邏輯；不處理 Memory 或 Knowledge；不直接與 Core 以外的元件互動。

**Relationships**
- **Parent**: Application（Adapter 是 Application 的一部分）
- **Children**: 各種具體 Adapter（`TelegramAdapter`, `DiscordAdapter`）
- **Depends On**: Event Bus（與 Core 通訊）
- **Used By**: Application（包裝 Adapter）、Core（接收標準化輸入）

**Examples**  
`TelegramAdapter`、`DiscordAdapter`、`GitHubWebhookAdapter`

**Cross References**  
- ADR-0002: Platform Strategy（平台無關性設計）  
- ADR-0014: Communication Strategy（Adapter 與 Core 的通訊方式）

**Decision History**  
— 無變更記錄

---

### Agent

| | |
|---|---|
| **Canonical Name** | Agent |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | Worker Pool（Worker 管理 Agent 生命週期）|
| **Aliases** | AI Worker（僅歷史文件中出現）|
| **Deprecated Names** | Bot（避免混用，Bot 特指 Telegram Bot）|
| **Lifecycle** | 隨 Task 建立，Task 完成即銷毀 |

**Why does it exist?**  
PAOS 需要 AI 能夠「推理並採取行動」，而不只是「回應」。Agent 讓 AI 有能力使用 Tool、查詢 Knowledge、做出多步驟決策。

**Definition**  
一個 AI 驅動的自主執行單元，能使用 Tools、查詢 Context，並產生結構化輸出完成特定 Task。

**Anti-Definition — 不是什麼**  
不是 Worker（執行環境容器）；  
不是 Tool（單一能力函數）；  
不是 Service（長期運行元件）；  
不是 Bot（Telegram Bot 是 Application，不是 Agent）。  
→ Agent 是使用 AI 進行推理並決策的執行主體，運行在 Worker 內。

**Responsibility**  
決定如何完成一個 Task（選擇 Tool、決定順序）；呼叫 AI Provider；輸出結構化結果。

**Out of Scope**  
不管理自己的排程；不直接持久化資料；不直接與 Channel 通訊；不管理自己的生命週期（Worker 管理）。

**Relationships**
- **Parent**: Worker（Agent 運行在 Worker 內）
- **Children**: Tool calls（Agent 使用的 Tools）
- **Depends On**: Tool, Context, AI Provider（透過 Provider 介面）
- **Used By**: Analyzer Worker（最常見的 Agent 宿主）

**Examples**  
`StockPriceAnalyzer`、`SecondhandClassifier`、`NewsSummarizer`

**Cross References**  
- ADR-0003: AI Provider Strategy（Agent 呼叫 AI 的方式）  
- ADR-0009: Security & Permission Strategy（Agent 的權限邊界）  
- ADR-0011: Runtime Strategy（Agent 在 Worker 內的執行模型）

**Decision History**  
— 無變更記錄（`Bot` 從未被採用為 Canonical Name）

---

### Analyzer

| | |
|---|---|
| **Canonical Name** | Analyzer |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | Worker Pool |
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 短期 Worker，分析完成即退出 |

**Why does it exist?**  
收集（Collector）和解析（Parser）不需要 AI。Analyzer 是 AI 真正介入的地方——對已結構化的資料做推理、評分、摘要。分離此職責確保 AI 計算只在需要時發生。

**Definition**  
一種專門的 Worker，負責對已解析的結構化資料執行 AI 分析，產生洞察、評分或摘要。

**Anti-Definition — 不是什麼**  
不是 Collector（負責取得原始資料）；  
不是 Parser（負責格式轉換，不使用 AI）；  
不是 Reporter（負責格式化展示結果）。  
→ Analyzer 是 AI 推理的執行容器，介於 Parser 和 Reporter 之間。

**Responsibility**  
呼叫 AI Provider；輸出分析結果；觸發後續 Event。

**Out of Scope**  
不收集原始資料；不解析格式；不交付通知。

**Relationships**
- **Parent**: Worker（Analyzer 是一種 Worker）
- **Children**: Agent（Analyzer 內部運行 Agent）
- **Depends On**: AI Provider, Knowledge（查詢領域規則）, Context（組裝 AI 輸入）
- **Used By**: Workflow Engine（Pipeline 中第三步）、Priority Engine（接收分析結果）

**Cross References**  
- ADR-0003: AI Provider Strategy  
- ADR-0011: Runtime Strategy（Worker 類型定義）

**Decision History**  
— 無變更記錄

---

### Application

| | |
|---|---|
| **Canonical Name** | Application |
| **Layer** | Application Layer |
| **Stability** | Stable |
| **Owner** | apps/ 目錄下各 package |
| **Aliases** | App（口語）|
| **Deprecated Names** | — |
| **Lifecycle** | 與部署週期相同（D1/D2/D3）|

**Why does it exist?**  
使用者需要透過不同介面使用 PAOS，但 Core 不應知道「介面長什麼樣子」。Application 讓 Core 保持介面無關（interface-agnostic）。

**Definition**  
一個可部署的使用者介面，讓使用者透過特定 Channel 存取 PAOS 功能。Application 包含一個或多個 Adapter。

**Anti-Definition — 不是什麼**  
不是 Domain（業務邏輯層）；  
不是 Service（共用基礎設施）；  
不是 Worker（後台執行單元）。  
→ Application 是面向使用者的前端，它只做「橋接」，不做業務決策。

**Responsibility**  
提供使用者互動介面；透過 Adapter 與外部系統溝通；將使用者意圖轉換為 PAOS Event。

**Out of Scope**  
不包含業務邏輯；不管理 Memory 或 Knowledge（由 Services 負責）。

**Relationships**
- **Parent**: Platform
- **Children**: Adapter（Application 包含一個或多個 Adapter）
- **Depends On**: Event Bus（與 Core 通訊）, Core（透過事件）
- **Used By**: 使用者（終端）

**Examples**  
`telegram-bot`、`web-ui`、`dashboard`、`cli`、`api`

**Cross References**  
- ADR-0001: Repository Strategy（apps/ 目錄命名規範）  
- ADR-0002: Platform Strategy（介面無關原則）  
- ADR-0015: Deployment Strategy（Application 的部署形態）

**Decision History**  
— apps/telegram/ → apps/telegram-bot/（ADR-0001 v2.0，命名更精確，支援未來 telegram-admin、telegram-notify）

---

### Collector

| | |
|---|---|
| **Canonical Name** | Collector |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | Domain（定義）+ Worker Pool（執行）|
| **Aliases** | Fetcher（非正式）|
| **Deprecated Names** | Scraper（過於具體，僅指爬蟲）|
| **Lifecycle** | 短期（單次爬取）或長期（持續輪詢）|

**Why does it exist?**  
外部資料來源的存取方式不穩定（逾時、格式變化、頻率限制）。隔離資料收集確保它的失敗不影響分析流程。

**Definition**  
一種專門的 Worker，負責從外部資料來源取得原始資料，不做任何解析或分析。

**Anti-Definition — 不是什麼**  
不是 Parser（負責格式轉換）；  
不是 Analyzer（負責 AI 推理）；  
不是 Repository（負責內部資料查詢）。  
→ Collector 只做一件事：從外部取得原始資料。

**Responsibility**  
連接外部 API 或爬取網頁；取得原始資料；處理逾時和重試；儲存原始快取；發出 `data.collected` Event。

**Out of Scope**  
不解析資料格式；不分析資料內容。

**Relationships**
- **Parent**: Worker
- **Children**: 各種具體 Collector（`TaiwanStockCollector`, `ShopeeCollector`）
- **Depends On**: External APIs（外部資料來源）, Event Bus（發出完成事件）
- **Used By**: Workflow Engine（Pipeline 第一步）、Scheduler（觸發定時收集）

**Examples**  
`TaiwanStockCollector`、`ShopeeListingCollector`、`RssNewsCollector`

**Cross References**  
- ADR-0011: Runtime Strategy（Collector 在 Worker Layer）  
- ADR-0013: Storage Strategy（原始資料快取至 SQLite）

**Decision History**  
— 無變更記錄

---

### Context

| | |
|---|---|
| **Canonical Name** | Context |
| **Layer** | Memory Layer |
| **Stability** | Stable |
| **Owner** | Memory Service（組裝）|
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 單次請求，請求結束即消失 |

**Why does it exist?**  
AI 的品質取決於它「這次呼叫知道什麼」。Context 在 token 預算限制內，為 AI 組裝最相關的資訊。Context 是 Memory + Knowledge + 當前請求的智慧組合。

**Definition**  
為一次 AI 呼叫組裝的完整資訊集合：System Prompt + 相關 Memory + 相關 Knowledge + 當前使用者輸入。

**Anti-Definition — 不是什麼**  
不是 Memory（持久化的記憶儲存）；  
不是 Knowledge（領域事實資料庫）；  
不是 Session（使用者會話容器）。  
→ Context 是一次性的，為單次 AI 呼叫組裝，用完即棄。

**Responsibility**  
Context Assembly（Working Memory 全部 + Long-term Memory 摘要 + Knowledge 相關片段）；在 token 限制內最大化相關性。

**Out of Scope**  
Context 只讀取，不寫入（寫入是 Memory Service 的職責）；Context 不跨請求保持。

**Relationships**
- **Parent**: Memory Layer（概念上屬於記憶系統）
- **Children**: System Prompt, Working Memory subset, Long-term Memory summary, Knowledge snippets
- **Depends On**: Memory Service（提供記憶片段）, Knowledge Service（提供知識片段）
- **Used By**: AI Provider（消費 Context）, Agent（透過 AI Provider）

**Cross References**  
- ADR-0006: Memory Strategy（Context Assembly 流程）  
- ADR-0003: AI Provider Strategy（Context 傳入 Provider）

**Decision History**  
— 無變更記錄

---

### Core

| | |
|---|---|
| **Canonical Name** | Core |
| **Layer** | Platform Layer |
| **Stability** | Stable |
| **Owner** | packages/core/ |
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 常駐，與 Platform 同生命週期 |

**Why does it exist?**  
若每個 Domain 和 Application 各自管理排程、通訊、記憶，系統很快混亂。Core 讓所有基礎能力集中，Domain 和 Application 只使用，不重新發明。

**Definition**  
PAOS 的中央基礎設施，包含所有與 Domain 無關、可被所有 Application 和 Domain 共用的能力。

**Anti-Definition — 不是什麼**  
不是 Application（使用者介面）；  
不是 Domain（業務邏輯）；  
不是 Framework（通用工具庫，Core 是 PAOS 專用的）。  
→ Core 是 PAOS 的心臟，但它不知道「股票是什麼」或「二手商品是什麼」。

**Responsibility**  
Workflow Engine、Scheduler、Event Bus、Priority Engine、Notification Dispatcher；不包含任何 Domain 特定邏輯。

**Out of Scope**  
Core 不知道任何 Domain 的業務；Core 不直接與 Channel 互動（Application 的職責）。

**Relationships**
- **Parent**: Platform
- **Children**: Scheduler, Event Bus, Workflow Engine, Priority Engine, Notification Dispatcher
- **Depends On**: Memory Service, Knowledge Service, AI Provider（透過介面）
- **Used By**: Application（透過 Event Bus）, Domain（透過 Event Bus）

**Cross References**  
- ADR-0002: Platform Strategy  
- ADR-0011: Runtime Strategy（Core Layer 定義）  
- ADR-0014: Communication Strategy（Core 的通訊邊界）

**Decision History**  
— 無變更記錄

---

### Dashboard

| | |
|---|---|
| **Canonical Name** | Dashboard |
| **Layer** | Application Layer |
| **Stability** | Evolving |
| **Owner** | apps/dashboard/ |
| **Aliases** | Admin UI（非正式）|
| **Deprecated Names** | — |
| **Lifecycle** | V2 實作 |

**Why does it exist?**  
Telegram 適合即時通知，不適合瀏覽歷史資料、管理設定、查看系統狀態。Dashboard 提供有視覺結構的介面。

**Definition**  
一個 Web-based Application，提供 PAOS 的狀態視覺化、歷史資料瀏覽與設定管理。

**Anti-Definition — 不是什麼**  
不是 Core（業務邏輯）；  
不是 API（後端服務）；  
不是指令介面（Dashboard 不觸發高風險 Action）。  
→ Dashboard 是唯讀 + 設定工具。

**Responsibility**  
顯示 Priority Engine 輸出（P3 低優先通知）；Knowledge 管理 UI；Workflow 執行歷史；系統設定。

**Relationships**
- **Parent**: Application
- **Children**: —
- **Depends On**: API Application（查詢資料）, Event Bus（接收狀態更新）
- **Used By**: 使用者（主動探索介面）

**Cross References**  
- ADR-0007: Notification Strategy（P3 通知只在 Dashboard）  
- ADR-0015: Deployment Strategy

**Decision History**  
— 無變更記錄（V2 規劃，尚未實作）

---

### Domain

| | |
|---|---|
| **Canonical Name** | Domain |
| **Layer** | Domain Layer |
| **Stability** | Stable |
| **Owner** | domains/ 目錄下各 module |
| **Aliases** | — |
| **Deprecated Names** | Feature（避免，過於模糊）、Module（避免，代碼組織術語）|
| **Lifecycle** | 與 Platform 同生命週期，可獨立啟用/停用 |

**Why does it exist?**  
「如何分析股票」與「如何分析二手商品」的邏輯完全不同。Domain 隔離業務邏輯，確保新增 Domain 不需要修改 Core。

**Definition**  
一個有界的業務領域，包含自己的知識規則、資料來源、Workflow 和通知條件。Domain 是 PAOS 的業務擴充單元。

**Anti-Definition — 不是什麼**  
不是 Service（共用基礎設施，Domain 使用 Service）；  
不是 Module（代碼組織概念，Domain 有業務含義）；  
不是 Microservice（Domain 不需要獨立部署，V1 在同一進程中）。  
→ Domain 是業務邊界，不是技術邊界。

**Responsibility**  
定義該領域的 Knowledge Schema、Workflow、Notification Rules 和資料來源。

**Out of Scope**  
不管理基礎設施；不直接與使用者互動；不直接呼叫其他 Domain。

**Relationships**
- **Parent**: Platform
- **Children**: Domain-specific Collector, Parser, Analyzer; Domain Workflows; Domain Knowledge
- **Depends On**: Core（透過 Event Bus）, Knowledge Service, Memory Service
- **Used By**: Core（載入 Domain 定義）, Application（透過 Core 存取 Domain 能力）

**Examples**  
`stocks`、`secondhand`、`ai-news`、`legal`

**Cross References**  
- ADR-0010: Domain Expansion Strategy（Domain Plugin System）

**Decision History**  
— 無變更記錄

---

### Event

| | |
|---|---|
| **Canonical Name** | Event |
| **Layer** | Infrastructure Layer |
| **Stability** | Stable |
| **Owner** | Event Bus |
| **Aliases** | — |
| **Deprecated Names** | Message（避免，過於通用）、Signal（避免，有其他含義）|
| **Lifecycle** | 發布後不可變；依設定保留或過期 |

**Why does it exist?**  
系統各部分需要知道「發生了什麼事」才能做出反應，但不應緊密耦合。Event 讓發布者和訂閱者完全解耦。

**Definition**  
一個不可變的事實記錄，描述系統中已經發生的事情（過去式）。Event 只記錄「發生了什麼」，不包含「應該做什麼」。

**Anti-Definition — 不是什麼**  
不是 Task（待完成的工作）；  
不是 Action（主動發起的操作）；  
不是 Notification（給使用者的訊息）；  
不是 Command（命令某人做某事）。  
→ Event 是已發生事實的不可變記錄。

**Responsibility**  
攜帶足夠上下文讓訂閱者決定是否行動；透過 Event Bus 路由到所有訂閱者。

**Out of Scope**  
不包含業務邏輯；不觸發特定行動（那是 Trigger 的職責）。

**Relationships**
- **Parent**: Infrastructure（概念層）
- **Children**: 各種具體 Event（`data.stocks_collected`, `workflow.completed`）
- **Depends On**: Event Bus（傳遞機制）
- **Used By**: Trigger（監聽並決定是否啟動 Workflow）、任何需要感知狀態變化的模組

**命名規則**：`{namespace}.{subject}_{past_tense_verb}`

**Examples**  
`data.collected`、`knowledge.updated`、`task.completed`、`stock.price_threshold_crossed`

**Cross References**  
- ADR-0011: Runtime Strategy（Event Bus 設計）  
- ADR-0014: Communication Strategy（Event 作為主要通訊模式）

**Decision History**  
— 無變更記錄

---

### Job

| | |
|---|---|
| **Canonical Name** | Task |
| **Layer** | Workflow Layer |
| **Stability** | Evolving |
| **Owner** | Scheduler |
| **Aliases** | Job（口語，特指 Scheduled Task）|
| **Deprecated Names** | — |
| **Lifecycle** | 與 Task 相同 |

**Why does it exist?**  
「Job」在技術傳統中有特定含義（cron job）。在 PAOS 中，Job 是 Scheduled Task 的口語化別稱，用在 Scheduler 語境。

**Definition**  
由 Scheduler 觸發的 Task。除觸發方式外，Job 與 Task 完全相同。

**Anti-Definition — 不是什麼**  
Job 本身不是獨立概念；它是「排程觸發的 Task」的口語說法。  
→ 在程式碼中，統一使用 `Task`。

**Relationships**
- **Parent**: Task（Job 是 Task 的子類型）
- **Depends On**: Scheduler（觸發源）
- **Used By**: Scheduler（管理生命週期）

**Cross References**  
- ADR-0012: Execution Model（六種 Trigger 類型）

> ⚠️ **使用規則**：程式碼和文件統一使用 `Task`；只在描述 Scheduler 功能時使用 `Job` 作口語說明。

**Decision History**  
— 無變更記錄

---

### Knowledge

| | |
|---|---|
| **Canonical Name** | Knowledge |
| **Layer** | Knowledge Layer |
| **Stability** | Stable |
| **Owner** | Knowledge Service（packages/knowledge/）|
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 永久，有版本控制 |

**Why does it exist?**  
AI 的推理品質取決於它知道什麼。PAOS 需要一個地方存放「相對穩定的領域事實」——可被版本控制、審核和重用的規則，而不是對話記憶。

**Definition**  
結構化的、領域特定的、相對穩定的資訊，可被多個 Workflow 和 Agent 引用。Knowledge 需要版本控制和人工審核。

**Anti-Definition — 不是什麼**  
不是 Memory（個人的、時間敏感的上下文）；  
不是 Database（泛指儲存媒介）；  
不是 Cache（暫時性資料）。  
→ Knowledge 是領域的、經過審核的、相對穩定的事實。

**Responsibility**  
儲存和管理 Domain 知識；提供語意查詢（Embedding 搜尋）；管理審核管線（AI 提議 → 人工確認）；版本控制所有變更。

**Out of Scope**  
不儲存對話記憶（Memory 的職責）；不儲存系統狀態（Task Queue 的職責）。

**Relationships**
- **Parent**: Knowledge Layer
- **Children**: KnowledgeItem（具體知識條目）、各 Domain 的知識規則
- **Depends On**: SQLite + sqlite-vss（儲存後端）, Validator（審核新知識）
- **Used By**: Agent（查詢）, Analyzer（推理時引用）, Context Assembly

**與 Memory 的核心區別**：
- Memory = 個人的、時間敏感的（「你上週說想追蹤 A 股票」）
- Knowledge = 領域的、相對穩定的（「A 類股票的技術面判斷規則」）

**Examples**  
二手商品定價規則、股票選股條件、AI 新聞重要性分類標準

**Cross References**  
- ADR-0004: Knowledge Strategy  
- ADR-0008: Validation Strategy（Knowledge 審核管線）  
- ADR-0013: Storage Strategy（SQLite + sqlite-vss）

**Decision History**  
— 無變更記錄

---

### Memory

| | |
|---|---|
| **Canonical Name** | Memory |
| **Layer** | Memory Layer |
| **Stability** | Stable |
| **Owner** | Memory Service（packages/memory/）|
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | Working：Session 級；Short-term：7–30 天；Long-term：永久 |

**Why does it exist?**  
AI 沒有記憶時，每次對話從零開始，無法建立長期協作。Memory 讓 PAOS 記住「你是誰、你喜歡什麼、我們上次談到哪裡」。

**Definition**  
PAOS 用於保存使用者特定、時間演進的情境資訊的三層系統（Working / Short-term / Long-term）。

**三層結構**：
- **Working Memory**：當前 Session 的全部對話（記憶體中，Session 結束即消失）
- **Short-term Memory**：最近幾週的對話摘要（SQLite，TTL 7–30 天）
- **Long-term Memory**：使用者偏好、長期目標（SQLite + 向量索引，永久）

**Anti-Definition — 不是什麼**  
不是 Knowledge（領域事實，與使用者無關）；  
不是 Database（泛指儲存，Memory 有衰減機制）；  
不是 Cache（性能優化，Memory 是業務邏輯的一部分）。  
→ Memory 是使用者個人的、隨時間演進的狀態保存系統。

**Responsibility**  
儲存三層記憶；提供 Context Assembly；管理 Short-term Memory 的 TTL 過期。

**Out of Scope**  
不儲存領域知識；不儲存 Task 狀態。

**Relationships**
- **Parent**: Memory Layer
- **Children**: Working Memory, Short-term Memory, Long-term Memory
- **Depends On**: SQLite（Short/Long-term）, sqlite-vss（Long-term 向量搜尋）
- **Used By**: Context Assembly, AI Provider（間接）

**Cross References**  
- ADR-0006: Memory Strategy  
- ADR-0013: Storage Strategy（sqlite-vss 相容性）

**Decision History**  
— 無變更記錄

---

### Notification

| | |
|---|---|
| **Canonical Name** | Notification |
| **Layer** | Infrastructure Layer |
| **Stability** | Stable |
| **Owner** | Notification Dispatcher（Core）|
| **Aliases** | Alert（P0/P1 高優先通知的口語）|
| **Deprecated Names** | Message（避免，Message 是 Telegram 概念）|
| **Lifecycle** | 一次性交付 |

**Why does it exist?**  
PAOS 監控大量資訊，但使用者注意力有限。Notification 讓系統主動告知「現在有一件重要的事需要你注意」。

**Definition**  
PAOS 主動向使用者交付的一則訊息，說明系統偵測到需要使用者注意的事情。

**Anti-Definition — 不是什麼**  
不是 Event（系統內部事實，使用者看不到）；  
不是 Action（系統執行的操作）；  
不是 Report（定期彙整，Notification 是即時的或有排程的）。  
→ Notification 是從系統到使用者的單向告知。

**Responsibility**  
依優先級（P0–P3）決定交付時機和管道；防止通知疲乏（批次、靜音模式）；記錄所有已發送通知。

**Out of Scope**  
不決定「什麼重要」（Priority Engine 決定）；不包含業務分析（Analyzer 完成後才通知）。

**Relationships**
- **Parent**: Infrastructure Layer
- **Children**: P0/P1/P2/P3 四種優先級
- **Depends On**: Priority Engine（重要性評分）, Adapter（交付管道）
- **Used By**: Reporter（格式化後交付）, Core（Notification Dispatcher）

**Cross References**  
- ADR-0007: Notification Strategy（四級優先模型）

**Decision History**  
— 無變更記錄

---

### Parser

| | |
|---|---|
| **Canonical Name** | Parser |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | Domain（定義 Schema）+ Worker Pool（執行）|
| **Aliases** | Transformer（非正式）|
| **Deprecated Names** | — |
| **Lifecycle** | 短期 Worker，解析完成即退出 |

**Why does it exist?**  
外部資料格式五花八門（API 回應、HTML、RSS）。Parser 在 AI 分析之前先把原始資料轉成結構化格式，讓 Analyzer 專注「理解意義」而不是「解析格式」。

**Definition**  
一種專門的 Worker，負責將 Collector 取得的原始資料轉換成符合 Domain Schema 的結構化格式。Parser 不使用 AI。

**Anti-Definition — 不是什麼**  
不是 Collector（取得原始資料）；  
不是 Analyzer（AI 推理）；  
不是 Validator（品質檢查）。  
→ Parser 是純粹的格式轉換，不涉及語意判斷。

**Responsibility**  
解析 JSON/HTML/XML/CSV；提取關鍵欄位；丟棄無效資料；輸出符合 Domain Schema 的結構化資料。

**Relationships**
- **Parent**: Worker
- **Children**: 各種具體 Parser（`ShopeeListingParser`, `StockCsvParser`）
- **Depends On**: Domain Schema（知道目標格式）
- **Used By**: Workflow Engine（Pipeline 中第二步，Collector 之後）

**Cross References**  
- ADR-0011: Runtime Strategy

**Decision History**  
— 無變更記錄

---

### Pipeline

| | |
|---|---|
| **Canonical Name** | Workflow |
| **Layer** | Workflow Layer |
| **Stability** | Evolving |
| **Owner** | Workflow Engine |
| **Aliases** | Pipeline（描述線性資料流時使用）|
| **Deprecated Names** | — |
| **Lifecycle** | 與 Workflow 相同 |

**Why does it exist?**  
資料處理常是線性的：收集 → 解析 → 分析 → 通知。Pipeline 是描述這種線性資料流的術語，強調「前一步的輸出是後一步的輸入」。

**Definition**  
一種線性的 Workflow，每個步驟的輸出直接成為下一步驟的輸入。資料單向流動。

**Anti-Definition — 不是什麼**  
不是獨立的概念，而是 Workflow 的一種特殊形式。  
→ Pipeline 是口語描述，實作術語是 Workflow。

**Relationships**
- **Parent**: Workflow（Pipeline 是 Workflow 的特殊形式）
- **Children**: Collect → Parse → Analyze → Report（典型 Pipeline）

**Cross References**  
- ADR-0005: Workflow Strategy

> ⚠️ **使用規則**：程式碼和文件統一使用 `Workflow`；`Pipeline` 只在說明線性資料流時作口語說明。

**Decision History**  
— 無變更記錄

---

### Platform

| | |
|---|---|
| **Canonical Name** | Platform |
| **Layer** | Platform Layer |
| **Stability** | Stable |
| **Owner** | paos/ repo（整個系統）|
| **Aliases** | System（口語）|
| **Deprecated Names** | — |
| **Lifecycle** | 永久 |

**Why does it exist?**  
PAOS 不只是一個應用程式，而是可以承載多個 Application 和 Domain 的基礎設施。稱之為 Platform 強調它的「承載」性質——不直接做業務，讓業務能夠發生。

**Definition**  
PAOS 整體，包含 Core、所有 Application、所有 Domain 和所有基礎設施。Platform 是系統的最高抽象層。

**Anti-Definition — 不是什麼**  
不是 Application（使用者介面）；  
不是 Framework（通用工具庫）；  
不是 Service（單一功能服務）。  
→ Platform 是承載一切的基礎，本身不執行業務邏輯。

**Relationships**
- **Parent**: — （最高層）
- **Children**: Core, Application, Domain, Services
- **Depends On**: Infrastructure（硬體、OS、執行環境）

**Cross References**  
- ADR-0002: Platform Strategy  
- ADR-0015: Deployment Strategy

**Decision History**  
— 無變更記錄

---

### Plugin

| | |
|---|---|
| **Canonical Name** | Plugin |
| **Layer** | Domain Layer |
| **Stability** | Experimental |
| **Owner** | 第三方 / 社群貢獻者 |
| **Aliases** | Extension（口語）、Add-on（口語）|
| **Deprecated Names** | — |
| **Lifecycle** | 獨立於 Core |

**Why does it exist?**  
隨 PAOS 成熟，可能需要支援第三方貢獻的擴充。Plugin 是非官方維護的擴充機制術語。

**Definition**  
由第三方或使用者貢獻的、遵循 PAOS 擴充標準的能力擴充包。

**Anti-Definition — 不是什麼**  
不是 Domain（PAOS 官方維護的業務擴充）；  
不是 Service（平台核心服務）；  
不是 Adapter（Channel 橋接）。  
→ Plugin 是 V3+ 的未來概念，V1 的業務擴充叫 Domain。

> ⚠️ **使用規則**：V1 的業務擴充是 **Domain**，不是 Plugin。Plugin 保留給未來第三方擴充機制。

**Cross References**  
- ADR-0010: Domain Expansion Strategy

**Decision History**  
— 無變更記錄（V3+ 規劃術語）

---

### Project

| | |
|---|---|
| **Canonical Name** | Project |
| **Layer** | Application Layer |
| **Stability** | Experimental |
| **Owner** | Claude Projects（外部系統，Anthropic 維護）|
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 由使用者管理 |

**Why does it exist?**  
Claude Projects 是 Anthropic 提供的功能，讓使用者可以給 Claude 持久的 System Prompt 和知識庫。在 PAOS 語境中，Project 代表「透過 Claude Projects 介面與 PAOS 互動的方式」。

**Definition**  
Claude Projects 中的一個容器，包含持久的 System Prompt 和上傳的知識文件。

**Anti-Definition — 不是什麼**  
不是 PAOS 的通用術語（這是 Claude 特定概念）；  
不是 Domain（Domain 是 PAOS 內部業務擴充）；  
不是 Application（Project 是外部系統的概念）。  
→ Project 只在描述「透過 Claude Projects 介面存取 PAOS」時使用。

**Relationships**
- **Parent**: Application Layer（作為 PAOS 的一種互動介面）
- **Depends On**: Claude Projects API

**Cross References**  
— 無對應 ADR（外部系統概念）

**Decision History**  
— 無變更記錄

---

### Provider

| | |
|---|---|
| **Canonical Name** | Provider |
| **Layer** | Platform Layer |
| **Stability** | Stable |
| **Owner** | packages/ai-provider/ |
| **Aliases** | AI Provider（當特指 AI 服務時）|
| **Deprecated Names** | — |
| **Lifecycle** | 常駐，與 Platform 同生命週期 |

**Why does it exist?**  
PAOS 不想被任何一家 AI 廠商綁定。Provider 讓系統說「我需要 AI 幫我分析」，而不是「我需要 Claude 幫我分析」——具體是哪個 AI，由設定決定。

**Definition**  
一個特定外部服務的標準化介面實作，讓 Core 可以使用服務而不知道服務的具體實作。

**Anti-Definition — 不是什麼**  
不是 Adapter（雙向橋接 Channel，Provider 是單向服務接口）；  
不是 Service（內部服務，Provider 是外部服務抽象）；  
不是 SDK（Provider 封裝了 SDK，外界不直接接觸 SDK）。  
→ Provider 是外部服務的單向接口抽象。

**Responsibility**  
實作 `AIProvider` 介面（`complete`、`stream`、`embed`、`toolCall`）；處理特定 API 的認證和錯誤。

**Out of Scope**  
不包含業務邏輯；不管理 Context（Memory Service 的職責）。

**Relationships**
- **Parent**: Platform Layer
- **Children**: `ClaudeProvider`, `OpenAIProvider`, `GeminiProvider`, `OllamaProvider`
- **Depends On**: External AI APIs（Anthropic、OpenAI 等）
- **Used By**: Agent（間接，透過 Analyzer）, Context Assembly

**Cross References**  
- ADR-0003: AI Provider Strategy

**Decision History**  
— 無變更記錄

---

### Reporter

| | |
|---|---|
| **Canonical Name** | Reporter |
| **Layer** | Execution Layer |
| **Stability** | Evolving |
| **Owner** | Notification Service |
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 短期 Worker |

**Why does it exist?**  
Analyzer 輸出的是分析結果，但使用者需要可讀訊息。Reporter 分離「分析」和「展示」兩個關注點。

**Definition**  
一種專門的 Worker，負責將 Analyzer 的輸出格式化成使用者可讀的通知或報告，並交付給 Notification Service。

**Anti-Definition — 不是什麼**  
不是 Analyzer（推理分析）；  
不是 Notification（交付機制）；  
不是 Formatter（太底層，Reporter 有業務邏輯）。  
→ Reporter 決定「如何把分析結果說給使用者聽」。

**Relationships**
- **Parent**: Worker
- **Depends On**: Notification Service（交付）
- **Used By**: Workflow Engine（Pipeline 最後一步）

> ⚠️ **V1 說明**：V1 中 Reporter 的功能通常由 Workflow 最後一個 Step 完成，不需要獨立的 Reporter Worker。

**Cross References**  
- ADR-0007: Notification Strategy

**Decision History**  
— 無變更記錄

---

### Scheduler

| | |
|---|---|
| **Canonical Name** | Scheduler |
| **Layer** | Infrastructure Layer |
| **Stability** | Stable |
| **Owner** | packages/core/（Scheduler 模組）|
| **Aliases** | Cron（口語，指底層實作）|
| **Deprecated Names** | — |
| **Lifecycle** | 常駐 |

**Why does it exist?**  
很多 PAOS 工作是時間觸發的（每日摘要、定時監控）。Scheduler 讓時間規則集中管理，不散布在各 Domain 中。

**Definition**  
負責管理和觸發時間性任務（cron job、定時 Workflow）的 Core 元件。

**Anti-Definition — 不是什麼**  
不是 Event Bus（Scheduler 使用 Event Bus 發出觸發，但它本身不是 Event Bus）；  
不是 Trigger（Trigger 是規則配置，Scheduler 是執行引擎）；  
不是 Worker（Scheduler 不執行業務邏輯）。  
→ Scheduler 是時間的管理者，它在正確的時間發出訊號。

**Responsibility**  
維護排程規則；在正確時間發出 Trigger 事件；確保同一排程同一時間只有一個 instance 執行。

**Relationships**
- **Parent**: Core
- **Children**: 各排程規則（cron expressions）
- **Depends On**: Event Bus（發出 Trigger）, Task Queue（追蹤 Job 狀態）
- **Used By**: Domain（定義排程 Workflow）, Collector（定時觸發收集）

**Cross References**  
- ADR-0011: Runtime Strategy  
- ADR-0012: Execution Model（Scheduled Trigger）

**Decision History**  
— 無變更記錄

---

### Service

| | |
|---|---|
| **Canonical Name** | Service |
| **Layer** | Platform Layer |
| **Stability** | Evolving |
| **Owner** | packages/ 下各 package |
| **Aliases** | — |
| **Deprecated Names** | Manager（反模式，避免使用）|
| **Lifecycle** | 常駐 |

**Why does it exist?**  
「Service」是描述「提供特定共用能力的長期運行元件」的通用詞。Memory Service、Knowledge Service 等是 Service 的實例。

**Definition**  
一個長期運行的元件，提供特定共用能力給 Core、Domain 和 Worker 使用。

**Anti-Definition — 不是什麼**  
不是 Worker（Worker 執行短期任務，Service 長期提供能力）；  
不是 Domain（Domain 是業務邊界，Service 是跨業務的基礎設施）；  
不是 Module（Module 是代碼組織，Service 有運行時含義）。  
→ Service 是一個持續提供能力的元件，不是一次性執行的。

> ⚠️ **使用規則**：優先使用具體名稱（Memory Service、Knowledge Service），避免只說「Service」。

**Cross References**  
- ADR-0011: Runtime Strategy

**Decision History**  
— 無變更記錄

---

### Skill

| | |
|---|---|
| **Canonical Name** | Skill |
| **Layer** | Execution Layer |
| **Stability** | Experimental |
| **Owner** | Agent |
| **Aliases** | Capability（非正式）|
| **Deprecated Names** | — |
| **Lifecycle** | 與 Agent 相同 |

**Why does it exist?**  
某些 Agent 的工作模式是可重複的（「搜尋 → 閱讀 → 摘要」）。Skill 是這種可重複使用的 Agent 行為模式的術語。

**Definition**  
由多個 Tool 組合而成的可重用 Agent 行為模式。

**Anti-Definition — 不是什麼**  
不是 Tool（單一能力函數）；  
不是 Workflow（平台層的業務流程）；  
不是 Agent（執行主體，Skill 是 Agent 使用的能力組合）。  
→ Skill 是「Tool 的組合配方」，Tool 是「原料」，Skill 是「食譜」。

**Relationships**
- **Parent**: Agent
- **Children**: Tool combinations
- **Depends On**: Tool（Skill 由多個 Tool 組成）

**Cross References**  
— 無對應 ADR（V1 設計概念，尚未正式化）

> ⚠️ **使用規則**：V1 中 Skill 主要在 Agent 的 Prompt 設計中使用，不是程式碼的一等公民。

**Decision History**  
— 無變更記錄

---

### Task

| | |
|---|---|
| **Canonical Name** | Task |
| **Layer** | Infrastructure Layer |
| **Stability** | Stable |
| **Owner** | Task Queue（ADR-0013）|
| **Aliases** | Job（特指排程觸發的 Task）|
| **Deprecated Names** | — |
| **Lifecycle** | Created → Queued → Running → Completed / Failed |

**Why does it exist?**  
系統需要一個清晰的「工作單元」概念——可追蹤、可重試、有明確輸入輸出的工作。Task 讓系統可以說「這件事需要被完成」並追蹤是否真的被完成了。

**Definition**  
一個具有明確輸入、輸出和完成條件的可執行工作單元。Task 是 Worker 可以獨立執行的最小工作。

**Anti-Definition — 不是什麼**  
不是 Event（已發生的事實，無執行狀態）；  
不是 Workflow（多步驟流程，Task 是單一工作）；  
不是 Action（原子操作，Task 包含 payload 和生命週期狀態）。  
→ Task 是待完成的工作單元，有生命週期、可追蹤、可重試。

**Responsibility**  
攜帶執行所需 payload；記錄執行狀態；支援重試（冪等設計）。

**Out of Scope**  
不包含「如何執行」的邏輯（Agent/Worker 的職責）。

**Relationships**
- **Parent**: Infrastructure Layer
- **Children**: Task payload, Task result
- **Depends On**: Task Queue（持久化）, SQLite（儲存）
- **Used By**: Worker（執行）, Scheduler（建立 Job Task）, Workflow Engine（建立 Workflow Tasks）

**Cross References**  
- ADR-0012: Execution Model  
- ADR-0013: Storage Strategy（Task Queue 在 SQLite）

**Decision History**  
— 無變更記錄

---

### Tool

| | |
|---|---|
| **Canonical Name** | Tool |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | AI Provider Layer + Domain |
| **Aliases** | Function（LLM API 術語，指同一概念）|
| **Deprecated Names** | — |
| **Lifecycle** | 與 Agent 呼叫相同 |

**Why does it exist?**  
LLM 只能生成文字，但 PAOS 的 Agent 需要真正執行操作（搜尋網頁、查詢知識庫、發送通知）。Tool 給 AI 結構化的、受控的能力邊界——AI 知道自己能做什麼，系統知道 AI 做了什麼。

**Definition**  
Agent 可以呼叫的一個明確定義的外部能力，有固定的輸入 schema 和輸出 schema。

**Anti-Definition — 不是什麼**  
不是 Action（Action 是有副作用的操作，Tool 是 Agent 呼叫的能力接口，可能包含 Action）；  
不是 Skill（Skill 是多個 Tool 的組合模式）；  
不是 API（API 是外部接口，Tool 是 Agent 的能力邊界定義）。  
→ Tool 是 Agent 的「手」——它的每個動作都有明確的 schema 和 Audit Log。

**Responsibility**  
提供 Agent 執行操作的能力；每次 Tool 呼叫都有 Audit Log 記錄。

**Relationships**
- **Parent**: Execution Layer
- **Children**: 各種具體 Tool（`web_search`, `query_knowledge`, `read_memory`）
- **Depends On**: AI Provider（Tool 在 Agent 呼叫 AI 時定義）, Permission Model（高風險 Tool 需要授權）
- **Used By**: Agent（呼叫）、Skill（組合多個 Tool）

**Examples**  
`web_search`、`query_knowledge`、`read_memory`、`send_notification`

**Cross References**  
- ADR-0003: AI Provider Strategy  
- ADR-0009: Security & Permission Strategy（Tool 呼叫的權限）

**Decision History**  
— 無變更記錄

---

### Trigger

| | |
|---|---|
| **Canonical Name** | Trigger |
| **Layer** | Workflow Layer |
| **Stability** | Stable |
| **Owner** | Workflow Engine（解析）+ Scheduler / Event Bus（觸發源）|
| **Aliases** | Hook（避免，有歷史歧義）|
| **Deprecated Names** | — |
| **Lifecycle** | 瞬間（條件滿足即觸發，不持久）|

**Why does it exist?**  
Event 描述「發生了什麼事」，但它不決定「應該做什麼」。Trigger 是連接 Event（事實）和 Workflow（行動）的橋梁——「如果 X 發生，就執行 Y」。

**Definition**  
一個配置規則，定義「當某個 Event 或條件滿足時，啟動哪個 Workflow」。

**Anti-Definition — 不是什麼**  
不是 Event（事實記錄）；  
不是 Workflow（被觸發的流程）；  
不是 Scheduler（時間管理）。  
→ Trigger 是 Event 和 Workflow 之間的規則配置。

**與 Event 的核心區別**：
- Event = 事實（「股價跌破 100」）
- Trigger = 規則（「當股價跌破 100 時，執行 price-alert Workflow」）

**Relationships**
- **Parent**: Workflow Layer
- **Children**: 各種 Trigger 類型（Scheduled, Event, Manual, Webhook, AI-initiated, API）
- **Depends On**: Event Bus（監聽 Event）
- **Used By**: Workflow Engine（接收觸發，啟動 Workflow）

**Cross References**  
- ADR-0005: Workflow Strategy  
- ADR-0012: Execution Model（六種 Trigger 類型）

**Decision History**  
— 無變更記錄

---

### Validator

| | |
|---|---|
| **Canonical Name** | Validator |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | Validation Service（ADR-0008）|
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 短期，驗證完成即結束 |

**Why does it exist?**  
AI 會產生幻覺和錯誤。Validator 在 AI 輸出被用於決策之前先做品質檢查。沒有 Validator，系統可靠性會隨 AI 使用量增加而下降。

**Definition**  
對 AI 輸出或資料品質進行多層驗證的元件，分為 L1（自動）、L2（交叉驗證）、L3（人工確認）三層（ADR-0008）。

**Anti-Definition — 不是什麼**  
不是 Parser（格式轉換，無品質判斷）；  
不是 Analyzer（語意推理）；  
不是 Filter（Validator 有三層，不是簡單過濾）。  
→ Validator 是 AI 輸出在被採用前的品質把關系統。

**Responsibility**  
L1: Schema 驗證 + Confidence 過濾；L2: 交叉驗證 + Multi-provider 確認；L3: 人工確認通知。

**Relationships**
- **Parent**: Execution Layer / Services Layer
- **Depends On**: AI Provider（L2 多 Provider 驗證）, Knowledge（規則一致性檢查）
- **Used By**: Analyzer（分析結果驗證）, Knowledge Service（新知識審核）

**Cross References**  
- ADR-0008: Validation Strategy

**Decision History**  
— 無變更記錄

---

### Worker

| | |
|---|---|
| **Canonical Name** | Worker |
| **Layer** | Execution Layer |
| **Stability** | Stable |
| **Owner** | Runtime（ADR-0011）|
| **Aliases** | — |
| **Deprecated Names** | — |
| **Lifecycle** | 短期（完成即退出）或長期（持續輪詢）|

**Why does it exist?**  
若所有任務在同一進程執行，一個長時間 AI 分析任務會阻塞所有其他任務（包括 Telegram 即時回覆）。Worker 隔離執行——每個 Worker 獨立運行，崩潰不影響 Core 或其他 Worker。

**Definition**  
一個獨立的執行單元，負責運行特定類型的 Task 和 Agent，與 Core Process 隔離。

**Anti-Definition — 不是什麼**  
不是 Agent（AI 推理邏輯，Agent 運行「在」Worker 內）；  
不是 Service（常駐服務，Worker 是任務型）；  
不是 Task（工作單元，Worker 執行 Task）。  
→ Worker 是執行環境容器，Agent 是容器裡的推理大腦。

**Responsibility**  
從 Task Queue 接收任務；在隔離環境執行 Agent 或處理邏輯；將結果寫回 Task Queue；在 Event Bus emit 完成事件。

**Out of Scope**  
不包含業務邏輯（在 Agent 和 Domain 中）；不直接呼叫其他 Worker。

**Relationships**
- **Parent**: Runtime Layer
- **Children**: Collector, Parser, Analyzer, Reporter, Validator（都是 Worker 的具體類型）
- **Depends On**: Event Bus（接收任務, 發出完成事件）, Task Queue（Task 生命週期）
- **Used By**: Workflow Engine（派發任務給 Worker）

**Cross References**  
- ADR-0011: Runtime Strategy（Worker Layer 定義）  
- ADR-0014: Communication Strategy（Worker 間通訊規則）

**Decision History**  
— 「V2 multi-process」改為「V2 Distributed-capable」（ADR-0011 v2.0）——Worker 可以是同進程、Docker 容器、K8s Pod 或 Serverless Function，不限於多進程。

---

### Workflow

| | |
|---|---|
| **Canonical Name** | Workflow |
| **Layer** | Workflow Layer |
| **Stability** | Stable |
| **Owner** | Workflow Engine（Core）|
| **Aliases** | Pipeline（描述線性資料流時）、Process（口語）|
| **Deprecated Names** | — |
| **Lifecycle** | 定義永久存在；執行實例有完整生命週期 |

**Why does it exist?**  
業務目標（「每天給我一份股票摘要」）需要多個步驟。Workflow 讓這些多步驟業務流程可被命名、版本控制、重用和觀測。

**Definition**  
一個命名的、有序的 Task 序列，定義完成某個業務目標的完整流程。Workflow 定義以 YAML 儲存（ADR-0005）。

**Anti-Definition — 不是什麼**  
不是 Pipeline（Pipeline 是 Workflow 的口語說法，特指線性資料流）；  
不是 Task（單一工作單元）；  
不是 Agent（AI 推理主體）；  
不是 Script（Workflow 是聲明式定義，不是命令式腳本）。  
→ Workflow 是業務流程的聲明式定義，由 Workflow Engine 執行。

**Responsibility**  
定義執行步驟的順序和條件；由 Workflow Engine 執行；每次執行有獨立追蹤 ID。

**Relationships**
- **Parent**: Domain（Workflow 定義在 Domain 中）
- **Children**: Task（Workflow 由一系列 Task 組成）、Step（每個 Task 也叫 Step）
- **Depends On**: Workflow Engine（執行）, Event Bus（步驟間通訊）, Worker（執行每個 Task）
- **Used By**: Trigger（啟動 Workflow）、Scheduler（定時啟動）

**Cross References**  
- ADR-0005: Workflow Strategy  
- ADR-0012: Execution Model（Workflow 的觸發方式）

**Decision History**  
— 無變更記錄

---

## 快速索引：術語 × Layer

| Layer | 術語 |
|---|---|
| **Platform Layer** | Core, Platform, Provider, Service |
| **Application Layer** | Adapter, Application, Dashboard, Project |
| **Domain Layer** | Domain, Plugin |
| **Workflow Layer** | Job, Pipeline, Trigger, Workflow |
| **Execution Layer** | Action, Agent, Analyzer, Collector, Parser, Reporter, Skill, Tool, Validator, Worker |
| **Knowledge Layer** | Knowledge |
| **Memory Layer** | Context, Memory |
| **Infrastructure Layer** | Event, Notification, Scheduler, Task |

---

## 快速索引：Stability Level

| Stability | 術語 |
|---|---|
| **Stable**（核心概念，盡量不改）| Action, Adapter, Agent, Analyzer, Application, Collector, Context, Core, Domain, Event, Knowledge, Memory, Notification, Parser, Platform, Provider, Scheduler, Task, Tool, Trigger, Validator, Worker, Workflow |
| **Evolving**（仍可能調整）| Dashboard, Job, Pipeline, Reporter, Service |
| **Experimental**（尚未定案）| Plugin, Project, Skill |

---

## 快速索引：Ownership（每個概念的唯一 Owner）

| 概念 | Owner |
|---|---|
| Action | Permission Model / Workflow Engine |
| Adapter | Application（apps/）|
| Agent | Worker Pool |
| Analyzer | Worker Pool |
| Application | apps/ package |
| Collector | Worker Pool |
| Context | Memory Service |
| Core | packages/core/ |
| Dashboard | apps/dashboard/ |
| Domain | domains/ module |
| Event | Event Bus |
| Job | Scheduler |
| Knowledge | Knowledge Service |
| Memory | Memory Service |
| Notification | Notification Dispatcher |
| Parser | Worker Pool |
| Pipeline | Workflow Engine |
| Platform | paos/ repo |
| Plugin | Third-party |
| Project | Claude Projects（外部）|
| Provider | packages/ai-provider/ |
| Reporter | Notification Service |
| Scheduler | packages/core/ |
| Service | packages/ |
| Skill | Agent |
| Task | Task Queue |
| Tool | AI Provider Layer + Domain |
| Trigger | Workflow Engine |
| Validator | Validation Service |
| Worker | Runtime |
| Workflow | Workflow Engine |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，31 個術語 + Concept Map + Naming Convention |
| 2.0 | 2026-06-27 | 大幅擴充：新增 Anti-Definition、Canonical Name/Aliases/Deprecated Names、Stability Level、Ownership 索引、Parent/Child/Depends On/Used By 關係、Cross References、Decision History；Concept Map 移至 concept-map.md；Naming Convention 移至 naming-convention.md；新增 Single Source of Truth 規則；新增八層 Concept Layer 分類 |
