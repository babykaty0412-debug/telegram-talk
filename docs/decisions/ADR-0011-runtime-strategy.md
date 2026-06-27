---
doc_type: adr
doc_id: ADR-0011
title: Runtime Strategy
status: accepted
version: "2.0"
date: 2026-06-27
supersedes: []
related: [ADR-0001, ADR-0002, ADR-0005, ADR-0007, ADR-0012, ADR-0014]
tags: [runtime, architecture, process, worker, event-bus]
---

# ADR-0011: Runtime Strategy

## 狀態

`Accepted`（自 2026-06-27）

## 背景（Context）

PAOS 的工作負載性質截然不同：
- **即時響應型**：Telegram 訊息必須在幾秒內回覆
- **持續監控型**：股票、二手商品需要每 N 分鐘輪詢一次
- **排程執行型**：每日摘要在固定時間觸發
- **耗時計算型**：複雜的 AI 分析 Workflow 可能需要數分鐘

單一的 Runtime 策略無法同時滿足「低延遲即時響應」與「長時間後台計算」的需求。

> **注意**：Runtime Strategy 定義的是「系統如何運行（Process Architecture）」。  
> 「任務如何被觸發」是 Execution Model（ADR-0012）的責任；「模組如何通訊」是 Communication Strategy（ADR-0014）的責任。

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
**缺點**：Telegram Polling 無法實現；長期監控需外部 cron；Memory 每次需重新載入  
**結論**：❌ 不適合 PAOS

---

### 選項 B：Always-on Monolith（整個系統常駐單一進程）

所有功能在同一個進程中運行。

**優點**：架構最簡單；Working Memory 可在記憶體中維持  
**缺點**：單點故障；長時間 Workflow 阻塞 Event Loop；難以水平擴展  
**結論**：⚠️ V1 勉強可行，中長期不適合

---

### 選項 C：Hybrid（常駐 Core + Event Bus + 任務型 Worker）

Core Process 常駐，負責輕量調度；Worker 負責耗時任務；所有通訊透過 Event Bus。

**結論**：✅ 最推薦

---

## Runtime Layer Architecture

PAOS 的 Runtime 採用分層架構。每層有明確的職責邊界：

```
┌──────────────────────────────────────────────────────┐
│                   Runtime Layer                       │
│  （系統進程的整體邊界，V1 為單進程，V2+ 可分散）        │
├──────────────────────────────────────────────────────┤
│                    Core Layer                         │
│  常駐。接收外部事件（TG Polling、Webhook）、管理 Session │
├──────────────────────────────────────────────────────┤
│                  Scheduler Layer                      │
│  常駐。管理排程任務（cron）、監控任務週期、任務優先佇列  │
├──────────────────────────────────────────────────────┤
│                  Memory Layer                         │
│  常駐。管理 Working / Short-term / Long-term Memory    │
│  提供 Context Assembly，不直接暴露給 Worker            │
├──────────────────────────────────────────────────────┤
│                 Knowledge Layer                       │
│  常駐。提供知識查詢介面，管理知識版本與審核管線          │
├──────────────────────────────────────────────────────┤
│                   Event Bus                           │
│  核心通訊樞紐。所有跨層通訊都經過 Event Bus             │
│  Core / Scheduler 派發任務 → Event Bus → Worker        │
│  Worker 完成 → Event Bus → Core / Notification        │
├──────────────────────────────────────────────────────┤
│                  Worker Layer                         │
│  短期或長期任務執行。不直接呼叫其他 Worker              │
├────────────────┬────────────────┬────────────────────┤
│  Collector     │    Parser      │    Analyzer         │
│  收集外部資料   │  解析原始資料   │  AI 分析 / 摘要      │
└────────────────┴────────────────┴────────────────────┘
```

### 各層職責

| 層次 | 職責 | 常駐？ | 可獨立擴展？ |
|---|---|---|---|
| Core | 外部事件接收、Session 管理 | ✅ 是 | — |
| Scheduler | 排程管理、任務優先佇列 | ✅ 是 | V3+ |
| Memory | Context Assembly、記憶讀寫 | ✅ 是 | — |
| Knowledge | 知識查詢、審核管線 | ✅ 是 | — |
| Event Bus | 跨層通訊、任務路由 | ✅ 是 | V3+ |
| Collector | 外部資料收集 | 長期 Worker | ✅ |
| Parser | 原始資料解析 | 短期 Worker | ✅ |
| Analyzer | AI 分析、摘要 | 短期 Worker | ✅ |

---

## 核心設計原則：Architecture First, Implementation Later

**V1 可以用單進程實作，但所有 Interface 必須按分散式架構設計。**

這意味著：

```
// ❌ 不要這樣（緊耦合）
async function run() {
  await collector.run()   // 直接呼叫，架構無法拆分
  await parser.run()
}

// ✅ 要這樣（透過 Event Bus 派發）
eventBus.dispatch('task.collect', {
  domain: 'stocks',
  source: 'api',
  taskId: 'abc-123'
})

// Worker 訂閱並處理
eventBus.on('task.collect', async (payload) => {
  const data = await collectData(payload)
  eventBus.emit('task.collected', { taskId: payload.taskId, data })
})
```

即使 V1 在同一個進程內跑，`dispatch` 和 `on` 的語意也確保了未來可以將 Event Bus 替換為真正的 Message Queue（BullMQ、Redis Streams），不需要修改業務邏輯。

---

## 各工作負載的最佳運行位置

| 工作負載 | 層次 / 運行位置 | 原因 |
|---|---|---|
| Telegram Polling / Webhook | Core Layer（常駐） | 必須持續運行 |
| 對話 Session 管理 | Core + Memory Layer（常駐） | Working Memory 需要跨請求保持 |
| Notification 推送 | Core Layer（常駐） | 低延遲、輕量 |
| 監控任務排程 | Scheduler Layer（常駐） | 只需發出任務，不執行 |
| 股票 / 商品資料收集 | Collector Worker（長期） | 與 Core 隔離，崩潰可重啟 |
| 資料解析 | Parser Worker（短期） | 完成就退出 |
| AI 分析 / 複雜 Workflow | Analyzer Worker（短期） | 完成就退出，不佔用 Core 資源 |
| Dashboard API 請求 | 短期 Worker | 按需啟動 |

---

## 決策（Decision）

**採用選項 C：Hybrid Runtime（常駐 Core + Event Bus + 任務型 Worker）。**

- Core、Scheduler、Memory、Knowledge 層常駐
- 所有跨層通訊透過 Event Bus
- Collector、Parser、Analyzer 作為 Worker 執行
- V1 用單進程 async 實作，但 Interface 按分散式設計

---

## 決策依據（Rationale）

1. **Telegram Polling 的硬性需求**：Core 必須常駐，沒有妥協空間
2. **故障隔離**：Worker 崩潰不影響 Core 的即時回覆能力
3. **Event Bus 為通訊樞紐**：所有跨層呼叫都有明確的 dispatch/subscribe 語意，V2+ 可以替換為真正的 Message Queue
4. **Architecture First**：V1 用 async 模擬，但 Interface 設計不妥協——業務邏輯與 Runtime 實作完全解耦

---

## 後果（Consequences）

### 正面影響
- Core 的 Event Loop 不被長時間任務阻塞
- Worker 崩潰可獨立重啟，不影響 Telegram 服務
- Event Bus 設計讓未來替換 Runtime 不需要修改業務邏輯

### 負面影響（需接受的取捨）
- 比 Monolith 增加一層設計複雜度
- V1 的單進程需要嚴格的代碼紀律，確保不繞過 Event Bus 直接呼叫

### 風險與緩解措施

| 風險 | 緩解措施 |
|---|---|
| V1 繞過 Event Bus 直接呼叫，退化為 Monolith | ADR + Code Review 確保 dispatch/subscribe 模式 |
| Worker 崩潰後任務遺失 | 任務持久化到 SQLite，崩潰後可重跑（冪等設計）|

---

## 演進路徑

```
V1（單進程 async，Interface 按分散式設計）
  - 所有層在同一個進程內
  - Event Bus = 輕量 in-process EventEmitter
  - 任務持久化到 SQLite

V2（依部署需求演進為可分散式執行架構）
  - 不預設為「多進程」，而是依當時需求選擇：
    - Docker 容器化（隔離但仍可單機）
    - Worker Process（worker_threads / child_process）
    - Serverless（特定 Worker 卸載到 Cloud Functions）
  - Event Bus 可替換為 BullMQ / Redis Streams，業務邏輯不改

V3（Distributed / Cloud-native）
  - Kubernetes 或 Cloud Run
  - 多個 Worker instance 水平擴展
  - Event Bus = 分散式 Message Queue（Kafka / SQS）
```

---

## 實施原則

1. Core 模組不得包含任何 AI 呼叫（AI 呼叫只在 Worker 中）
2. 所有跨層呼叫必須透過 `eventBus.dispatch()` / `eventBus.on()`，禁止直接呼叫其他層的函數
3. Worker 必須設計為**冪等（idempotent）**：同一任務跑兩次結果相同
4. 所有 Worker 的執行狀態必須持久化，Core 可以查詢任意 Worker 的狀態

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | V1 的 Event Bus 實作：自建 EventEmitter 還是用輕量 library？ | Open（建議：自建 EventEmitter wrapper） |
| 2 | Monitor Worker 的輪詢間隔：全域設定還是每個 Domain 獨立？ | Open（見 ADR-0010 Domain Strategy） |
| 3 | Worker 任務的持久化後端 | Open（見 ADR-0013 Storage Strategy） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，深度分析三個選項並提出 Hybrid 建議 |
| 2.0 | 2026-06-27 | 新增 Runtime Layer Architecture（7 層）；加入 Event Bus 為通訊樞紐；「Architecture First, Implementation Later」原則；演進路徑改為「V2 Distributed-capable」（移除多進程的寫死假設）；狀態升為 Accepted |
