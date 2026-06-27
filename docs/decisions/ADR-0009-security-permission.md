---
doc_type: adr
doc_id: ADR-0009
title: Security & Permission Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0008]
tags: [security, permission, audit]
---

# ADR-0009: Security & Permission Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 的 AI Agent 有能力：收集資料、分析、更新知識庫、發送通知、觸發 Workflow。隨著 Domain 擴充，這些能力的範圍會持續增大。

如果沒有明確的權限模型，AI 可能在沒有預期的情況下修改重要資料、發送錯誤通知，甚至（在未來）執行金融操作。信任必須逐步建立，而非一開始就全部放開。

---

## 決策（Decision）

**採用四層權限模型（Read → Analyze → Write → Execute），每層能力的開放需要明確授權。所有 AI 行動記入 Audit Log，不可更改。**

---

## 四層權限模型

| 層級 | 名稱 | 包含的能力 | 預設狀態 |
|---|---|---|---|
| P-R | Read | 讀取資料、知識庫、記憶 | ✅ 預設允許 |
| P-A | Analyze | 執行 AI 分析、計算優先級、生成摘要 | ✅ 預設允許 |
| P-W | Write | 更新記憶（L2 Short-term）、建議知識更新、發送通知 | ✅ 預設允許（通知）、⚠️ 需確認（知識更新） |
| P-E | Execute | 修改核心知識、觸發外部 API、執行金融操作 | ❌ 預設禁止（需明確授權） |

---

## 具體行動的權限對照

| 行動 | 權限層 | V1 狀態 |
|---|---|---|
| 讀取知識庫 | P-R | ✅ 自動 |
| 讀取 Memory | P-R | ✅ 自動 |
| 分析股票資料 | P-A | ✅ 自動 |
| 生成摘要 | P-A | ✅ 自動 |
| 更新 Short-term Memory | P-W | ✅ 自動 |
| 更新 Long-term Memory | P-W | ⚠️ 需確認 |
| 發送通知（P0–P2） | P-W | ✅ 自動 |
| 新增知識（建議） | P-W | ⚠️ 通知使用者確認 |
| 修改現有知識 | P-E | ❌ 禁止（AI 只能建議，人工執行） |
| 刪除任何資料 | P-E | ❌ 永遠禁止（AI 不能刪除） |
| 呼叫外部 API（非讀取） | P-E | ❌ 需明確授權 |
| 自動下單 / 金融操作 | P-E | ❌ V1 完全禁止 |
| 自動發文到社群媒體 | P-E | ❌ V1 完全禁止 |

---

## Audit Log

所有 AI 行動（不論成功或失敗）都記入不可更改的 Audit Log：

```
AuditEntry {
  id: string
  timestamp: datetime
  action: string               # 行動描述
  permission_level: P-R | P-A | P-W | P-E
  actor: string                # 執行的 AI / Workflow / User
  target: string               # 被操作的資源
  status: success | denied | pending_approval
  reason: string               # AI 的行動理由
  approved_by: string | null
}
```

**Audit Log 特性**：
- 只能追加（append-only），不能修改或刪除
- 定期匯出為不可變的快照（用於長期存查）

---

## 安全邊界

除了 AI 的行動控制，以下安全邊界也必須在 V1 建立：

| 邊界 | 規則 |
|---|---|
| API 憑證 | 永遠存在環境變數或 `.env`，不得出現在程式碼或日誌中 |
| 知識庫敏感欄位 | 個人財務資料（如持股數量）標記為 `sensitive = true`，AI 不得在通知中明文顯示 |
| 外部 API 呼叫 | 所有外部呼叫透過統一的 `ExternalAPIGateway`，不允許 AI 直接呼叫外部 URL |

---

## 後果（Consequences）

### 正面影響
- 信任邊界清晰，使用者知道 AI 能做什麼不能做什麼
- Audit Log 讓問題可追溯

### 負面影響（需接受的取捨）
- P-E 層的功能需要額外的授權 UI
- Audit Log 的儲存量會隨使用時間增長

---

## 實施原則

1. 任何新功能在實作前，必須先定義其權限層級（P-R/P-A/P-W/P-E）
2. P-E 層的功能需要在對應的 ADR 中明確說明授權機制
3. Audit Log 的讀取權限屬於 P-R，但任何人不得修改 Audit Log

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | V2 多人版本的權限如何隔離？（每個使用者有自己的 AI 權限設定） | Open（V2 再討論） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
