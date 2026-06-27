---
doc_type: governance
doc_id: GOVR-002
title: Domain Review Process
status: accepted
version: "1.0"
date: 2026-06-27
related: [GOVR-001, GOVR-003, TMPL-001, ADR-0010]
tags: [domain, review, process, governance]
---

# Domain Review Process

> 本文件定義 Domain 設計文件的正式審查流程。  
> 目標：確保每個 Domain 在標記為 Validated（Level 2）之前，都通過標準化的品質審查。

---

## 一、為什麼需要正式審查流程？

在 PAOS 中，每個 Domain 都是一個獨立的業務模組。Domain 設計的品質直接影響：

- **可維護性**：設計良好的 Domain 進入實作階段不需要重新設計
- **可擴展性**：新增 Domain 必須能複用現有基礎設施而不是重造輪子
- **一致性**：所有 Domain 遵循相同標準，系統才能保持整體可理解性

正式審查流程防止「先寫後說」的慣例——確保文件在進入實作階段前已通過架構驗證。

---

## 二、審查觸發時機

| 觸發條件 | 目標等級 | 說明 |
|---|---|---|
| Domain 文件初稿完成（16 個區塊填寫完畢）| Level 1（Defined）| 首次文件完整性審查 |
| Domain 已達 Level 1，Author 申請架構驗證 | Level 2（Validated）| 完整 9 維度審查 |
| Domain 文件 major version bump（如 v1.0 → v2.0）| 重新驗證（目標 Level 2）| 重大設計變更後需重審 |
| Template（TMPL-001）版本升級且有 Breaking Change | 重新驗證 | 所有 Domain 對照新模板重審 |

**不觸發審查的情況**：
- 文字修正、範例補充（minor version bump，如 v1.0 → v1.1）
- 僅修正錯字、補充說明，不涉及設計決策

---

## 三、審查者角色

PAOS V1 是個人系統，沒有傳統意義的審查委員會，但審查職責仍需明確分工：

| 角色 | 職責 | V1 誰來做 |
|---|---|---|
| **Domain Author** | 設計並撰寫 Domain 文件 | User 或 AI Architect（Claude）|
| **Primary Reviewer** | 填寫 GOVR-001 驗證清單，完成全部審查 | AI Architect（Claude）|
| **Final Approver** | 審閱審查意見，批准等級晉升 | User（系統所有人）|

**分工原則**：Domain Author 不能同時擔任 Primary Reviewer（自審有盲點）。

實踐方式：
- 若 **User 設計** Domain → **Claude** 擔任 Primary Reviewer
- 若 **Claude 設計** Domain → **User 必須親自審查**核心設計決策，Claude 協助填寫清單

---

## 四、Level 1 審查流程（文件完整性）

**目標**：確認文件完整——完整不等於正確，正確性由 Level 2 驗證。

```
[Author] 宣告「Level 1 審查就緒」，標明審查基準版本
         ↓
[Reviewer] 對照 GOVR-001，填寫 TMPL + NAME + GLOSS 三個維度
         ↓
[Reviewer] 識別所有 Blocker 項目
         ↓
有 Blocker？
  ↳ 是 → [Reviewer] 列出問題 → [Author] 修正文件（bump minor version）→ 重新提交
  ↳ 否 → 繼續
         ↓
[Reviewer] 填寫「審查者總體意見」
         ↓
[Final Approver] 確認無 Blocker，批准 Level 1
         ↓
[Author] 更新 Domain 文件 front matter：
           maturity_level: 1
         ↓
[Author] 更新 GOVR-003（domain-maturity-model.md）Domain Registry 表
```

**時間目標**：Level 1 審查在 1 個工作天內完成。

**審查記錄儲存路徑**：
```
docs/governance/reviews/{domain}-v{version}-level1-review.md
```

---

## 五、Level 2 審查流程（架構完整性）

**目標**：確認 Domain 設計架構正確——符合所有架構原則，可以安全進入實作。

```
[Author] 確認 Domain 已達 Level 1，宣告「Level 2 審查就緒」
         ↓
[Reviewer] 對照 GOVR-001，填寫全部 9 個維度
         ↓
[Reviewer] 識別 Blocker 和 Major 失敗
         ↓
有 Blocker？
  ↳ 是 → [Reviewer] 列出問題 → [Author] 修正 → 重新提交（重複直到零 Blocker）
  ↳ 否 → 繼續
         ↓
Major 失敗 > 2？
  ↳ 是 → [Reviewer] 建議優先修正的 Major 項目 → [Author] 修正後重新審查
  ↳ 否（≤ 2）→ [Author] 為每個 Major 例外提供文件化說明（原因 + 風險 + 計劃）
         ↓
[Reviewer] 撰寫審查者總體意見（優點、主要問題、改進建議）
         ↓
[Final Approver] 審閱完整審查記錄，決定是否批准
         ↓
批准 → [Author] 更新 Domain 文件 front matter：
                  maturity_level: 2
              [Author] 更新 GOVR-003 Domain Registry
不批准 → [Author] 依 Approver 意見修正 → 重新提交 Level 2 審查
```

**時間目標**：Level 2 審查在 3 個工作天內完成。

**審查記錄儲存路徑**：
```
docs/governance/reviews/{domain}-v{version}-level2-review.md
```

---

## 六、重新審查流程

當 Domain 設計發生重大變更時需重新審查：

**觸發條件**：Domain 文件 major version bump（v1.x → v2.0）

**流程**：
1. Domain 自動降至 Level 1（文件定義層）
2. Author 補上新版本的 Level 2 審查申請
3. 重新走 Level 2 審查流程
4. 通過後恢復 Level 2 並更新 Registry

**重新審查規則**：
- 歷史審查記錄永遠保留（不刪除）
- 降級是客觀的品質標誌，不是懲罰
- 若新版本僅部分重大變更，Reviewer 可選擇只重審受影響的維度（需在意見中說明）

---

## 七、審查記錄管理

**目錄結構**：

```
docs/governance/reviews/
├── marketplace-v1.0-level1-review.md
├── marketplace-v1.0-level2-review.md
├── stocks-v1.0-level1-review.md
└── {domain}-v{version}-level{n}-review.md
```

**記錄格式**：複製 GOVR-001（domain-validation-checklist.md），填入所有 Verdict 和備註。

**保留原則**：審查記錄永遠保留，不因 Domain 版本升級而刪除。歷史記錄是整個系統的學習資料。

---

## 八、例外處理規則

| 情況 | 處理方式 |
|---|---|
| 項目不適用（NA）| Verdict 填 `⬜ NA`，**必須**在備註說明為何不適用 |
| Major 有合理技術例外 | 記錄：原因、風險評估、預計改善版本（最多 2 個例外）|
| Blocker 申請例外 | **不接受**。Blocker 必須修正，無例外，無討論空間 |
| Reviewer 與 Author 意見不一致 | Final Approver 有最終決定權 |
| 緊急情況需跳過審查 | **不允許**。寧可推遲實作，也不跳過架構驗證 |

---

## 九、Level 3–5 的進階審查

Level 3（Implemented）及以上的審查涉及程式碼實作與生產運行，不在本文件（GOVR-002）範圍內。

進階等級的晉升標準詳見 GOVR-003（domain-maturity-model.md）。

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：Level 1 與 Level 2 審查流程、角色分工、例外規則 |
