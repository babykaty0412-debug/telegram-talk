---
doc_type: architecture
doc_id: ARCH-001
title: Platform Blueprint
status: draft
version: "0.9"
date: 2026-06-27
related: [ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010]
tags: [architecture, overview, blueprint]
---

# PAOS Platform Blueprint

> **版本說明**：本文件為 Draft（0.9），等 ADR-0001（Repo Strategy）與 Runtime Strategy 確定後升為 1.0。

---

## 一、平台全貌

```
┌─────────────────────────────────────────────────────────────────┐
│                        Interaction Channels                      │
│           Telegram │ Web UI │ CLI │ Line │ Discord │ API        │
└─────────────────────────────┬───────────────────────────────────┘
                              │ Channel Adapters
┌─────────────────────────────▼───────────────────────────────────┐
│                         PAOS Platform Core                       │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │ Workflow     │  │ Priority     │  │ Notification           │ │
│  │ Engine       │  │ Engine       │  │ Dispatcher             │ │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬─────────────┘ │
│         │                 │                      │              │
│  ┌──────▼───────────────────────────────────────▼─────────────┐ │
│  │                    Core Services                            │ │
│  │  Knowledge Manager │ Memory Manager │ Validation Engine    │ │
│  └──────────────────────────────────────────────────────────── │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   AI Provider Layer                       │   │
│  │   Claude Adapter │ OpenAI Adapter │ Gemini │ Ollama      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │ Domain Plugin System
┌─────────────────────────────▼───────────────────────────────────┐
│                          Domains                                 │
│         stocks │ secondhand │ ai-news │ legal │ ...             │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                      External Integrations                       │
│         Stock API │ Shopee │ RSS Feeds │ GitHub │ Gmail │ ...   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、分層說明

### 層 1：Interaction Channels（互動管道）

使用者與 PAOS 溝通的所有入口點。每個管道是一個**介面卡（Channel Adapter）**，負責：
- 接收使用者輸入，轉換為統一的 `UserMessage` 格式
- 將 Platform Core 的回應轉換為管道特定的格式輸出

**目前實作**：Telegram Adapter（`apps/telegram/`）  
**未來計劃**：Web UI、CLI、LINE、Discord

**關鍵原則**：Channel Adapter 不包含任何業務邏輯。

---

### 層 2：Platform Core

PAOS 的核心，包含三個子系統：

#### 2a. Workflow Engine

負責執行 Domain 定義的 Workflow。  
接收觸發器（Trigger）→ 執行 Steps → 產生結果。  
詳見：**ADR-0005**

#### 2b. Priority Engine

PAOS 的核心差異化功能。  
輸入：多個 Domain 產生的事件（可能有數百個）  
輸出：按重要性排序的優先事件清單  
決策依據：Domain 定義的規則 + AI 評分 + 使用者歷史行為  
詳見：**Vision & Scope §8**

#### 2c. Notification Dispatcher

接收 Priority Engine 的輸出，依優先級決定通知的時機和管道。  
詳見：**ADR-0007**

---

### 層 3：Core Services

所有 Workflow 和 Engine 共用的基礎服務：

| 服務 | 責任 | 相關 ADR |
|---|---|---|
| Knowledge Manager | 知識庫的 CRUD、版本控制、審核管線 | ADR-0004 |
| Memory Manager | 三層記憶的讀寫、Context Assembly | ADR-0006 |
| Validation Engine | AI 輸出的多層驗證 | ADR-0008 |

---

### 層 4：AI Provider Layer

所有 AI 呼叫的統一抽象層。  
Platform Core 只與 `AIProvider` 介面互動，不知道背後是 Claude 還是 GPT。  
詳見：**ADR-0003**

---

### 層 5：Domain Plugin System

每個 Domain 是獨立的模組，透過 `domain.json` 宣告能力，Platform Core 動態載入。  
新增 Domain 不需要修改 Platform Core。  
詳見：**ADR-0010**

---

### 層 6：External Integrations

所有外部 API 和資料來源。AI Agent 不得直接呼叫外部 URL，必須透過統一的 `ExternalAPIGateway`。  
詳見：**ADR-0009**

---

## 三、資料流示意

### 情境 A：使用者透過 Telegram 發問

```
Telegram 訊息
  → Channel Adapter（解析訊息）
  → Workflow Engine（選擇對話處理 Workflow）
    → Memory Manager（讀取 Context）
    → AI Provider（生成回應）
    → Validation Engine（驗證輸出）
  → Channel Adapter（格式化）
  → Telegram 回覆
```

### 情境 B：排程任務觸發每日摘要

```
Schedule Trigger（08:00）
  → Workflow Engine（執行 daily-digest Workflow）
    → 各 Domain 的資料收集 Steps
    → AI Provider（分析 + 摘要）
    → Priority Engine（排序今日最重要的 N 件事）
    → Notification Dispatcher（決定推送方式）
  → Telegram 推送批次摘要
```

### 情境 C：Domain 監控觸發警示

```
External API（股價更新）
  → stocks Domain（規則評估：是否觸及門檻）
  → Validation Engine（確認訊號可靠性）
  → Priority Engine（分類為 P1 High）
  → Notification Dispatcher（立即推送）
  → Telegram 即時警示
```

---

## 四、Repo 結構（建議，待 ADR-0001 確認）

```
paos/                              ← 主倉庫
├── packages/
│   ├── core/                      ← Platform Core（Workflow Engine, Priority Engine, Notification Dispatcher）
│   ├── ai-provider/               ← AI Provider 抽象層 + Adapters
│   ├── knowledge/                 ← Knowledge Manager
│   ├── memory/                    ← Memory Manager
│   ├── validation/                ← Validation Engine
│   └── shared/                    ← 共用型別、工具函數
├── apps/
│   ├── telegram/                  ← Telegram Channel Adapter（從 telegram-talk 遷移）
│   ├── web/                       ← 未來 Web UI
│   └── cli/                       ← 未來 CLI
├── domains/
│   ├── stocks/
│   ├── secondhand/
│   └── ai-news/
├── docs/                          ← 架構文件（本目錄）
└── tools/                         ← 開發工具（Windows watchdog 等）
    ├── windows/
    └── docker/
```

---

## 五、待決定事項

本文件有以下部分依賴未確認的決策：

| 待決項 | 影響範圍 | 對應 ADR |
|---|---|---|
| Repo 策略（Monorepo vs Hybrid） | 整體目錄結構 | ADR-0001（Proposed） |
| Runtime 策略（Event-driven vs Always-on vs Hybrid） | Platform Core 的部署模型 | 待建立 |
| 主要儲存後端（SQLite / Notion / Postgres） | Knowledge Manager、Memory Manager | OQ-03 |
| Runtime 語言（Node.js vs Bun） | 所有 packages | OQ（ADR-0002 Open Questions） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 0.9 | 2026-06-27 | 初稿，待 ADR-0001 與 Runtime Strategy 確認後升為 1.0 |
