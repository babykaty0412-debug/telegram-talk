---
doc_type: adr
doc_id: ADR-0012
title: Execution Model
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0011, ADR-0005, ADR-0014]
tags: [execution, trigger, workflow, scheduling]
---

# ADR-0012: Execution Model

## 狀態

`Accepted`（自 2026-06-27）

## 背景（Context）

ADR-0011 定義的是系統如何「持續運行」（Process Architecture）。但它沒有定義：**一個任務是如何被觸發執行的？**

這是不同的關注點：

| 關注點 | 負責的 ADR |
|---|---|
| 系統進程架構（常駐 Core、Worker 隔離） | ADR-0011 Runtime Strategy |
| **任務的觸發方式** | **本文件 ADR-0012 Execution Model** |
| 模組之間如何通訊 | ADR-0014 Communication Strategy |

PAOS 的任務有六種觸發方式，每種方式有不同的行為模式、延遲要求與錯誤處理機制。如果沒有統一的 Execution Model，每個 Domain 和 Workflow 都會發明自己的觸發邏輯，造成不一致。

---

## 六種 Execution Trigger

### Trigger 1：Scheduled（排程觸發）

**描述**：按時間表自動觸發，不需人工介入。  
**觸發機制**：Scheduler Layer 的 cron job 發出事件  
**範例**：每天 08:00 執行「晨報摘要」；每 5 分鐘檢查股票價格  

```
Scheduler.cron('0 8 * * *')
  → eventBus.dispatch('workflow.execute', { id: 'daily-digest' })
```

**特性**：
- 延遲容忍度：高（幾分鐘誤差可接受）
- 錯誤處理：失敗後重試 N 次，超過次數發出 P1 通知
- 並發：同一個排程任務，同一時間只允許一個 instance 執行

---

### Trigger 2：Manual（手動觸發）

**描述**：使用者明確發出指令觸發，例如透過 Telegram 傳送指令。  
**觸發機制**：Channel Adapter 解析使用者訊息，識別為指令，發出事件  
**範例**：使用者傳送「/summary」→ 觸發摘要 Workflow  

```
// Channel Adapter 解析到指令
eventBus.dispatch('workflow.execute', {
  id: 'on-demand-summary',
  triggeredBy: 'user',
  context: currentSession
})
```

**特性**：
- 延遲容忍度：低（使用者在等待，< 30s 要有初步回應）
- 錯誤處理：立即通知使用者失敗原因
- 並發：使用者可以觸發多個，但需要防止重複觸發同一個長時間任務

---

### Trigger 3：Webhook（外部 HTTP 觸發）

**描述**：外部系統透過 HTTP 呼叫 PAOS API，觸發特定 Workflow。  
**觸發機制**：API Server 接收請求，驗證來源，發出事件  
**範例**：GitHub 推送 PR → PAOS 分析程式碼差異；未來 n8n 呼叫 PAOS  

```
// API Layer 接收請求
POST /webhook/github
  → 驗證 signature
  → eventBus.dispatch('workflow.execute', { id: 'analyze-pr', payload: req.body })
```

**特性**：
- 延遲容忍度：中（通常是異步，可以立即回 202 Accepted）
- 錯誤處理：回傳 HTTP 錯誤碼；必要時通知使用者
- 安全：必須驗證 webhook 來源（signature / token）

---

### Trigger 4：Event（內部事件觸發）

**描述**：PAOS 內部的一個動作完成後，自動觸發另一個 Workflow。  
**觸發機制**：Event Bus 的事件鏈  
**範例**：Collector 收集到新的二手商品數據 → 自動觸發 Parser → 自動觸發 Analyzer  

```
// Collector 完成
eventBus.emit('data.collected', { domain: 'secondhand', count: 50 })

// Parser 訂閱並自動觸發
eventBus.on('data.collected', (e) => {
  eventBus.dispatch('workflow.execute', { id: 'parse-data', payload: e })
})
```

**特性**：
- 延遲容忍度：中（Pipeline 各步驟自動接續，允許幾秒鐘的間隔）
- 錯誤處理：單個步驟失敗不影響其他 Pipeline；失敗步驟記入日誌

---

### Trigger 5：AI-initiated（AI 主動觸發）

**描述**：AI 分析當前狀況後，主動決定啟動某個 Workflow，不需要人工指令。  
**觸發機制**：Analyzer Worker 的輸出觸發後續行動  
**範例**：AI 分析股市後，自主觸發「市場異常警示 Workflow」  

```
// Analyzer 判斷觸發條件
if (analysis.marketAnomaly > threshold) {
  eventBus.dispatch('workflow.execute', {
    id: 'market-alert',
    reason: analysis.summary,
    confidence: analysis.confidence
  })
}
```

**特性**：
- 延遲容忍度：依情境（市場異常需要即時；一般分析可以批次）
- **限制**：AI-initiated 觸發只允許 P-W 層以下的操作（見 ADR-0009）；高風險操作需要人工確認
- 錯誤處理：AI 觸發的 Workflow 失敗記入 Audit Log

---

### Trigger 6：API（程式化觸發）

**描述**：外部程式或整合工具透過 PAOS 的 REST API 程式化觸發任務。  
**觸發機制**：API Server 驗證呼叫者身份，轉換為 eventBus 事件  
**範例**：Zapier、Make.com、或自訂腳本呼叫 PAOS API  

**特性**：
- 延遲容忍度：視呼叫方需求（同步 or 異步）
- 安全：需要 API Key 驗證；每個呼叫記入 Audit Log
- 限制：API 呼叫者只能觸發「已允許的 Workflow」，不能任意執行命令

---

## Trigger 對照表

| Trigger | 觸發者 | 延遲要求 | 是否需要驗證 | 並發限制 |
|---|---|---|---|---|
| Scheduled | Scheduler（自動） | 低（容忍分鐘誤差） | — | 同任務單 instance |
| Manual | 使用者 | 高（< 30s 初步回應） | 使用者身份 | 防重複觸發 |
| Webhook | 外部系統 | 中（202 Accepted）| Signature/Token | — |
| Event | 內部事件 | 中（自動 Pipeline）| — | 依 Workflow 設定 |
| AI-initiated | AI | 依情境 | — | 受 Permission 模型限制 |
| API | 外部程式 | 依呼叫方 | API Key | 速率限制 |

---

## 決策（Decision）

**PAOS 採用六種 Execution Trigger，每種 Trigger 有明確的行為規範。所有 Trigger 都必須透過 Event Bus 轉換為統一的 `workflow.execute` 事件，不允許直接呼叫 Workflow 函數。**

---

## 實施原則

1. 所有 Trigger 在進入 Event Bus 前必須完成驗證（身份、簽名、權限）
2. 每次 Trigger 都產生一個唯一的 `taskId`，用於追蹤執行狀態
3. `taskId` 進入 Audit Log，確保每次執行可追溯（見 ADR-0009）
4. AI-initiated Trigger 必須附上 `reason` 和 `confidence`，記入 Audit Log
5. Scheduled 和 Event Trigger 的失敗必須有重試機制，Manual 和 API 的失敗立即通知呼叫方

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | 是否需要 Trigger 的 rate limiting（例如 AI-initiated 每小時最多觸發 N 次）？ | Open |
| 2 | API Trigger 的 API Key 管理策略？ | Open（V2 再設計） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，定義六種 Execution Trigger |
