---
doc_type: architecture
doc_id: ARCH-002
title: PAOS Concept Map
status: accepted
version: "1.0"
date: 2026-06-27
related: [GLOSS-001, ARCH-001]
tags: [concept-map, relationships, hierarchy, layers]
---

# PAOS Concept Map

> 本文件是 Glossary（GLOSS-001）的視覺化補充。  
> 所有術語定義以 Glossary 為準；本文件只描述「關係」。

---

## Platform Hierarchy（平台層次圖）

```
PAOS Platform
│
├── Core（Platform 核心，常駐）
│      ├── Workflow Engine    ← 協調 Workflow 執行
│      ├── Scheduler          ← 管理時間觸發
│      ├── Event Bus          ← 內部通訊樞紐（所有跨層通訊必須過這裡）
│      ├── Priority Engine    ← 決定 Notification 重要性排序
│      └── Notification Dispatcher ← 交付 Notification 給 Application
│
├── Services（共用基礎設施，常駐）
│      ├── Memory Service     ← 三層記憶管理（Working/Short-term/Long-term）
│      ├── Knowledge Service  ← 領域知識管理 + 審核管線
│      ├── Validation Service ← AI 輸出品質控制（L1/L2/L3）
│      └── AI Provider Layer  ← Claude/GPT/Gemini 抽象
│
├── Workers（執行層，按需啟動）
│      ├── Collector          ← 取得外部原始資料
│      ├── Parser             ← 原始資料 → 結構化資料
│      ├── Analyzer           ← 結構化資料 → AI 洞察（內含 Agent）
│      ├── Validator          ← AI 輸出品質驗證
│      └── Reporter           ← 分析結果 → 使用者可讀格式
│
├── Domains（業務領域，可啟用/停用）
│      ├── stocks/            ← 股票追蹤
│      ├── secondhand/        ← 二手商品
│      ├── ai-news/           ← AI 產業動態
│      └── [future domains]
│
└── Applications（使用者介面，可部署）
       ├── telegram-bot/      ← Telegram Channel（含 TelegramAdapter）
       ├── web-ui/            ← Web 前端
       ├── dashboard/         ← 管理介面（V2）
       ├── cli/               ← 命令列工具
       └── api/               ← REST API Server
```

---

## 八層概念架構（Layer Diagram）

```
┌─────────────────────────────────────────────────────────┐
│                    Platform Layer                        │
│            Platform, Core, Service, Provider             │
├─────────────────────────────────────────────────────────┤
│                   Application Layer                      │
│          Application, Dashboard, Adapter, Project        │
├─────────────────────────────────────────────────────────┤
│                     Domain Layer                         │
│                    Domain, Plugin                        │
├─────────────────────────────────────────────────────────┤
│                    Workflow Layer                         │
│            Workflow, Pipeline, Job, Trigger              │
├─────────────────────────────────────────────────────────┤
│                    Execution Layer                       │
│   Worker, Collector, Parser, Analyzer, Reporter,         │
│   Validator, Agent, Tool, Action, Skill                  │
├──────────────────────────┬──────────────────────────────┤
│     Knowledge Layer      │       Memory Layer           │
│        Knowledge         │     Memory, Context          │
├─────────────────────────────────────────────────────────┤
│                  Infrastructure Layer                    │
│           Event, Task, Scheduler, Notification           │
└─────────────────────────────────────────────────────────┘
```

**層間通訊規則**（ADR-0014）：
- 跨層通訊 → Event Bus（非同步）或 Repository Query（同步唯讀）
- 同層通訊（Workflow 內）→ Context Object
- 派發任務給 Worker → Task Queue
- 任何層都不能直接 import 另一層的業務邏輯（只能 import Event Bus 和 Repository 介面）

---

## 全域關係矩陣

每個術語的 Parent / Children / Depends On / Used By：

| 術語 | Parent | Children | Depends On | Used By |
|---|---|---|---|---|
| Action | Workflow / Agent | 各具體操作 | Permission Model, Audit Log | Agent, Workflow Engine |
| Adapter | Application | 各 Channel Adapter | Event Bus | Application |
| Agent | Worker | Tool calls | Tool, Context, AI Provider | Analyzer Worker |
| Analyzer | Worker | Agent | AI Provider, Knowledge, Context | Workflow Engine, Priority Engine |
| Application | Platform | Adapter | Event Bus, Core | 使用者 |
| Collector | Worker | 各具體 Collector | External APIs, Event Bus | Workflow Engine, Scheduler |
| Context | Memory Layer | System Prompt, Memory subsets, Knowledge snippets | Memory Service, Knowledge Service | AI Provider, Agent |
| Core | Platform | Scheduler, Event Bus, Workflow Engine | Memory, Knowledge, AI Provider | Application, Domain |
| Dashboard | Application | — | API Application, Event Bus | 使用者 |
| Domain | Platform | Domain Workflows, Domain Knowledge, Domain Workers | Core（Event Bus）, Knowledge Service | Core（載入 Domain）, Application |
| Event | Infrastructure | 各具體 Event | Event Bus | Trigger, 任何訂閱者 |
| Job | Task | — | Scheduler | Scheduler |
| Knowledge | Knowledge Layer | KnowledgeItem | SQLite, sqlite-vss, Validator | Agent, Analyzer, Context Assembly |
| Memory | Memory Layer | Working, Short-term, Long-term | SQLite, sqlite-vss | Context Assembly, AI Provider |
| Notification | Infrastructure | P0/P1/P2/P3 | Priority Engine, Adapter | Reporter, Core |
| Parser | Worker | 各具體 Parser | Domain Schema | Workflow Engine（Pipeline 第二步）|
| Pipeline | Workflow | Collect→Parse→Analyze→Report | Workflow Engine | 口語描述，實作是 Workflow |
| Platform | — | Core, Application, Domain, Services | Infrastructure | — |
| Plugin | Domain Layer | — | PAOS Extension API | 第三方（V3+）|
| Project | Application Layer | — | Claude Projects API | 使用者（透過 Claude）|
| Provider | Platform | ClaudeProvider, OpenAIProvider... | External AI APIs | Agent, Analyzer |
| Reporter | Worker | — | Notification Service | Workflow Engine |
| Scheduler | Core | 排程規則 | Event Bus, Task Queue | Domain（定義排程）, Collector |
| Service | Platform | Memory S., Knowledge S., Validation S., AI Provider | packages/ | Core, Domain, Worker |
| Skill | Agent | Tool combinations | Tool | Agent |
| Task | Infrastructure | Task payload, Task result | Task Queue, SQLite | Worker, Scheduler, Workflow Engine |
| Tool | Execution | 各具體 Tool | AI Provider, Permission Model | Agent, Skill |
| Trigger | Workflow | 六種 Trigger 類型 | Event Bus | Workflow Engine |
| Validator | Execution | — | AI Provider, Knowledge | Analyzer, Knowledge Service |
| Worker | Runtime | Collector, Parser, Analyzer, Reporter, Validator | Event Bus, Task Queue | Workflow Engine |
| Workflow | Domain | Task（序列）| Workflow Engine, Event Bus, Worker | Trigger, Scheduler |

---

## 關鍵互動模式（Interaction Patterns）

### Pattern 1：使用者對話流程

```
User
 → Telegram Bot（Application）
 → TelegramAdapter（Adapter）
 → Event: user.message_received（Event Bus）
 → Core（接收 Event）
 → Memory Service（Context Assembly）
 → AI Provider（generate response）
 → Notification Dispatcher
 → TelegramAdapter
 → User
```

### Pattern 2：定時監控 Pipeline

```
Scheduler
 → Event: workflow.trigger_scheduled（Event Bus）
 → Workflow Engine
 → Task Queue: collect_task
 → Collector Worker（取得原始資料）
 → Event: data.collected
 → Parser Worker（格式轉換）
 → Event: data.parsed
 → Analyzer Worker（AI 分析，內含 Agent）
 → Event: data.analyzed
 → Priority Engine（評分）
 → Notification Dispatcher（發送 P0/P1 立即通知）
 → TelegramAdapter → User
```

### Pattern 3：Knowledge 更新流程

```
Analyzer（AI 建議新知識）
 → Validator L1（自動驗證）
 → Validator L3（發送人工確認 Notification）
 → User 確認
 → Knowledge Service（寫入，版本控制）
 → Event: knowledge.updated
```

### Pattern 4：Domain 擴充（新增 Domain）

```
新建 domains/stocks/
 ├── domain.json（manifest，Core 載入此文件）
 ├── knowledge-schema.json
 ├── workflows/daily-digest.yaml
 ├── notification-rules.json
 └── prompts/
      └── stock-analyzer.md

Core 載入 domain.json → 
Scheduler 讀取 workflows/ → 
Workflow Engine 可以執行 daily-digest → 
不需要修改任何 Core 程式碼
```

---

## 概念邊界速查（Concept Boundaries）

| 容易混淆的對 | 區別 |
|---|---|
| **Memory vs Knowledge** | Memory = 個人的、時間敏感的（上週你說了什麼）；Knowledge = 領域的、相對穩定的（股票的判斷規則）|
| **Agent vs Worker** | Agent = AI 推理邏輯；Worker = 執行環境容器。Agent 跑在 Worker 裡 |
| **Event vs Task** | Event = 已發生的不可變事實；Task = 待執行的可追蹤工作單元 |
| **Event vs Action** | Event = 已發生（過去式）；Action = 正在做（有副作用）|
| **Adapter vs Provider** | Adapter = 雙向 Channel 橋接（Telegram）；Provider = 單向服務接口（AI API）|
| **Domain vs Plugin** | Domain = PAOS 官方業務擴充；Plugin = 第三方貢獻（V3+）|
| **Job vs Task** | 統一用 Task；Job 只在描述 Scheduler 時口語說明 |
| **Pipeline vs Workflow** | 統一用 Workflow；Pipeline 只在說明線性資料流時口語說明 |
| **Trigger vs Event** | Event = 事實（「股價跌破 100」）；Trigger = 規則（「當股價跌破 100 時，執行 Workflow」）|
| **Context vs Memory** | Memory = 持久化儲存；Context = 為單次 AI 呼叫組裝的一次性集合 |
| **Notification vs Event** | Event = 系統內部通訊；Notification = 面向使用者的告知訊息 |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 從 Glossary v1.0 提取並擴充；新增 Layer Diagram、關係矩陣、互動模式、邊界速查 |
