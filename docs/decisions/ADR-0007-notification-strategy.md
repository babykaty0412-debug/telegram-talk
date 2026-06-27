---
doc_type: adr
doc_id: ADR-0007
title: Notification Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0005, ADR-0008]
tags: [notification, priority, ux]
---

# ADR-0007: Notification Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 會持續監控多個資訊來源（股票、二手商品、AI 新聞等）。如果每一個事件都推送通知，使用者很快就會通知疲乏（Alert Fatigue），開始忽略所有通知。

通知策略必須回答：**什麼事情值得打擾使用者？什麼時候？用什麼方式？**

---

## 決策（Decision）

**採用四層優先級模型，每層對應不同的交付策略。Priority Engine（見 Vision Scope）決定每個事件的優先級，Notification Strategy 決定如何交付。**

---

## 四層優先級模型

| 層級 | 名稱 | 觸發條件範例 | 交付方式 | 時機 |
|---|---|---|---|---|
| P0 | Critical | 股票觸及停損、系統錯誤、安全警告 | 立即推送（所有管道） | 任何時間 |
| P1 | High | 高分二手商品出現、重要新聞突發 | 立即推送（主要管道） | 任何時間 |
| P2 | Medium | 每日摘要、達到關注條件 | 批次推送（排程） | 依使用者排程 |
| P3 | Low | 一般資訊更新、系統日誌 | 記錄於 Dashboard | 使用者主動查看 |

---

## 批次推送策略（P2）

P2 通知不立即推送，而是累積後在排程時間統一發送：

**預設排程（可使用者設定）**：
- 早晨摘要：08:00
- 傍晚摘要：18:00

**批次內容格式**：
```
【PAOS 每日摘要 - 08:00】

🔴 高優先 (3)
• 某某書低於門檻價 $120，目前 $95
• 某某股票達到買入觀察點

🟡 一般 (12)
• AI 新聞摘要（3 則）
• 市場每日概覽

→ 查看完整清單：[Dashboard 連結]
```

---

## 通知管道優先順序（可設定）

| 情境 | 管道優先順序 |
|---|---|
| P0 Critical | Telegram > SMS（未來）> Email |
| P1 High | Telegram |
| P2 Medium | Telegram（批次）|
| P3 Low | Dashboard only |

---

## 通知疲乏防護機制

1. **靜音模式**：使用者可設定時間段（如 23:00–08:00）不接收 P1 以下的通知
2. **頻率限制**：同一來源同一類型的通知，同一天最多推送 N 次
3. **降級機制**：若使用者連續 3 天未互動 P2 通知，自動降為 Dashboard only
4. **緊急覆蓋**：P0 永遠不受靜音模式限制

---

## 後果（Consequences）

### 正面影響
- 使用者只在真正重要時被打擾
- 批次摘要比單條推送更易於消化

### 負面影響（需接受的取捨）
- P2 的「重要性」判斷依賴 Priority Engine，需要持續調校

---

## 實施原則

1. Notification 模組不直接決定優先級——它接受已分好優先級的事件，只負責交付
2. 優先級由 Priority Engine（ADR-0008 的 Validation + Domain 規則）決定
3. 所有已發送的通知記錄在日誌中（可查詢、可審計）
4. 使用者可以對任何通知回饋「太頻繁」或「重要」，作為 Priority Engine 的學習訊號

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | 批次摘要的格式是純文字還是帶結構的 Rich Message？ | Open |
| 2 | 使用者如何設定靜音時間？（Telegram 指令、Dashboard、設定檔？） | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
