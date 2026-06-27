---
doc_type: adr
doc_id: ADR-0014
title: Communication Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0011, ADR-0012, ADR-0003]
tags: [communication, event-bus, agent, decoupling]
---

# ADR-0014: Communication Strategy

## 狀態

`Accepted`（自 2026-06-27）

## 背景（Context）

PAOS 由多個模組組成：Core、Scheduler、Memory、Knowledge、Worker（Collector、Parser、Analyzer）、Channel Adapters。

如果這些模組可以任意互相呼叫，系統很快就會退化為難以維護的「義大利麵架構（Spaghetti Architecture）」：修改任何一個模組，都需要追蹤它影響了哪些其他模組。

本 ADR 定義：**模組之間只能用哪幾種方式通訊，以及哪些方式是明確禁止的。**

---

## 核心原則

**模組之間不允許直接呼叫。所有通訊透過以下四種合法模式之一進行。**

---

## 四種合法通訊模式

### 模式 1：Event Bus（非同步，fire-and-forget）

**用途**：一個模組完成某件事，廣播給所有關心的模組。  
**特性**：發布者不等待訂閱者的回應。  
**適用情境**：狀態改變通知、Pipeline 中的階段完成事件

```
// ✅ Collector 完成後廣播事件
eventBus.emit('data.collected', {
  domain: 'stocks',
  taskId: 'abc-123',
  recordCount: 50
})

// ✅ Parser 訂閱並處理（與 Collector 解耦）
eventBus.on('data.collected', async (payload) => {
  await parseData(payload)
  eventBus.emit('data.parsed', { taskId: payload.taskId })
})
```

**禁止**：
- 在 `emit` 之後立即 `await` 回傳值（這就變成同步呼叫，失去解耦效果）

---

### 模式 2：Task Queue（非同步，有結果回傳）

**用途**：Core 或 Scheduler 派發任務給 Worker 執行，並在稍後查詢結果。  
**特性**：發布者派發後不阻塞；Worker 執行完成後將結果寫入 Task Queue。  
**適用情境**：Core 派發 AI 分析任務、Scheduler 觸發定時 Workflow

```
// ✅ Core 派發任務（不等待結果）
const taskId = await taskQueue.enqueue({
  type: 'analyze',
  domain: 'secondhand',
  payload: { items: [...] }
})

// ✅ Core 稍後查詢結果（輪詢或事件通知）
const result = await taskQueue.getResult(taskId)
```

**禁止**：
- 在 `enqueue` 後立即等待執行完成（應改用 Event Bus 通知結果）

---

### 模式 3：Context Object（同步，同一請求鏈內）

**用途**：同一個請求處理過程中，在函數之間傳遞共用狀態。  
**特性**：同步傳遞，只在同一個執行鏈內有效，不跨越模組邊界。  
**適用情境**：一次 AI 呼叫的 Context Assembly；一次 Workflow 執行的中間狀態

```
// ✅ Context 在同一個執行鏈內傳遞
async function handleUserMessage(message) {
  const ctx = {
    sessionId: message.sessionId,
    workingMemory: await memory.getWorking(message.sessionId),
    longTermContext: await memory.recall(message.content)
  }
  const response = await aiProvider.complete(message.content, ctx)
  await memory.updateWorking(ctx.sessionId, response)
  return response
}
```

**禁止**：
- 將 Context 存入全域變數或共用 Singleton（這會導致並發請求互相汙染）

---

### 模式 4：Repository Query（同步，唯讀查詢）

**用途**：任何模組查詢持久化資料（Knowledge、Memory、Task 狀態）。  
**特性**：只讀，無副作用；透過 Repository 介面，不直接執行 SQL。  
**適用情境**：Worker 查詢知識庫、Core 查詢任務狀態

```
// ✅ 透過 Repository 查詢（不直接寫 SQL）
const rules = await knowledgeRepo.findByDomain('secondhand')
const task = await taskRepo.findById(taskId)
```

**禁止**：
- 在 Repository Query 中執行寫入操作（違反「唯讀查詢無副作用」原則）

---

## 禁止的通訊模式

以下模式是明確禁止的：

| 反模式 | 原因 | 替代方案 |
|---|---|---|
| `moduleA.callModuleB()` 直接呼叫 | 造成緊耦合，修改 A 必須同時改 B | Event Bus 或 Task Queue |
| 共用可變全域狀態 | 並發請求互相汙染 | Context Object（請求級別）或 Repository（持久化） |
| Worker 直接呼叫另一個 Worker | Worker 應各自獨立，透過 Event Bus 協調 | `eventBus.emit()` |
| 直接 `import` 並呼叫其他 Layer 的函數 | 繞過 Event Bus，無法追蹤執行流程 | 只允許 `import` Repository 介面和 Event Bus |
| AI Provider 直接從業務邏輯呼叫 | 違反 ADR-0003 Provider 抽象 | 透過 `aiProvider.complete()` 介面 |

---

## 通訊模式選擇指南

```
有回傳結果嗎？
├── 否 → 用 Event Bus（emit/on）
└── 是 → 需要立即結果嗎？
         ├── 是，且在同一請求鏈內 → 用 Context Object（函數呼叫）
         ├── 是，且是查詢持久化資料 → 用 Repository Query
         └── 否，允許異步等待 → 用 Task Queue（enqueue + poll）
```

---

## 邊界定義：模組可以 import 什麼

| 模組 | 允許 import | 禁止 import |
|---|---|---|
| Core | Event Bus、Memory Repository、Task Repository | 任何 Worker、任何 Domain 模組 |
| Scheduler | Event Bus、Task Repository | Core、Worker |
| Worker（Collector/Parser/Analyzer） | Event Bus、Knowledge Repository、AI Provider 介面 | 其他 Worker、Core |
| Channel Adapter | Event Bus、Core 的訊息介面 | Worker、Memory、Knowledge（直接） |
| Domain Module | Knowledge Repository、Event Bus | Core、其他 Domain |

---

## 決策（Decision）

**PAOS 只允許四種通訊模式：Event Bus、Task Queue、Context Object、Repository Query。禁止任何模組直接呼叫另一個模組的函數（除非透過以上四種模式之一）。**

---

## 後果（Consequences）

### 正面影響
- 模組之間的依賴關係清晰，修改任何模組只需要確認它的 Event 介面不變
- 分散式架構演進時（ADR-0011 V2/V3），Event Bus 替換為 Message Queue 不影響業務邏輯

### 負面影響（需接受的取捨）
- 開發者需要記住「不能直接呼叫」的規則——這是一個需要持續強制的紀律
- 偵錯時，執行流程不像直接呼叫那麼直觀

### 風險與緩解措施

| 風險 | 緩解措施 |
|---|---|
| 開發者繞過 Event Bus 直接 import | Linter 規則（禁止跨層 import）；Code Review |
| Event Bus 事件名稱不一致（typo） | 使用常數定義所有事件名稱（`EVENTS.DATA_COLLECTED`） |

---

## 實施原則

1. 所有 Event Bus 的事件名稱定義為常數，存放在 `packages/core/events.ts`
2. 每個 Worker 只訂閱它負責的事件，不訂閱與自己無關的事件
3. Task Queue 的任務類型也定義為常數
4. 禁止在 Channel Adapter 中直接存取 Memory 或 Knowledge——必須透過 Core 的事件介面

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | Event Bus 的錯誤事件（`error.*`）如何統一處理？ | Open |
| 2 | 是否需要 Event Bus 的 Dead Letter Queue（處理失敗的事件）？ | Open（V2） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，定義四種合法通訊模式與禁止模式 |
