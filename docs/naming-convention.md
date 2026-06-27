---
doc_type: system
doc_id: SYS-002
title: PAOS Naming Convention
status: accepted
version: "1.0"
date: 2026-06-27
related: [GLOSS-001, ARCH-002]
tags: [naming, convention, ubiquitous-language, anti-patterns]
---

# PAOS Naming Convention

> 本文件是 Glossary（GLOSS-001）的命名規範補充。  
> 在創建任何新的類別、模組、事件或文件時，先查本文件。

---

## 核心原則

**每個術語都有精確的含義，不能互換使用。**

一個名稱應該告訴讀者「這個東西做什麼、屬於哪個概念層」，而不只是「它叫什麼」。  
壞名稱是：`StockManager`、`BookAgent`、`TelegramService`。  
好名稱是：`StockCollector`、`BookAnalyzer`、`TelegramAdapter`。

---

## 命名決策樹

為一個新元件命名時，先回答這些問題：

```
這個東西是什麼？
│
├── 它從外部取得原始資料？
│      → Worker 類型：{Domain}Collector
│
├── 它把原始資料轉成結構化格式（不用 AI）？
│      → Worker 類型：{Domain}Parser
│
├── 它用 AI 對結構化資料做推理？
│      → Worker 類型：{Domain}Analyzer（內含 Agent）
│
├── 它把分析結果格式化成可讀訊息？
│      → Worker 類型：{Domain}Reporter（V1 通常是 Workflow Step）
│
├── 它是 AI 使用的單一能力接口？
│      → Tool：{verb}_{noun}（snake_case）
│
├── 它是多個 Tool 的組合行為模式？
│      → Skill（命名為行為描述，如 research、summarize）
│
├── 它是已發生的事實記錄？
│      → Event：{namespace}.{subject}_{past_tense_verb}
│
├── 它是待完成的工作單元？
│      → Task：{verb}_{noun}（snake_case）
│
├── 它是多步驟業務流程定義？
│      → Workflow：{context}-{action}（kebab-case）
│
├── 它連接 PAOS 與外部 Channel（Telegram 等）？
│      → Adapter：{Channel}Adapter（PascalCase）
│
├── 它是外部 AI 服務的接口實作？
│      → Provider：{ServiceName}Provider
│
├── 它是有界的業務領域？
│      → Domain：{noun}（小寫，如 stocks, secondhand）
│
├── 它是使用者可互動的介面？
│      → Application：{service}-{role}（kebab-case）
│
└── 以上都不是 → 先查 Glossary 是否已有適合的術語；
                  若無，提出新術語並先更新 Glossary
```

---

## Domain-specific 元件命名規則

**格式：`{Domain}{Role}`（PascalCase）**

| Role | 含義 | 範例 |
|---|---|---|
| `Collector` | 取得外部原始資料 | `StockCollector`、`ShopeeCollector`、`RssNewsCollector` |
| `Parser` | 原始資料 → 結構化資料 | `StockCsvParser`、`ShopeeListingParser` |
| `Analyzer` | AI 推理與分析 | `StockSentimentAnalyzer`、`PriceValueAnalyzer` |
| `Reporter` | 格式化結果 → 通知 | `StockDailyReporter`（V2+ 使用）|
| `Workflow` | 業務流程定義（YAML） | `daily-digest`、`price-alert`（kebab-case）|

**重要**：`{Domain}` 部分必須是 Glossary 中已定義的 Domain 名稱（如 `Stock`、`Secondhand`、`AiNews`）。不要自創 Domain 名稱。

---

## Application 命名規則

**格式：`{service}-{role}`（kebab-case，用於 apps/ 目錄）**

| 範例 | 說明 |
|---|---|
| `telegram-bot` | Telegram 使用者 Bot（主要互動介面）|
| `telegram-admin` | Telegram 管理 Bot（V2+，管理員專用）|
| `telegram-notify` | Telegram 通知 Bot（V2+，只發通知）|
| `web-ui` | Web 前端介面 |
| `dashboard` | 管理儀表板 |
| `cli` | 命令列工具 |
| `api` | REST API Server |

**為什麼不用 `{service}` 單詞？**  
`telegram` 太模糊——未來可能有多個 Telegram 相關的 Application。`{service}-{role}` 確保名稱唯一且語義清晰。

---

## Event 命名規則

**格式：`{namespace}.{subject}_{past_tense_verb}`**

- Namespace：描述「哪個模組或領域」發出這個 Event
- Subject：描述「什麼被影響了」（名詞，snake_case）
- Verb：必須是**過去式**（Event 是已發生的事實）

```
data.stocks_collected        ← data 命名空間，stocks 被 collected
data.listing_parsed          ← listing 被 parsed
knowledge.rule_updated       ← knowledge rule 被 updated
task.analysis_completed      ← analysis task 被 completed
workflow.daily_digest_started← daily digest workflow 被 started
user.message_received        ← user message 被 received
system.worker_crashed        ← worker 崩潰了
```

**禁止**：
- 現在式（`data.stocks_collecting`）——Event 是已發生的事實
- 命令式（`data.collect_stocks`）——Event 不是命令，Command 才是
- 沒有 Namespace（`stocks_collected`）——難以追蹤來源

所有 Event 名稱必須定義為常數，存放在 `packages/core/events.ts`（ADR-0014）。

---

## Task 命名規則

**格式：`{verb}_{noun}`（snake_case）**

Task 名稱描述「要做什麼」，用動詞開頭：

```
collect_stock_prices
parse_shopee_listing
analyze_sentiment
send_daily_summary
update_knowledge_rule
validate_ai_output
```

**禁止**：
- 名詞式命名（`stock_prices`）——無法表達動作
- PascalCase（`CollectStockPrices`）——Task 名稱用 snake_case

---

## Workflow 命名規則

**格式：`{context}-{action}`（kebab-case，存在 YAML 檔案中）**

```
daily-digest            ← 每日摘要
price-alert             ← 價格警報
new-listing-scan        ← 新商品掃描
weekly-report           ← 週報
knowledge-update        ← 知識更新
sentiment-analysis      ← 情緒分析
```

Workflow 的 YAML 檔案路徑：`domains/{domain}/workflows/{workflow-name}.yaml`

---

## 檔案與目錄命名規則

| 類型 | 規則 | 範例 |
|---|---|---|
| TypeScript 類別檔案 | PascalCase.ts | `StockCollector.ts`, `TelegramAdapter.ts` |
| TypeScript 模組/工具檔 | camelCase.ts | `contextAssembly.ts`, `eventBus.ts` |
| Workflow YAML | kebab-case.yaml | `daily-digest.yaml`, `price-alert.yaml` |
| Domain 目錄 | snake_case | `stocks/`, `secondhand/`, `ai_news/` |
| Application 目錄 | kebab-case | `telegram-bot/`, `web-ui/` |
| 測試檔案 | `{name}.test.ts` | `StockCollector.test.ts` |
| 環境變數 | SCREAMING_SNAKE_CASE，加 `PAOS_` 前綴 | `PAOS_DB_PATH`, `PAOS_LOG_LEVEL` |

---

## 禁止的命名模式

| 禁止模式 | 原因 | 應使用 |
|---|---|---|
| `{Domain}Agent` | Agent 是 AI 推理單元，不是業務實體 | `{Domain}Analyzer`（如果它分析）|
| `{Domain}Worker` | Worker 是執行環境，不是業務實體 | `{Domain}Collector`、`{Domain}Parser`（用具體 Role）|
| `{Domain}Task` | Task 是工作單元，不是業務實體 | 用 Workflow 名稱描述，Task 不需要業務命名 |
| `{Domain}Service` | Service 太模糊 | 用具體的 Role（Collector、Analyzer 等）|
| `{Domain}Manager` | Manager 是過時的反模式 | 根據具體職責命名 |
| `{Domain}Handler` | Handler 沒有架構含義 | 根據具體職責命名 |
| `{Domain}Helper` | Helper 沒有架構含義 | 根據具體職責命名 |
| `TelegramService` | Service 太模糊，且 Telegram 是 Channel | `TelegramAdapter` |
| `AIHelper` | Helper 沒有架構含義 | 根據職責：`AIProvider`、`Agent`、`Analyzer` |
| `BookBot` | Bot 特指 Telegram Bot，不是 AI 功能 | `BookAnalyzer`（分析書）|
| `DataManager` | Manager 反模式 + 過於模糊 | `Collector`（收集）、`Repository`（查詢）|

---

## 常見混淆場景

### 場景 1：我要建一個「幫助使用者查詢股票的東西」

❌ 不對：
- `StockBot`（Bot 是 Application，不是 AI 功能）
- `StockService`（Service 太模糊）
- `StockAgent`（Agent 是執行單元，不是業務功能）

✅ 正確（取決於職責）：
- 如果它取得原始股票資料 → `StockCollector`
- 如果它分析股票資料 → `StockAnalyzer`（內含 Agent）
- 如果它是整個業務領域 → `stocks` Domain
- 如果它是完整的資料流程 → `stock-daily-digest` Workflow

### 場景 2：我要建一個「AI 幫忙的東西」

❌ 不對：
- `AIHelper`（Helper 沒有架構含義）
- `SmartAnalyzer`（形容詞無法表達職責）
- `ClaudeWorker`（Claude 是 Provider，不是 Worker 名稱）

✅ 正確（取決於職責）：
- 如果它用 AI 推理資料 → `{Domain}Analyzer`
- 如果它是 AI 呼叫的接口 → `ClaudeProvider`（Provider 層）
- 如果它是 AI 使用的能力 → Tool（如 `query_knowledge`）

### 場景 3：我要建一個「管理 X 的東西」

❌ 不對：
- `StockManager`（Manager 反模式）
- `KnowledgeManager`（Knowledge Service 已存在）

✅ 正確：
- 「管理」通常是 Service 的職責（Memory Service, Knowledge Service）
- 如果需要新的 Service，命名為 `{Domain}Service`，但需先確認是否真的需要新 Service

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 從 Glossary v1.0 提取並大幅擴充；新增決策樹、各類命名規則、常見混淆場景 |
