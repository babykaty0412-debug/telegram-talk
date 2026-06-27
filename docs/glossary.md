---
doc_type: system
doc_id: GLOSS-001
title: PAOS Architecture Glossary
status: accepted
version: "1.0"
date: 2026-06-27
priority: "00"
audience: [self, ai, engineer, automation]
tags: [ubiquitous-language, ddd, glossary, naming]
---

# PAOS Architecture Glossary

> **第一優先閱讀文件。**  
> 在讀任何 ADR、架構文件或程式碼之前，先讀這份文件。  
> PAOS 的所有設計決策都使用這裡定義的語言。

---

## 為什麼這份文件存在？

大型系統失敗最常見的原因之一，是不同的人用相同的詞描述不同的事，或者用不同的詞描述相同的事。

在 DDD（Domain-Driven Design）裡，這份文件的功能叫做**通用語言（Ubiquitous Language）**：一套整個系統共用的詞彙，讓人、AI、工程師都在說同一種語言。

本文件的目的不只是「定義術語」，更是定義每個概念**為什麼存在**。當你需要新增一個概念時，先問：它的 Why 是什麼？如果無法清楚回答，它可能不需要存在，或者應該合併進現有概念。

---

## Concept Map（概念圖）

```
PAOS Platform（整個系統）
│
├── Application（使用者介面層）
│      ├── telegram-bot/        ← Channel Adapter 的實作
│      ├── web-ui/
│      ├── dashboard/
│      ├── cli/
│      └── api/
│
├── Core（平台核心）
│      ├── Workflow Engine       ← 協調 Workflow 執行
│      ├── Scheduler             ← 管理時間觸發
│      ├── Event Bus             ← 內部通訊樞紐
│      ├── Priority Engine       ← 決定重要性排序
│      └── Notification          ← 交付通知
│
├── Services（共用基礎服務）
│      ├── Memory Service        ← 三層記憶管理
│      ├── Knowledge Service     ← 領域知識管理
│      ├── Validation Service    ← AI 輸出品質控制
│      └── AI Provider Layer     ← Claude/GPT/Gemini 抽象
│
├── Workers（執行層）
│      ├── Collector             ← 收集外部資料
│      ├── Parser                ← 解析原始資料
│      ├── Analyzer              ← AI 推理與分析
│      ├── Validator             ← 品質驗證
│      └── Reporter              ← 格式化並交付結果
│
└── Domains（業務邏輯層）
       ├── stocks/               ← 股票追蹤
       ├── secondhand/           ← 二手商品
       ├── ai-news/              ← AI 動態
       └── [future domains...]
```

---

## 概念關係矩陣

| 概念 | 包含 | 被包含於 | 依賴 | 不直接互動 |
|---|---|---|---|---|
| Platform | Core, Application, Domain | — | — | — |
| Application | Adapter | Platform | Core | Domain |
| Core | Workflow, Scheduler, Event Bus | Platform | Services | Domain |
| Domain | Workflow, Knowledge, Collector | Platform | Core Services | 其他 Domain |
| Workflow | Task, Trigger, Pipeline | Core / Domain | Event Bus, Worker | — |
| Worker | Agent | Runtime | Event Bus, Knowledge | 其他 Worker |
| Agent | Tool | Worker | Context, Knowledge, AI Provider | — |
| Task | — | Task Queue | — | — |
| Event | — | Event Bus | — | — |
| Memory | Working, Short-term, Long-term | Services | — | — |
| Knowledge | Domain facts | Services | — | Memory |

---

## 術語詞典（A–Z）

---

### Action

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Workflow Engine / Permission Model（ADR-0009） |
| **Lifecycle** | 瞬間執行，完成即結束 |
| **Core Concept** | Yes |
| **Replaceable** | No |

**Why does it exist?**  
系統需要區分「描述事情」（Event）和「做一件事」（Action）。Action 有副作用——它改變系統狀態。因為有副作用，Action 必須受到 Permission 模型的管控。

**Definition**  
一個有副作用的原子操作——執行後會改變系統狀態（寫入資料庫、發送訊息、呼叫外部 API）。

**Responsibility**  
代表「現在要做的一件具體事情」，帶有明確的執行對象和預期結果。

**Out of Scope**  
不包含決策邏輯（由 Agent 決定）；不包含排程（由 Scheduler 決定）；純讀取操作不算 Action。

**Relationships**  
Action 由 Agent 或 Workflow 發起；所有 Action 記入 Audit Log；高風險 Action 需要 Permission 授權（ADR-0009）。

**Examples**  
`send_telegram_message`、`write_knowledge`、`create_task`、`call_external_api`

---

### Adapter

| 欄位 | 內容 |
|---|---|
| **Layer** | Interface Layer（Application 內部） |
| **Owner** | 各個 Application |
| **Lifecycle** | 與 Application 同生命週期 |
| **Core Concept** | Yes |
| **Replaceable** | Yes（可換成不同平台的 Adapter） |

**Why does it exist?**  
外部系統（Telegram、Discord、GitHub）各有自己的 API 格式。Adapter 的存在是為了讓 PAOS Core 不需要知道 Telegram 的 API 長什麼樣——Core 只說「發一條訊息」，Adapter 負責翻譯成 Telegram 的格式。

**Definition**  
在 PAOS 內部介面與外部系統介面之間雙向轉換的元件。

**Responsibility**  
- 接收外部輸入，轉換成 PAOS 的標準 `UserMessage` 格式
- 接收 PAOS 的輸出，轉換成外部系統可理解的格式

**Out of Scope**  
不包含業務邏輯；不處理 Memory 或 Knowledge；不直接與 Core 以外的元件互動。

**Relationships**  
Adapter 是 Application 的一部分；Application = Adapter + 使用者介面。

**Examples**  
`TelegramAdapter`、`DiscordAdapter`、`GitHubWebhookAdapter`

---

### Agent

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Worker（由 Worker 負責 Agent 的生命週期） |
| **Lifecycle** | 隨任務建立，任務完成即銷毀 |
| **Core Concept** | Yes |
| **Replaceable** | Yes（可替換背後的 AI Provider） |

**Why does it exist?**  
PAOS 需要 AI 不只是「回應」，而是能夠「推理並採取行動」。Agent 的存在就是讓 AI 有能力使用 Tool、查詢 Knowledge、做出多步驟決策，而不只是生成文字。

**Definition**  
一個 AI 驅動的自主執行單元，能使用 Tools、查詢 Context，並產生結構化輸出來完成特定任務。

**Responsibility**  
決定如何完成一個 Task（選擇使用哪些 Tool、以什麼順序）；呼叫 AI Provider；輸出結構化結果。

**Out of Scope**  
不管理自己的排程；不直接持久化資料；不直接與 Channel 通訊；不管理自己的生命週期（由 Worker 管理）。

**Relationships**  
Agent 運行在 Worker 內；Agent 使用 Tool；Agent 讀取 Context；Agent 的輸出透過 Event Bus 回傳。

**Examples**  
`StockPriceAnalyzer`（分析股票資料）、`SecondhandClassifier`（分類二手商品）、`NewsSummarizer`（摘要新聞）

> ⚠️ **命名規則**：Agent 的名稱應反映它「分析什麼」，不應使用 `{Domain}Agent` 這種模式（見 Naming Convention）。

---

### Analyzer

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer（Worker 類型） |
| **Owner** | Worker Pool |
| **Lifecycle** | 短期 Worker，分析完成即退出 |
| **Core Concept** | Yes |
| **Replaceable** | Yes |

**Why does it exist?**  
資料收集（Collector）和資料解析（Parser）都不需要 AI。Analyzer 是 AI 真正介入的地方——它對已結構化的資料做推理、評分、摘要。分離這個職責確保 AI 計算只在需要時發生。

**Definition**  
一種專門的 Worker，負責對已解析的結構化資料執行 AI 分析，產生洞察、評分或摘要。

**Responsibility**  
呼叫 AI Provider（透過 AIProvider 介面）；輸出分析結果；觸發後續 Event。

**Out of Scope**  
不收集原始資料（Collector 的職責）；不解析格式（Parser 的職責）；不交付通知（Notification 的職責）。

**Relationships**  
Analyzer 在 Parser 之後執行；Analyzer 的輸出送給 Priority Engine；Analyzer 使用 AI Provider。

**Examples**  
`StockSentimentAnalyzer`、`PriceValueAnalyzer`、`NewsPriorityAnalyzer`

---

### Application

| 欄位 | 內容 |
|---|---|
| **Layer** | Interface Layer |
| **Owner** | apps/ 目錄下各自的 package |
| **Lifecycle** | 與部署週期相同（D1/D2/D3） |
| **Core Concept** | Yes |
| **Replaceable** | Yes（可以新增或移除特定 Application） |

**Why does it exist?**  
使用者需要透過不同的介面（手機、瀏覽器、CLI）使用 PAOS，但 Core 不應該知道「介面長什麼樣子」。Application 的存在是讓 Core 保持介面無關（interface-agnostic）。

**Definition**  
一個可部署的使用者介面，讓使用者透過特定管道存取 PAOS 功能。Application 包含一個或多個 Adapter。

**Responsibility**  
提供使用者互動介面；透過 Adapter 與外部系統溝通；將使用者意圖轉換為 PAOS Event。

**Out of Scope**  
不包含業務邏輯（由 Domain 負責）；不管理 Memory 或 Knowledge（由 Services 負責）。

**Relationships**  
Application 包含 Adapter；Application 透過 Event Bus 與 Core 溝通；多個 Application 可以共用同一個 Core。

**Examples**  
`telegram-bot`（Telegram 使用者 Bot）、`web-ui`（Web 前端）、`dashboard`（管理介面）、`cli`

---

### Collector

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer（Worker 類型） |
| **Owner** | Domain（各 Domain 定義自己的 Collector）+ Worker Pool（執行） |
| **Lifecycle** | 短期（單次爬取）或長期（持續輪詢） |
| **Core Concept** | Yes |
| **Replaceable** | Yes |

**Why does it exist?**  
外部資料來源（RSS、API、爬蟲）的存取方式千變萬化，且可能不穩定（逾時、格式改變、頻率限制）。將資料收集隔離為專門的 Worker，確保它的失敗不會影響分析流程。

**Definition**  
一種專門的 Worker，負責從外部資料來源取得原始資料，不做任何解析或分析。

**Responsibility**  
連接外部 API 或爬取網頁；取得原始資料；處理逾時和重試；儲存原始快取；發出 `data.collected` Event。

**Out of Scope**  
不解析資料格式（Parser 的職責）；不分析資料內容（Analyzer 的職責）。

**Relationships**  
Collector 在 Workflow Pipeline 的第一步；Collector 的輸出觸發 Parser；Collector 受 Scheduler 排程。

**Examples**  
`TaiwanStockCollector`、`ShopeeListingCollector`、`RssNewsCollector`

---

### Context

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer（請求級別） |
| **Owner** | Memory Service（組裝）；AI Provider（消費） |
| **Lifecycle** | 單次請求，請求結束即消失 |
| **Core Concept** | Yes |
| **Replaceable** | No（所有 AI 呼叫都需要 Context） |

**Why does it exist?**  
AI 的品質直接取決於它在這次呼叫中「知道什麼」。Context 的存在是為了在 token 預算限制內，為 AI 組裝出「最相關的資訊」。Context 是 Memory + Knowledge + 當前請求的智慧組合。

**Definition**  
為一次 AI 呼叫組裝的完整資訊集合，包含 System Prompt、相關 Memory、相關 Knowledge 和當前使用者輸入。

**Responsibility**  
Context Assembly（將 Working Memory + Long-term Memory + Knowledge 按相關性組合）；在 token 限制內最大化相關性。

**Out of Scope**  
Context 是讀取的，不寫入（寫入是 Memory Service 的職責）；Context 不跨請求保持。

**Relationships**  
Context 由 Memory Service 組裝；Context 傳給 AI Provider；Context 包含 Working Memory 的全部 + Long-term Memory 的摘要。

**Examples**  
一次對話的 Context 包含：「你是 PAOS 助理」（System Prompt）+ 「上次對話你提到追蹤某股票」（Short-term Memory）+ 「使用者的風險偏好是保守型」（Long-term Memory）+ 「用戶說：今天股市怎麼樣？」（當前輸入）

---

### Core

| 欄位 | 內容 |
|---|---|
| **Layer** | Platform Core Layer |
| **Owner** | packages/core/ |
| **Lifecycle** | 與 Platform 同生命週期（常駐） |
| **Core Concept** | Yes |
| **Replaceable** | No（Core 是平台的心臟） |

**Why does it exist?**  
如果每個 Domain 和 Application 都各自管理排程、通訊、記憶，系統很快就會混亂。Core 的存在是讓所有這些基礎能力集中在一個地方，Domain 和 Application 只需要使用，不需要重新發明。

**Definition**  
PAOS 的中央基礎設施，包含所有與 Domain 無關、可被所有 Application 和 Domain 共用的能力。

**Responsibility**  
提供 Workflow 執行引擎、Scheduler、Event Bus、Priority Engine、Notification Dispatcher；不包含任何 Domain 特定邏輯。

**Out of Scope**  
Core 不知道「股票是什麼」或「二手商品是什麼」；Core 不直接與 Channel 互動（Application 的職責）。

**Relationships**  
Core 是所有 Application 和 Domain 的依賴來源；Core 只依賴 Services（Memory、Knowledge、AI Provider）。

---

### Dashboard

| 欄位 | 內容 |
|---|---|
| **Layer** | Interface Layer |
| **Owner** | apps/dashboard/ |
| **Lifecycle** | V2 實作 |
| **Core Concept** | No（是一種 Application） |
| **Replaceable** | Yes |

**Why does it exist?**  
Telegram 適合即時通知，但不適合瀏覽歷史資料、管理設定、查看系統狀態。Dashboard 的存在是提供一個有視覺結構的介面，讓使用者可以主動探索 PAOS 的狀態和資料。

**Definition**  
一個 Web-based Application，提供 PAOS 的狀態視覺化、歷史資料瀏覽、設定管理。

**Responsibility**  
顯示 Priority Engine 的輸出（P3 低優先通知）；提供 Knowledge 管理 UI；顯示 Workflow 執行歷史；提供系統設定介面。

**Out of Scope**  
Dashboard 是唯讀+設定工具，不是指令介面（不觸發高風險 Action）。

**Relationships**  
Dashboard 是一種 Application；Dashboard 透過 REST API（api/ Application）查詢資料；P3 通知只在 Dashboard 中顯示。

---

### Domain

| 欄位 | 內容 |
|---|---|
| **Layer** | Business Logic Layer |
| **Owner** | domains/ 目錄下各自的 module |
| **Lifecycle** | 與 Platform 同生命週期（可獨立啟用/停用） |
| **Core Concept** | Yes |
| **Replaceable** | Yes（每個 Domain 是獨立的模組） |

**Why does it exist?**  
PAOS 需要追蹤股票、二手商品、AI 新聞等，但「如何分析股票」與「如何分析二手商品」的邏輯完全不同。Domain 的存在是將業務邏輯隔離，確保新增一個 Domain 不需要修改 Core。

**Definition**  
一個有界的業務領域，包含自己的知識規則、資料來源、Workflow 和通知條件。Domain 是 PAOS 的業務擴充單元。

**Responsibility**  
定義該領域的 Knowledge Schema、Workflow、Notification Rules 和資料來源；提供 Collector、Parser、Analyzer 的 Domain 特定實作。

**Out of Scope**  
Domain 不管理基礎設施（由 Core 管理）；Domain 不直接與使用者互動（由 Application 管理）；Domain 不直接呼叫其他 Domain。

**Relationships**  
Domain 透過 Event Bus 與 Core 溝通；Domain 使用 Knowledge Service 和 Memory Service；Domain 定義的 Workflow 由 Core 的 Workflow Engine 執行。

**Examples**  
`stocks`（股票追蹤）、`secondhand`（二手商品）、`ai-news`（AI 產業動態）、`legal`（法律知識庫）

---

### Event

| 欄位 | 內容 |
|---|---|
| **Layer** | Communication Layer |
| **Owner** | Event Bus |
| **Lifecycle** | 發布後不可變；依設定保留或過期 |
| **Core Concept** | Yes |
| **Replaceable** | No（Event 是 PAOS 通訊的基礎） |

**Why does it exist?**  
系統的各個部分需要知道「發生了什麼事」才能做出反應，但它們不應該緊密耦合。Event 的存在讓發布者和訂閱者完全解耦——發布者不知道有誰在聽，訂閱者不知道是誰發布的。

**Definition**  
一個不可變的事實記錄，描述系統中已經發生的事情（過去式）。Event 不包含「應該做什麼」，只記錄「發生了什麼」。

**Responsibility**  
攜帶足夠的上下文資訊讓訂閱者決定是否需要行動；透過 Event Bus 路由到所有訂閱者。

**Out of Scope**  
Event 不包含業務邏輯；Event 不觸發任何特定行動（那是 Trigger 的職責）；Event 不包含使用者個資。

**Relationships**  
Event 由任何元件 emit；Event 透過 Event Bus 派發；Trigger 監聽 Event 並決定是否啟動 Workflow。

**命名規則**：使用點分隔的 namespace + 過去式動詞（`domain.data_collected`、`workflow.completed`、`task.failed`）

**Examples**  
`data.collected`、`knowledge.updated`、`task.completed`、`stock.price_threshold_crossed`

---

### Job

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Scheduler |
| **Lifecycle** | 與 Task 相同 |
| **Core Concept** | No（Task 的別名） |
| **Replaceable** | Yes（用 Task 代替） |

**Why does it exist?**  
「Job」在技術傳統（cron job、batch job）中有特定含義：一個由時間或排程觸發的後台工作。在 PAOS 中，Job 是 Scheduled Task 的口語化別稱，特別用在 Scheduler 語境中。

**Definition**  
由 Scheduler 觸發的 Task。除了觸發方式之外，Job 與 Task 完全相同。

**Responsibility**  
同 Task。

**Out of Scope**  
同 Task。

**Relationships**  
Job 是 Scheduled Trigger 觸發的 Task；Job 由 Scheduler 管理生命週期。

> ⚠️ **使用規則**：在程式碼和文件中，統一使用 `Task`；只在描述 Scheduler 功能時使用 `Job` 作為口語說明。

---

### Knowledge

| 欄位 | 內容 |
|---|---|
| **Layer** | Services Layer |
| **Owner** | Knowledge Service（packages/knowledge/） |
| **Lifecycle** | 永久，有版本控制 |
| **Core Concept** | Yes |
| **Replaceable** | No（Knowledge 是核心資料層） |

**Why does it exist?**  
AI 的推理品質取決於它知道什麼。PAOS 需要一個地方存放「相對穩定的領域事實」——不是對話記憶，而是「低於 $50 的二手書通常不值得購買」這種規則。Knowledge 讓這些規則可被版本控制、審核和重用。

**Definition**  
結構化的、領域特定的、相對穩定的資訊，可被多個 Workflow 和 Agent 引用。Knowledge 需要版本控制和人工審核。

**Responsibility**  
儲存和管理 Domain 知識；提供語意查詢（Embedding 搜尋）；管理知識的審核管線（AI 提議 → 人工確認）；版本控制所有變更。

**Out of Scope**  
Knowledge 不儲存對話記憶（那是 Memory 的職責）；Knowledge 不儲存系統狀態（那是 Task Queue 的職責）。

**Relationships**  
Knowledge 由 Domain 定義 Schema；Knowledge 由 Agent 查詢；Knowledge 的更新需要通過 Validation 和人工確認（ADR-0009）。

**與 Memory 的區別**：
- Memory = 個人的、時間敏感的、可能衰減（「你上週說想追蹤 A 股票」）
- Knowledge = 領域的、相對穩定的、需要審核（「A 類型股票的技術面判斷規則」）

**Examples**  
二手商品定價規則、股票選股條件、AI 新聞的重要性分類標準

---

### Memory

| 欄位 | 內容 |
|---|---|
| **Layer** | Services Layer |
| **Owner** | Memory Service（packages/memory/） |
| **Lifecycle** | Working Memory：Session 級；Short-term：7-30 天；Long-term：永久 |
| **Core Concept** | Yes |
| **Replaceable** | No（三層架構不可取代，但每層的儲存後端可替換） |

**Why does it exist?**  
AI 在沒有記憶的情況下，每次對話都是從零開始，無法建立連貫的長期協作關係。Memory 的存在讓 PAOS 能夠記住「你是誰、你喜歡什麼、我們上次談到哪裡」，而不只是「這次你說了什麼」。

**Definition**  
PAOS 用於保存使用者特定、時間演進的情境資訊的三層系統（Working / Short-term / Long-term）。

**三層結構**：
- **Working Memory**：當前 Session 的全部對話（記憶體中，Session 結束即消失）
- **Short-term Memory**：最近幾週的對話摘要（SQLite，TTL 7–30 天）
- **Long-term Memory**：使用者偏好、長期目標（SQLite + 向量索引，永久）

**Responsibility**  
儲存三層記憶；提供 Context Assembly（為每次 AI 呼叫組裝最相關的記憶）；管理 Short-term Memory 的過期。

**Out of Scope**  
不儲存領域知識（那是 Knowledge 的職責）；不儲存 Task 狀態（那是 Task Queue 的職責）。

---

### Notification

| 欄位 | 內容 |
|---|---|
| **Layer** | Core Layer |
| **Owner** | Notification Dispatcher（Core）|
| **Lifecycle** | 一次性交付（發送後完成） |
| **Core Concept** | Yes |
| **Replaceable** | Yes（不同管道的 Notification 可以替換） |

**Why does it exist?**  
PAOS 監控了大量資訊，但使用者的注意力是有限的。Notification 的存在是讓系統主動告知使用者「現在有一件重要的事需要你注意」，而不是讓使用者自己去查詢。

**Definition**  
PAOS 主動向使用者交付的一則訊息，說明系統偵測到一件需要使用者注意的事情。

**Responsibility**  
依優先級（P0–P3）決定交付時機和管道；避免通知疲乏（批次、靜音模式）；記錄所有已發送的通知。

**Out of Scope**  
Notification 不決定「什麼重要」（由 Priority Engine 決定）；Notification 不包含業務分析（由 Analyzer 完成後再通知）。

---

### Parser

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer（Worker 類型） |
| **Owner** | Domain（定義 Schema）+ Worker Pool（執行） |
| **Lifecycle** | 短期 Worker，解析完成即退出 |
| **Core Concept** | Yes |
| **Replaceable** | Yes |

**Why does it exist?**  
外部資料來源（API 回應、HTML、RSS）的格式五花八門。Parser 的存在是在 AI 分析之前，先把雜亂的原始資料轉換成結構化的格式。這讓 Analyzer 可以專注於「理解意義」，而不是「解析格式」。

**Definition**  
一種專門的 Worker，負責將 Collector 取得的原始資料轉換成符合 Domain Schema 的結構化格式。Parser 不使用 AI。

**Responsibility**  
解析 JSON/HTML/XML/CSV；提取關鍵欄位；丟棄無效資料；輸出符合 Domain Knowledge Schema 的結構化資料。

**Out of Scope**  
不從外部收集資料（Collector 的職責）；不分析資料意義（Analyzer 的職責）；不使用 AI。

**Examples**  
`ShopeeListingParser`（解析蝦皮商品資料）、`StockCsvParser`（解析股票 CSV）

---

### Pipeline

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Workflow Engine |
| **Lifecycle** | 與 Workflow 相同 |
| **Core Concept** | No（Workflow 的一種特殊形式） |
| **Replaceable** | Yes（用 Workflow 代替） |

**Why does it exist?**  
資料處理常常是線性的：收集 → 解析 → 分析 → 通知。Pipeline 是描述這種線性資料流的術語，強調「前一步驟的輸出是後一步驟的輸入」。

**Definition**  
一種線性的 Workflow，其中每個步驟的輸出直接成為下一步驟的輸入。資料像管道中的水一樣單向流動。

**Relationships**  
Pipeline 是 Workflow 的特殊形式；Collector → Parser → Analyzer → Reporter 是 PAOS 最典型的 Pipeline。

> ⚠️ **使用規則**：在程式碼和文件中，Pipeline 是口語說明詞；實際實作的術語是 Workflow。

---

### Platform

| 欄位 | 內容 |
|---|---|
| **Layer** | 整個系統 |
| **Owner** | 整個 paos/ repo |
| **Lifecycle** | 永久（只要系統存在） |
| **Core Concept** | Yes |
| **Replaceable** | No（Platform 本身就是 PAOS） |

**Why does it exist?**  
PAOS 不只是一個應用程式，而是一個可以承載多個 Application 和 Domain 的基礎設施。稱之為 Platform 是為了強調它的「承載」性質——它不直接做任何具體的業務，而是讓業務能夠發生。

**Definition**  
PAOS 整體，包含 Core、所有 Application、所有 Domain 和所有基礎設施。Platform 是系統的最高抽象層。

---

### Plugin

| 欄位 | 內容 |
|---|---|
| **Layer** | Extension Layer |
| **Owner** | 第三方或使用者貢獻 |
| **Lifecycle** | 獨立於 Core 的生命週期 |
| **Core Concept** | No |
| **Replaceable** | Yes |

**Why does it exist?**  
隨著 PAOS 成熟，可能需要支援第三方貢獻的擴充。Plugin 是泛指所有非 PAOS 官方維護的擴充機制的術語。

**Definition**  
由第三方或使用者貢獻的、遵循 PAOS 擴充標準的能力擴充包。

> ⚠️ **使用規則**：在 V1，PAOS 的業務擴充機制叫做 **Domain**，不是 Plugin。「Plugin」這個詞保留給未來的第三方擴充機制。

---

### Project

| 欄位 | 內容 |
|---|---|
| **Layer** | Interface Layer（Claude 特定概念） |
| **Owner** | Claude Projects（外部系統） |
| **Lifecycle** | 由使用者管理 |
| **Core Concept** | No |
| **Replaceable** | Yes |

**Why does it exist?**  
Claude Projects 是 Anthropic 提供的功能，讓使用者可以給 Claude 一個持久的 System Prompt 和知識庫。在 PAOS 語境中，Project 代表「透過 Claude Projects 介面與 PAOS 互動的方式」。

**Definition**  
Claude Projects 中的一個容器，包含持久的 System Prompt 和上傳的知識文件。

> ⚠️ **注意**：Project 是 Claude-specific 的概念，不是 PAOS 的通用術語。在 PAOS 架構中，類似的功能由 Domain + Memory 實現。

---

### Provider

| 欄位 | 內容 |
|---|---|
| **Layer** | Services Layer（AI Provider Layer） |
| **Owner** | packages/ai-provider/ |
| **Lifecycle** | 與 Platform 同生命週期 |
| **Core Concept** | Yes |
| **Replaceable** | Yes（整個 Provider 設計目的就是可替換） |

**Why does it exist?**  
PAOS 不想被任何一家 AI 廠商綁定。Provider 的存在讓 PAOS 可以說「我需要 AI 幫我分析這段文字」，而不需要說「我需要 Claude 幫我分析」——具體是 Claude、GPT 還是 Gemini，由設定決定。

**Definition**  
一個特定外部服務的標準化介面實作，讓 Core 可以使用服務而不知道服務的具體實作。在 PAOS 中最重要的是 AI Provider。

**Responsibility**  
實作 `AIProvider` 介面的 `complete`、`stream`、`embed`、`toolCall` 等方法；處理特定 API 的認證和錯誤。

**Out of Scope**  
Provider 不包含業務邏輯；Provider 不管理 Context（那是 Memory Service 的職責）。

**與 Adapter 的區別**：
- Adapter：雙向（接收輸入 + 輸出回應），用於 Channel（Telegram）
- Provider：單向（提供服務），用於 Service（AI）

**Examples**  
`ClaudeProvider`、`OpenAIProvider`、`GeminiProvider`、`OllamaProvider`

---

### Reporter

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer（Worker 類型） |
| **Owner** | Domain + Notification Service |
| **Lifecycle** | 短期 Worker |
| **Core Concept** | No |
| **Replaceable** | Yes |

**Why does it exist?**  
Analyzer 輸出的是分析結果，但分析結果需要被格式化成使用者可讀的訊息才能交付。Reporter 的存在是分離「分析」和「展示」兩個關注點。

**Definition**  
一種專門的 Worker，負責將 Analyzer 的輸出格式化成使用者可讀的通知或報告，並交付給 Notification Service。

**Relationships**  
Reporter 在 Analyzer 之後執行；Reporter 呼叫 Notification Service。

> ⚠️ **注意**：在 PAOS V1，Reporter 的功能通常由 Workflow 的最後一個 Step 完成，不需要獨立的 Reporter Worker。Reporter 是較複雜情境下的概念。

---

### Scheduler

| 欄位 | 內容 |
|---|---|
| **Layer** | Core Layer |
| **Owner** | Core（packages/core/） |
| **Lifecycle** | 常駐 |
| **Core Concept** | Yes |
| **Replaceable** | Yes（底層 cron 實作可替換） |

**Why does it exist?**  
很多 PAOS 的工作不是使用者觸發的，而是時間觸發的（每日摘要、定時監控）。Scheduler 的存在讓這些時間規則集中管理，而不是散布在各個 Domain 中。

**Definition**  
負責管理和觸發時間性任務（cron job、定時 Workflow）的 Core 元件。

**Responsibility**  
維護排程規則；在正確的時間發出 Trigger 事件；確保同一排程的同一時間只有一個 instance 執行。

---

### Service

| 欄位 | 內容 |
|---|---|
| **Layer** | Services Layer |
| **Owner** | packages/ 下各個 package |
| **Lifecycle** | 常駐 |
| **Core Concept** | No（通用術語，在 PAOS 中有具體實例） |
| **Replaceable** | 視具體 Service 而定 |

**Why does it exist?**  
「Service」是 PAOS 中描述「提供特定能力的長期運行元件」的通用詞。Memory Service、Knowledge Service 等都是 Service 的實例。

**Definition**  
一個長期運行的元件，提供特定的共用能力給 Core、Domain 和 Worker 使用。

> ⚠️ **使用規則**：程式碼和文件中，優先使用具體名稱（Memory Service、Knowledge Service），避免只說「Service」。

---

### Skill

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer（Agent 內部） |
| **Owner** | Agent |
| **Lifecycle** | 與 Agent 相同 |
| **Core Concept** | No |
| **Replaceable** | Yes |

**Why does it exist?**  
某些 Agent 的工作模式是重複的（例如「搜尋資料 → 閱讀頁面 → 摘要」）。Skill 是這種可重複使用的 Agent 行為模式的術語。

**Definition**  
一個由多個 Tool 組合而成的可重用 Agent 行為模式。

**Relationships**  
Skill 由多個 Tool 組成；Skill 是 Agent 使用的能力組合。

**與 Tool 的區別**：
- Tool = 單一能力（`web_search`）
- Skill = 組合的行為模式（`research` = search + read + summarize）

> ⚠️ **使用規則**：在 PAOS V1，Skill 這個詞主要在 Agent 的 Prompt 設計中使用，不是程式碼的一等公民。

---

### Task

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Task Queue（ADR-0013）|
| **Lifecycle** | Created → Queued → Running → Completed / Failed |
| **Core Concept** | Yes |
| **Replaceable** | No（Task 是執行的基本單元） |

**Why does it exist?**  
系統需要一個清晰的「工作單元」概念——它是可追蹤的、可重試的、有明確輸入輸出的。Task 的存在讓系統可以說「這件事需要被完成」並追蹤它是否真的被完成了。

**Definition**  
一個具有明確輸入、輸出和完成條件的可執行工作單元。Task 是可以被 Worker 獨立執行的最小工作。

**Responsibility**  
攜帶執行所需的 payload；記錄執行狀態；支援重試（冪等設計）。

**Out of Scope**  
Task 不包含「如何執行」的邏輯（那是 Agent/Worker 的職責）。

**Relationships**  
Task 由 Workflow、Scheduler 或 Trigger 建立；Task 由 Worker 執行；Task 的狀態持久化在 Task Queue（SQLite）。

---

### Tool

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer（Agent 層） |
| **Owner** | AI Provider Layer + Domain |
| **Lifecycle** | 與 Agent 呼叫相同 |
| **Core Concept** | Yes |
| **Replaceable** | Yes |

**Why does it exist?**  
LLM 本身只能生成文字，但 PAOS 的 Agent 需要能夠真正執行操作（搜尋網頁、查詢知識庫、發送通知）。Tool 的存在是給 AI 結構化的、受控的能力邊界——AI 知道自己能做什麼，系統知道 AI 做了什麼。

**Definition**  
Agent 可以呼叫的一個明確定義的外部能力，有固定的輸入 schema 和輸出 schema。

**Responsibility**  
提供 Agent 執行特定操作的能力；每個 Tool 呼叫都有 Audit Log 記錄。

**Examples**  
`web_search`（搜尋網頁）、`query_knowledge`（查詢知識庫）、`read_memory`（讀取記憶）、`send_notification`（發送通知）

---

### Trigger

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Workflow Engine（解析）+ Scheduler / Event Bus（觸發源）|
| **Lifecycle** | 瞬間（條件滿足即觸發，不持久） |
| **Core Concept** | Yes |
| **Replaceable** | Yes |

**Why does it exist?**  
Event 描述「發生了什麼事」，但它不決定「應該做什麼」。Trigger 的存在是連接 Event（事實）和 Workflow（行動）——它是「如果 X 發生，就執行 Y」的橋梁。

**Definition**  
一個配置規則，定義「當某個 Event 或條件滿足時，啟動哪個 Workflow」。

**與 Event 的區別**：
- Event = 事實（「股價跌破 100」）
- Trigger = 規則（「當股價跌破 100 時，執行 price-alert Workflow」）

**Relationships**  
Trigger 監聽 Event；Trigger 啟動 Workflow；Trigger 定義在 Domain 的 `workflow/*.yaml` 中。

---

### Validator

| 欄位 | 內容 |
|---|---|
| **Layer** | Services Layer |
| **Owner** | Validation Service（ADR-0008） |
| **Lifecycle** | 短期，驗證完成即結束 |
| **Core Concept** | Yes |
| **Replaceable** | Yes（驗證策略可替換） |

**Why does it exist?**  
AI 會產生幻覺和錯誤。Validator 的存在是在 AI 的輸出被用於決策之前，先做品質檢查。沒有 Validator，系統的可靠性會隨著 AI 使用量增加而下降。

**Definition**  
對 AI 輸出或資料品質進行多層驗證的元件，分為 L1（自動）、L2（交叉驗證）、L3（人工確認）三層（ADR-0008）。

---

### Worker

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Runtime（ADR-0011）|
| **Lifecycle** | 短期（完成即退出）或長期（持續輪詢） |
| **Core Concept** | Yes |
| **Replaceable** | Yes（V2+ 可替換為分散式 Worker） |

**Why does it exist?**  
如果所有任務都在同一個進程中執行，一個長時間的 AI 分析任務就會阻塞所有其他任務（包括 Telegram 的即時回覆）。Worker 的存在是隔離執行——每個 Worker 獨立運行，崩潰不影響其他 Worker 或 Core。

**Definition**  
一個獨立的執行單元，負責運行特定類型的 Task 和 Agent，與 Core Process 隔離。

**Responsibility**  
從 Task Queue（透過 Event Bus）接收任務；在隔離環境中執行 Agent 或處理邏輯；將結果寫回 Task Queue；在 Event Bus 上 emit 完成事件。

**Out of Scope**  
Worker 不包含業務邏輯（業務邏輯在 Agent 和 Domain 中）；Worker 不直接呼叫其他 Worker。

**與 Agent 的區別**：
- Worker = 執行環境（運行的容器）
- Agent = 執行邏輯（AI 推理的主體）
- Agent 運行「在」Worker 內

**Examples**  
Worker 類型：Collector Worker、Parser Worker、Analyzer Worker、Monitor Worker

---

### Workflow

| 欄位 | 內容 |
|---|---|
| **Layer** | Execution Layer |
| **Owner** | Workflow Engine（Core）|
| **Lifecycle** | 執行期間有生命週期；定義永久存在 |
| **Core Concept** | Yes |
| **Replaceable** | No（Workflow 是 PAOS 業務邏輯的主要載體） |

**Why does it exist?**  
業務目標（「每天給我一份股票摘要」）通常需要多個步驟完成。Workflow 的存在是讓這些多步驟業務流程可被命名、版本控制、重用和觀測。

**Definition**  
一個命名的、有序的 Task 序列，定義了完成某個業務目標的完整流程。Workflow 的定義以 YAML 儲存（見 ADR-0005）。

**Responsibility**  
定義執行步驟的順序和條件；由 Workflow Engine 執行；每個 Workflow 執行都有獨立的追蹤 ID。

**Relationships**  
Workflow 由 Trigger 啟動（見 ADR-0012）；Workflow 包含多個 Task；Workflow 由 Workflow Engine 執行；Workflow 定義在 Domain 中。

---

## Naming Convention（命名規範）

### 核心原則

**每個術語都有精確的含義，不能互換使用。**

選擇名稱時的決策流程：

```
這個東西是什麼？
│
├── 它是「執行環境」（承載任務的容器）→ Worker
├── 它是「AI 推理單元」（使用 Tools 完成目標）→ Agent
├── 它是「工作單元」（可追蹤、可重試的工作）→ Task
├── 它是「已發生的事實」（不可變）→ Event
├── 它是「多步驟業務流程」→ Workflow
├── 它是「業務領域」（股票、二手商品）→ Domain
├── 它是「外部系統橋接」（Telegram、GitHub）→ Adapter
├── 它是「服務介面實作」（Claude、GPT）→ Provider
├── 它是「使用者介面」（TG Bot、Web）→ Application
└── 以上都不是 → 再思考是否真的需要新術語
```

---

### Domain-specific 元件的命名規則

**格式：`{Domain}{Role}`**

| Role | 含義 | 範例 |
|---|---|---|
| Collector | 收集外部資料的 Worker | `StockCollector`、`ShopeeCollector` |
| Parser | 解析原始資料的 Worker | `StockCsvParser`、`ListingParser` |
| Analyzer | 執行 AI 分析的 Worker | `StockSentimentAnalyzer`、`PriceAnalyzer` |
| Workflow | 業務流程定義 | `StockDailyWorkflow`、`SecondhandAlertWorkflow` |

---

### 禁止的命名模式

| 禁止 | 原因 | 應使用 |
|---|---|---|
| `BookAgent` | Agent 是 AI 推理單元，不是業務實體 | `BookAnalyzer`（如果它分析書）|
| `BookWorker` | Worker 是執行環境，不是業務實體 | `BookCollector`、`BookParser`（用具體 Role）|
| `BookTask` | Task 是工作單元，不是業務實體 | 用 Workflow 名稱描述，不要給 Task 命名 |
| `TelegramService` | Service 太模糊 | `TelegramAdapter` |
| `StockManager` | Manager 是過時的反模式 | `StockCollector`、`StockWorkflow` |
| `AIHelper` | Helper 沒有架構含義 | 根據具體職責命名 |

---

### Event 命名規則

Event 名稱使用**點分隔的 namespace**，動詞用**過去式**：

```
{namespace}.{subject}_{past_tense_verb}

data.stocks_collected
data.listing_parsed
knowledge.rule_updated
task.analysis_completed
workflow.daily_digest_started
user.message_received
system.worker_crashed
```

---

### Task 命名規則

Task 使用**動詞_名詞**（snake_case）：

```
collect_stock_prices
parse_shopee_listing
analyze_sentiment
send_daily_summary
```

---

### Workflow 命名規則

Workflow 使用**kebab-case 描述性名稱**（存在 YAML 檔案中）：

```
daily-digest
price-alert
new-listing-scan
weekly-report
```

---

## 待釐清的邊界

以下邊界仍需要在實作中持續確認，如有歧義請以本文件為準：

| 邊界 | 規則 |
|---|---|
| Memory vs Knowledge | 個人的、時間敏感的 → Memory；領域的、相對穩定的 → Knowledge |
| Agent vs Worker | AI 推理邏輯 → Agent；執行環境 → Worker；Agent 跑在 Worker 裡 |
| Event vs Task | 已發生的事實 → Event；需要被完成的工作 → Task |
| Adapter vs Provider | 雙向橋接（Channel）→ Adapter；單向服務（AI）→ Provider |
| Domain vs Plugin | PAOS 官方業務擴充 → Domain；第三方貢獻 → Plugin（V3+） |
| Job vs Task | 統一用 Task；Job 只在描述 Scheduler 時用作口語說明 |
| Pipeline vs Workflow | 統一用 Workflow；Pipeline 只在說明線性資料流時用作口語說明 |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，定義 31 個術語 + Concept Map + Naming Convention |
