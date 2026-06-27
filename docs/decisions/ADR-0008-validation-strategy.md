---
doc_type: adr
doc_id: ADR-0008
title: Validation Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0003, ADR-0009]
tags: [validation, quality, ai-reliability]
---

# ADR-0008: Validation Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 的決策（通知、知識更新、Workflow 觸發）高度依賴 AI 的分析結果。AI 會產生幻覺（hallucination）、錯誤推論、過度自信。

如果 AI 的輸出未經驗證就直接作為行動依據，系統的可靠性會不斷下降，使用者的信任也會流失。

---

## 決策（Decision）

**所有 AI 輸出在被用於決策前，必須通過至少一層驗證。驗證層級依「錯誤代價」而定：代價越高，驗證越嚴格。**

---

## 驗證層級模型

### 層級 1：Auto-validate（自動驗證）

適用於低風險、高頻率的 AI 輸出（如新聞摘要、商品分類）。

驗證方式：
- **Schema 驗證**：輸出符合預期的 JSON 結構
- **信心度過濾**：`confidence < 0.7` 的輸出降級或棄用
- **一致性檢查**：與已知知識庫比對，明顯矛盾的輸出標記為 `needs_review`

---

### 層級 2：Cross-validate（交叉驗證）

適用於中風險輸出（如優先級評分、知識建議）。

驗證方式：
- **多次呼叫取共識**：同一問題呼叫 AI 2–3 次，取多數答案或平均值
- **不同 Provider 驗證**：用 Claude 分析，再用 OpenAI 驗證關鍵結論
- **規則交叉驗證**：AI 評分與規則型系統評分比對，差異超過閾值則標記

---

### 層級 3：Human-validate（人工驗證）

適用於高風險輸出（如核心知識修改、高優先通知決策）。

驗證方式：
- AI 產生輸出 + 理由
- 系統通知使用者審核
- 使用者確認後才正式生效
- 使用者否決的輸出記入「否決紀錄」，作為後續訓練訊號

---

## 錯誤代價 vs 驗證層級對照表

| 輸出類型 | 錯誤代價 | 驗證層級 |
|---|---|---|
| 新聞摘要 | 低（最多讀到錯誤資訊） | L1 Auto |
| 商品分類 | 低 | L1 Auto |
| 優先級評分 | 中（通知錯誤事項） | L2 Cross |
| 新增知識建議 | 中-高（可能影響後續決策） | L2–L3 |
| 修改現有知識 | 高 | L3 Human |
| 觸發執行型 Workflow | 高 | L3 Human |

---

## 驗證結果記錄

每次驗證的結果都記入 `ValidationLog`：

```
ValidationLog {
  id: string
  output_id: string            # 被驗證的 AI 輸出
  validation_level: L1 | L2 | L3
  result: pass | fail | needs_review | human_rejected
  reason: string
  timestamp: datetime
}
```

---

## 後果（Consequences）

### 正面影響
- 系統可靠性隨使用時間提升（否決紀錄累積學習訊號）
- 使用者建立對系統的信任

### 負面影響（需接受的取捨）
- L2 Cross-validate 增加 AI API 呼叫成本（2–3 倍）
- L3 Human-validate 增加使用者確認步驟的摩擦

---

## 實施原則

1. 每個 AI 呼叫的輸出必須標記預期的驗證層級（由 Workflow 定義）
2. L2 Cross-validate 在 API 成本敏感時，可降級為「單次呼叫 + 規則交叉」
3. 所有 `human_rejected` 的記錄定期彙整，用於調整 AI Prompt 或知識庫

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | L2 交叉驗證的「共識閾值」應設為多少？（例如 2/3 多數） | Open |
| 2 | ValidationLog 是否對使用者可視？（Dashboard 功能） | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
