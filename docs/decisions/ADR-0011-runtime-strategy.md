---
doc_type: adr
doc_id: ADR-0011
title: Runtime Strategy
status: proposed
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0001, ADR-0002, ADR-0005, ADR-0007]
tags: [runtime, architecture, process, worker]
---

# ADR-0011: Runtime Strategy

## 狀態

`Proposed`（等待確認後改為 Accepted）

## 背景（Context）

PAOS 的工作負載性質截然不同：
- **即時響應型**：Telegram 訊息必須在幾秒內回覆
- **持續監控型**：股票、二手商品需要每 N 分鐘輪詢一次
- **排程執行型**：每日摘要在固定時間觸發
- **耗時計算型**：複雜的 AI 分析 Workflow 可能需要數分鐘

單一的 Runtime 策略無法同時滿足「低延遲即時響應」與「長時間後台計算」的需求。

---

## 工作負載分析

| 工作負載 | 類型 | 持續時間 | 延遲要求 | 崩潰影響 |
|---|---|---|---|---|
| Telegram 訊息處理 | 事件驅動 | < 10 秒 | 低延遲（< 3s） | 嚴重 |
| 排程任務（每日摘要） | 排程觸發 | 1–5 分鐘 | 無（定時執行） | 中（可重跑） |
| 長期監控（股票 / 二手商品） | 持續輪詢 | 永久 | 無嚴格要求 | 中（可重啟） |
| Dashboard 請求 | 事件驅動 | < 5 秒 | 低延遲 | 低 |
| Notification 推送 | 事件驅動 | < 1 秒 | 低延遲 | 中 |
| 複雜 AI Workflow | 後台計算 | 1–10 分鐘 | 無 | 低（可重跑） |

---

## 考慮的選項

### 選項 A：Event-driven Only（純事件驅動）

所有功能無狀態，被呼叫才執行，執行完即結束。

**優點**：資源佔用低、部署簡單  
**缺點**：
- Telegram Polling 根本無法實現（需要常駐進程）
- 長期監控需要外部 cron，管理複雜度線性增長
- 每次啟動需要重新載入 Memory，對話連貫性差  

**對 AI Agent 的影響**：差。每次呼叫冷啟動，Context 需要重新組裝，延遲高。  
**結論**：❌ 不適合 PAOS

---

### 選項 B：Always-on Monolith（整個系統常駐單一進程）

所有功能（Polling、監控、Workflow 執行、對話處理）在同一個進程中運行。

**優點**：架構最簡單、Working Memory 可在記憶體中維持  
**缺點**：
- 單點故障：一個長時間 Workflow 可以阻塞整個 Event Loop
- 難以水平擴展（未來 V3 SaaS 需要多 instance）
- 記憶體用量隨功能增加難以控制  

**對 AI Agent 的影響**：尚可。Session 連貫但多個並行 AI 呼叫時資源競爭明顯。  
**結論**：⚠️ V1 勉強可行，中長期不適合

---

### 選項 C：Hybrid（常駐核心 + 任務型 Worker）

```
┌────────────────────────────────────────────────┐
│            PAOS Core Process（常駐）             │
│                                                │
│  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Event Loop   │  │  Scheduler           │   │
│  │ - TG Polling │  │  - 監控任務排程        │   │
│  │ - Webhook    │  │  - 每日摘要排程        │   │
│  └──────────────┘  └──────────────────────┘   │
│                                                │
│  ┌──────────────────────────────────────────┐  │
│  │        Session Manager（Working Memory） │  │
│  └──────────────────────────────────────────┘  │
│                                                │
│  ┌──────────────────────────────────────────┐  │
│  │           Worker Pool Manager            │  │
│  └──────────┬─────────────────────┬─────────┘  │
└─────────────│─────────────────────│────────────┘
              │ 派發任務              │
    ┌─────────▼──────────┐ ┌────────▼────────────┐
    │  Workflow Worker   │ │  Monitor Worker      │
    │  (短期，完成即退出) │ │  (長期，持續輪詢)    │
    │  - AI 分析         │ │  - 股票價格          │
    │  - 複雜 Workflow   │ │  - 二手商品          │
    └────────────────────┘ └─────────────────────┘
```

**優點**：
- Core Process 輕量，只做調度和狀態管理，延遲低
- Worker 崩潰不影響 Core Process（隔離故障）
- 未來可以把 Worker 升級為真正的分散式 Worker（BullMQ + Redis）

**缺點**：
- 比 Monolith 複雜，Core 與 Worker 需要通訊機制
- 需要 Worker 生命週期管理

**對 AI Agent 的影響**：最好。Core 維持對話連貫性，AI 分析 Worker 獨立隔離，互不干擾。  
**結論**：✅ 最推薦

---

## 各工作負載的最佳運行位置

| 工作負載 | 運行位置 | 原因 |
|---|---|---|
| Telegram Polling / Webhook | Core（常駐） | 必須持續運行 |
| 對話 Session 管理 | Core（常駐） | Working Memory 需要跨請求保持 |
| Notification 推送 | Core（常駐） | 低延遲、輕量 |
| 監控任務排程器 | Core（常駐） | 調度器只需要發出任務，不執行 |
| 股票 / 商品監控（輪詢） | Monitor Worker（長期） | 與 Core 隔離，崩潰可重啟 |
| AI 分析 / 複雜 Workflow | Workflow Worker（短期） | 完成就退出，不佔用 Core 資源 |
| Dashboard API 請求 | Workflow Worker（短期） | 按需啟動，低流量時不佔資源 |

---

## 決策（Decision）

**建議採用選項 C：Hybrid Runtime（常駐 Core + 任務型 Worker）。**

V1 實作策略（簡化版）：
- V1 可以用**同一個進程內的 async 並發**模擬 Hybrid（不需要真正的多進程）
- 設計上嚴格分離 Core 邏輯與 Worker 邏輯，確保未來可以真正拆分
- V2 再引入真正的多進程或 Message Queue

---

## 決策依據（Rationale）

1. **Telegram Polling 的硬性需求**：Core 必須常駐，沒有妥協空間
2. **故障隔離**：長時間 AI Workflow 不應該影響 Telegram 的即時回覆
3. **五年可擴充**：Hybrid 的 Worker 模式在未來可以直接升級為分散式架構（BullMQ、Temporal），不需要重寫
4. **V1 漸進實作**：不需要第一天就做完整的多進程，用 async/await 在單進程內先分層

---

## 後果（Consequences）

### 正面影響
- Core Process 的 Event Loop 不被長時間任務阻塞
- 任何 Worker 崩潰都可以獨立重啟，不影響 Telegram 服務
- 架構路徑清晰：V1 單進程 → V2 多進程 → V3 分散式

### 負面影響（需接受的取捨）
- 比 Monolith 增加一層設計複雜度
- V1 的「假 Hybrid」（單進程 async）需要嚴格的代碼紀律，確保不違反分層

### 風險與緩解措施

| 風險 | 緩解措施 |
|---|---|
| V1 單進程模擬 Hybrid，代碼紀律不夠，退化為 Monolith | 用 ADR + Code Review 確保 Core / Worker 分層界線 |
| Worker 崩潰後任務遺失 | V1 任務持久化到儲存（即使是 SQLite），崩潰後可重跑 |

---

## V1 實作路徑

```
V1（單進程 async）
  Core Module：負責 Telegram Polling、Session 管理、任務派發
  Worker Module：負責執行 Workflow（async function，在同一進程內）
  分離邊界：Core 不直接執行 AI 呼叫，只透過 Worker Interface 派發

V2（多進程）
  Core Process：不變
  Worker Process：用 Node.js worker_threads 或 child_process 真正分離

V3（分散式）
  Message Queue（BullMQ / Redis）替換 Worker Interface
  Worker 可以水平擴展到多台機器
```

---

## 實施原則

1. Core 模組不得包含任何 AI 呼叫（AI 呼叫只在 Worker 中）
2. Core 模組的每個任務處理必須在 100ms 內完成（或立即派發給 Worker）
3. Worker 必須設計為**冪等（idempotent）**：同一任務跑兩次結果相同（支援重試）
4. 所有 Worker 的執行結果必須持久化，Core 可以查詢任意 Worker 的狀態

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | V1 的 Worker 通訊機制：同進程 async 還是 worker_threads？ | Open（建議：先用 async） |
| 2 | Monitor Worker 的輪詢間隔如何設定？（全域 vs 每個 Domain 獨立設定） | Open |
| 3 | Worker 任務的持久化後端：記憶體佇列還是 SQLite？ | Open（建議：SQLite，確保重啟不遺失） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，深度分析三個選項並提出 Hybrid 建議 |
