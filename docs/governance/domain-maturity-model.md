---
doc_type: governance
doc_id: GOVR-003
title: Domain Maturity Model
status: accepted
version: "1.2"
date: 2026-06-29
related: [GOVR-001, GOVR-002, GOVR-004, GOVR-005, GOVR-006, GOVR-007, TMPL-001, ADR-0010]
tags: [domain, maturity, quality, governance, golden-domain]
---

# Domain Maturity Model

> 本文件定義 PAOS Domain 的六級成熟度模型（Level 0–5）。  
> **核心目標**：每個 Domain 不只是「文件寫完了」，而是「被驗證、被實作、被證明可複用」。  
> Level 5 Domain 成為 **Golden Domain**——整個 PAOS Domain 系統的品質標準範本。

---

## 一、為什麼需要成熟度模型？

沒有成熟度模型的風險：
- Domain 文件完成但存在架構缺陷，直到實作時才發現，修改成本高
- 每個 Domain 品質不一，系統越大越難維護
- 無法判斷哪個 Domain 可以作為「參考範本」，每次設計新 Domain 都從零開始

成熟度模型提供一個**共同的品質語言**：說「Marketplace 是 Level 2」，就意味著它通過了完整的架構驗證，可以安全進入實作。

---

## 二、六個等級定義

### Level 0：Draft（草稿）

**說明**：Domain 設計已開始，但文件尚未完整或尚未準備好審查。

**進入條件**：建立 Domain 文件檔案（`docs/architecture/domains/{domain}.md`），確立設計方向。

**特徵**：
- 部分區塊有佔位符或尚未填寫
- 核心概念已確立，但細節仍在探索

**允許的事**：自由修改設計、探索多個方向、與 AI Architect 共同討論  
**不允許的事**：開始實作程式碼、引用此文件作為正式規格

---

### Level 1：Defined（已定義）

**說明**：Domain 設計文件完整，通過文件完整性審查。

**進入條件**（通過 Level 1 審查，見 GOVR-002）：
- GOVR-001 中 TMPL + NAME + GLOSS 三個維度全部通過
- 零 Blocker 發現
- Final Approver 批准

**代表意義**：這個 Domain 的「是什麼」已清楚定義——但**文件完整不等於設計正確**，架構正確性由 Level 2 驗證。

**允許的事**：進入 Level 2 審查  
**不允許的事**：開始實作程式碼（架構可能仍有問題）

---

### Level 2：Validated（已驗證）

**說明**：Domain 通過完整的架構與設計驗證，確認符合 PAOS 所有架構原則。

**進入條件**（通過 Level 2 審查，見 GOVR-002）：
- 已達到 Level 1
- GOVR-001 所有 9 個維度通過（零 Blocker，Major 失敗 ≤ 2 且有文件化說明）
- 完整審查記錄存於 `docs/governance/reviews/`
- Final Approver 批准

**代表意義**：這個 Domain 的設計是**「架構正確的」**——符合 12 個架構原則、能與其他 Domain 共存，但尚未證明對使用者有價值。

**允許的事**：完成 Product Validation Gate，申請進入 Level 3  
**不允許的事**：開始實作程式碼（必須先定義「成功」是什麼）

---

### Product Validation Gate（Level 2 → Level 3 前置，GOVR-004）

> 架構正確 ≠ 產品有價值。在實作之前，必須先定義清楚「什麼叫成功」。

**必須完成的 8 項前置條件**（全部由 GOVR-004 定義）：

| # | 項目 | 輸出文件 |
|---|---|---|
| PV-G1 | User Stories（≥ 3 個，含 Acceptance Criteria）| Domain PV Spec |
| PV-G2 | Success Criteria（≥ 3 項，對應 KPI）| Domain PV Spec |
| PV-G3 | KPI 與目標值（可量測）| Domain PV Spec |
| PV-G4 | Manual Baseline 建立（不用 AI 時的現狀）| GOVR-005 Benchmark |
| PV-G5 | Benchmark 勝出條件（AI 如何「贏過」手動）| GOVR-005 Benchmark |
| PV-G6 | Golden Dataset 建立（≥ 30 筆，人工標注）| GOVR-006 Dataset |
| PV-G7 | Regression 衰退門檻設定 | GOVR-007 Regression |
| PV-G8 | Level 3 Acceptance Criteria（實作後的驗收標準）| Domain PV Spec |

**所有 PV-G1～PV-G8 完成 → Final Approver 批准 → 才能進入 Level 3 實作。**

---

### Level 3：Implemented（已實作）

**說明**：Domain 的所有設計元件已完成程式碼實作，且通過測試與 Product Validation。

**進入條件**：
- 已達到 Level 2
- Product Validation Gate（PV-G1～PV-G8）全部完成
- 所有 Collector / Parser / Analyzer 實作完成
- 所有 Workflow 可以端對端執行
- 單元測試通過率 ≥ 80%
- 至少 1 個整合測試通過
- 部署至 D1（Windows 開發環境）並成功執行完整 Workflow

**代表意義**：這個 Domain 不只是設計，它**實際上在運行，且通過了 Product Validation 的 Acceptance Criteria**。

**允許的事**：進入 Level 4 穩定性觀察期  
**不允許的事**：在累積足夠穩定性數據前標記為 Production

---

### Level 4：Production（生產穩定）

**說明**：Domain 在生產環境中穩定運行，使用者依賴它產出有價值的結果。

**進入條件**：
- 已達到 Level 3
- 在 D1 或 D2 環境中穩定運行 ≥ 30 天
- P1 Bug 數量 = 0（30 天觀察期內）
- P2 Bug 數量 ≤ 3（30 天內，且已全部解決）
- 所有 Workflow 按排程正常執行，成功率 ≥ 95%
- 至少產出過 1 次有效的使用者通知（Domain 確實在交付價值，不是空轉）

**代表意義**：這個 Domain 是**可靠的**，使用者可以依賴它。

**允許的事**：作為非正式參考、申請 Level 5 認定  
**不允許的事**：在成為 Level 5 前，不能被官方引用為「Golden Domain」

---

### Level 5：Reusable（可複用 / Golden Domain）

**說明**：Domain 已證明自己是有效的設計範本，後續 Domain 以它為參考標準。

**進入條件**：
- 已達到 Level 4
- 至少有 **1 個後繼 Domain** 在設計時以此 Domain 作為明確參考（「按照 Marketplace 的模式設計」）
- 在設計後繼 Domain 過程中，從此 Domain 發現的問題已**回饋到 TMPL-001**（domain-template.md 更新）
- 實作和運行中發現的設計缺陷已修正並記錄於 Domain 文件的 Changelog
- Final Approver 正式認定此 Domain 為「Golden Domain」

**代表意義**：這個 Domain 不只是在運行的業務模組——它是**整個 PAOS Domain 系統的品質基準範本**。

**Golden Domain 的特殊地位**：
1. 列於本文件的 Golden Domain 官方名單（第六節）
2. 新 Domain 設計時，Reviewer 對照 Golden Domain 的具體做法提出建議
3. Golden Domain 的設計決策（「為什麼這樣設計」）有文件說明，供後來者學習
4. Golden Domain 的設計決策視為 PAOS 的「最佳實踐」，並回饋改進 domain-template.md

---

## 三、等級速查表

| 等級 | 名稱 | 核心意義 | 需通過 PV Gate？ | 可開始實作？ | 可標記 Production？ | 可作 Golden Domain？ |
|---|---|---|---|---|---|---|
| 0 | Draft | 設計進行中 | ❌ | ❌ | ❌ | ❌ |
| 1 | Defined | 文件完整 | ❌ | ❌ | ❌ | ❌ |
| 2 | Validated | 架構正確 | ✅ 必須 | ❌（PV Gate 後才可）| ❌ | ❌ |
| — | PV Gate | 定義成功標準 | — | — | — | — |
| 3 | Implemented | 程式碼完成 | — | ✅ | ❌ | ❌ |
| 4 | Production | 穩定運行 | — | — | ✅ | ❌ |
| 5 | Reusable | 可作範本 | — | — | ✅ | ✅ |

---

## 四、等級降級規則

降級是系統誠實性的標誌，不應視為失敗——它表示「這個 Domain 需要重新驗證」。

| 降級觸發 | 降至 | 說明 |
|---|---|---|
| Domain 文件 major version bump（1.x → 2.0）| Level 1 | 重大設計改動需重新通過架構驗證 |
| 重新審查發現 Blocker 項目 | Level 1 | 架構缺陷修正後需重審 |
| P1 Bug 歸因為設計缺陷（非實作 Bug）| Level 3 | 設計問題需回到設計層修正後重新實作 |
| Template（TMPL-001）major version 升級且有 Breaking Change | Level 1 | 新 Template 要求不相容時需重新驗證 |

**重要**：降級不刪除歷史審查記錄。`docs/governance/reviews/` 中的所有記錄永久保留。

---

## 五、Domain 等級的前置條件關係

```
Level 0 (Draft)
  ↓ [16 個區塊填寫完畢 → 申請 Level 1 審查]
Level 1 (Defined)
  ↓ [通過 GOVR-001 完整 9 維度架構審查 → 申請 Level 2 批准]
Level 2 (Validated)
  ↓ [完成 Product Validation Gate（GOVR-004/005/006/007）]
  ┌─────────────────────────────────────────────────────────┐
  │ Product Validation Gate（PV-G1 ~ PV-G8）                │
  │  PV-G1: User Stories 定義（≥ 3 個）                    │
  │  PV-G2: Success Criteria 定義（≥ 3 項）                │
  │  PV-G3: KPI 與目標值確定                               │
  │  PV-G4: Manual Baseline 建立（GOVR-005）               │
  │  PV-G5: Benchmark 勝出條件定義（GOVR-005）             │
  │  PV-G6: Golden Dataset 建立（≥ 30 筆，GOVR-006）       │
  │  PV-G7: Regression 門檻設定（GOVR-007）                │
  │  PV-G8: Level 3 Acceptance Criteria 定義               │
  └─────────────────────────────────────────────────────────┘
  ↓ [Final Approver 批准 PV Gate]
Level 3 (Implemented)
  ↓ [所有元件實作，測試通過，D1 部署成功，通過 Acceptance Criteria]
Level 4 (Production)
  ↓ [穩定運行 30 天，成功率 ≥ 95%，有效通知 ≥ 1 次]
Level 5 (Reusable / Golden Domain)
  ↓ [後繼 Domain 以此為參考，改進回饋到 TMPL-001]
```

---

## 六、Domain 登記表（Registry）

> 所有 PAOS Domain 的當前等級狀態。本表是唯一的 Domain 狀態真實來源（Single Source of Truth）。  
> 每次等級變更後必須更新本表。

| Domain | doc_id | 當前等級 | 狀態名稱 | 最後等級更新 | 備註 |
|---|---|---|---|---|---|
| marketplace | DOMAIN-001 | **Level 1** | Defined | 2026-06-27 | 等待 Level 2 審查（GOVR-001 9 維度）|

---

## 七、Golden Domain 官方列表

> Level 5 Domain 的官方認定名單。  
> **目標**：Marketplace 成為第一個 Golden Domain，為 Stocks、Jobs、AI 等後續 Domain 樹立設計標準。

| Domain | 認定日期 | 後繼 Domain（以此為參考）| 回饋到 TMPL-001 的改進 |
|---|---|---|---|
| （尚無 Golden Domain）| — | — | — |

---

## 八、Marketplace 的預期進展路徑

```
Level 1: Defined      → Level 2 審查（GOVR-001，9 維度）
Level 2: Validated    → Product Validation Gate（GOVR-004/005/006/007）
                      → Prototype 階段（5 元件驗證）
                      → Performance Validation
Level 3: Implemented  → 30 天生產觀察 + 月度 Replay
Level 4: Production   → 第二個 Domain 套用驗證
Level 5: Reusable     ← 第一個 Golden Domain
```

> 完整的各階段目標、Entry/Exit Criteria、成功標準與風險清單，  
> 請參閱 **[governance/product-validation/marketplace-roadmap.md](./product-validation/marketplace-roadmap.md)**（GOVR-PV-MKT-001）。

---

## 九、Golden Domain 對後繼 Domain 的影響

當 Marketplace 成為 Golden Domain 後，後繼 Domain 的設計流程應包含：

1. **對照 Marketplace 的 Core Concepts**：新 Domain 的核心實體設計方式是否與 Marketplace 一致？
2. **對照 Marketplace 的 Workflow 步驟設計**：Input/Output 型別定義方式是否一致？
3. **對照 Marketplace 的 Knowledge 結構**：thresholds / rules 的儲存格式是否相容？
4. **學習 Marketplace 踩過的坑**：Marketplace Changelog 中記錄的設計問題，後繼 Domain 不要重蹈

**目標**：每個後繼 Domain 都站在前任 Golden Domain 的肩膀上設計，系統整體品質螺旋上升。

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版：Level 0–5 定義、Domain Registry、Golden Domain 列表、Marketplace 路徑圖 |
| 1.1 | 2026-06-27 | 新增 Product Validation Gate（PV-G1~G8）於 Level 2 → Level 3 之間；更新等級速查表和路徑圖 |
| 1.2 | 2026-06-29 | 精簡第八節路徑圖，完整路徑移至 marketplace-roadmap.md（GOVR-PV-MKT-001）|
