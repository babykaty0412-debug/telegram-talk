---
doc_type: adr
doc_id: ADR-0006
title: Memory Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0004]
tags: [memory, context, retention]
---

# ADR-0006: Memory Strategy

## 狀態

`Accepted`

## 背景（Context）

AI 的有效運作依賴「記憶」——但不同性質的記憶有不同的生命週期與存取模式。如果把所有記憶都堆在一起，AI 的 context window 很快就會爆滿，且重要資訊會被噪音淹沒。

此外，「記憶」與「知識」（ADR-0004）必須明確區分：
- **Memory**：情境相關，隨時間衰減，屬於使用者的個人情境
- **Knowledge**：領域正確，需要明確管理版本，屬於可分享的客觀資訊

---

## 決策（Decision）

**採用三層記憶模型（Working → Short-term → Long-term），每層有不同的生命週期、存取策略與資料格式。**

---

## 三層記憶模型

### Layer 1：Working Memory（工作記憶）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 當前 Session（對話結束即消失） |
| 內容 | 當前對話的上下文、正在處理的任務、暫時的計算結果 |
| 存取方式 | 直接放在 AI Context Window 中 |
| 容量限制 | AI 的 context window 上限 |

**用途**：「你剛才說的那本書」、「這個對話目前分析到哪裡了」

---

### Layer 2：Short-term Memory（短期記憶）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 數天至數週，自動過期 |
| 內容 | 最近的對話摘要、近期提到的任務、臨時觀察 |
| 存取方式 | 新對話開始時，依相關性注入 context |
| 儲存格式 | 結構化摘要（JSON）+ 時間戳記 |
| 過期機制 | TTL（Time-to-live），超過 N 天自動 archive |

**用途**：「上週你在追蹤某支股票」、「你前幾天提到想整理書單」

---

### Layer 3：Long-term Memory（長期記憶）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 永久，直到明確刪除或更新 |
| 內容 | 使用者偏好、長期目標、重要決定、個人背景資訊 |
| 存取方式 | 以語意搜尋（Embedding）檢索，按相關性注入 context |
| 儲存格式 | 向量資料庫 + 原始文字 |
| 更新機制 | AI 提議更新，需人工確認（核心記憶），或自動更新（低風險偏好） |

**用途**：「你對股票的風險偏好是保守型」、「你通常在晚上 10 點後才看通知」

---

## 記憶注入策略（Context Assembly）

每次 AI 被呼叫時，依以下順序組合 context：

```
1. System Prompt（固定指示）
2. Long-term Memory（相關性 > 閾值的項目）
3. Short-term Memory（最近 N 天的摘要）
4. Working Memory（當前對話歷史）
5. 當前 Query
```

總 token 超過上限時，優先截斷 Short-term，其次是 Long-term 低相關性項目。

---

## 後果（Consequences）

### 正面影響
- AI 的 context 維持高相關性，不被無關記憶佔滿
- 分層管理讓記憶的生命週期清晰可控

### 負面影響（需接受的取捨）
- 需要實作 context assembly 邏輯
- Long-term Memory 需要 Embedding 支援（見 ADR-0003）

---

## 實施原則

1. Working Memory 永遠優先，不可被截斷
2. Long-term Memory 的更新必須有明確的觸發條件，不能被 AI 隨意修改
3. Short-term Memory 過期後移入 archive，不直接刪除（保留可查詢性）
4. Memory 與 Knowledge 嚴格分層：使用者偏好屬於 Memory，領域規則屬於 Knowledge

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | Long-term Memory 的 Embedding 選擇哪個 Provider？（見 ADR-0003） | Open |
| 2 | Short-term Memory 的 TTL 預設值？（建議：7–30 天） | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，定義三層記憶模型 |
