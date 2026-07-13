---
doc_type: vision
doc_id: INDEX-001
title: PAOS Documentation Index
status: accepted
version: "1.9"
date: 2026-07-13
---

# PAOS 文件總索引

> 這是整個 PAOS 文件系統的入口點。  
> **AI 接手時請從這裡開始閱讀。**
>
> 🔀 **跨 Session / 跨裝置 / 跨瀏覽器接手**：先讀 [session-handoff.md](./session-handoff.md)（HANDOFF-001），一讀即可無縫接續目前進度與下一步。

---

## 建議閱讀順序（AI / 新加入者）

```
1. glossary.md                  → 統一術語（先建立共同語言，避免一切誤解）
2. concept-map.md               → 理解概念之間的關係與互動模式
3. vision-scope.md              → 理解為什麼這個系統存在
4. architecture-principles.md  → 理解設計哲學與不可違反的規則
5. system/documentation-system.md → 理解文件的規則和格式（含 ADR Lifecycle）
6. architecture/platform-blueprint.md → 理解整體系統架構
7. decisions/ADR-000*.md        → 理解所有重要決策的來龍去脈
```

---

## 文件地圖

### 接手與交接（Handoff）

| 文件 | 說明 | 狀態 |
|---|---|---|
| [session-handoff.md](./session-handoff.md) | 跨 Session / 跨裝置接手說明（HANDOFF-001）：現況一句話、Git 座標、MVP 位置與跑法、被 Blocked 的第一份 PV Report 需要哪些輸入、下一步、不可違反護欄 | Living v1.0 |

---

### 通用語言（Ubiquitous Language）

> **所有讀者必讀。** 這四份文件構成 PAOS 的共同語言基礎。任何新文件或代碼必須以此為準。

| 文件 | 說明 | 狀態 |
|---|---|---|
| [glossary.md](./glossary.md) | 31 個核心術語：Anti-Definition、Canonical Name、Stability、Ownership、Relationships | Accepted v2.0 |
| [concept-map.md](./concept-map.md) | 平台層次圖、八層架構、全域關係矩陣、關鍵互動模式、概念邊界速查 | Accepted v1.0 |
| [naming-convention.md](./naming-convention.md) | 命名決策樹、Domain 元件命名、Event/Task/Workflow 命名規則、禁止模式 | Accepted v1.0 |
| [architecture-principles.md](./architecture-principles.md) | 14 個架構原則（P-01 Glossary First ～ P-14 Secrets Never Leave the Runtime）| Accepted v1.2 |

---

### 願景與範圍

| 文件 | 說明 | 狀態 |
|---|---|---|
| [vision-scope.md](./vision-scope.md) | PAOS 的願景、範圍、已確認決策與開放問題 | Accepted |

---

### 系統規範

| 文件 | 說明 | 狀態 |
|---|---|---|
| [system/documentation-system.md](./system/documentation-system.md) | 文件格式標準、ADR Lifecycle、版本控制規則 | Accepted v1.2 |
| [decision-log.md](./decision-log.md) | 術語變更記錄、架構轉折、棄用模式、開放決策追蹤 | Accepted v1.0 |

---

### 架構文件

| 文件 | 說明 | 狀態 |
|---|---|---|
| [architecture/platform-blueprint.md](./architecture/platform-blueprint.md) | 平台分層架構、資料流、Repo 結構建議 | Draft |

---

### Domain 設計文件

| 文件 | 說明 | 狀態 |
|---|---|---|
| [architecture/domains/marketplace.md](./architecture/domains/marketplace.md) | Marketplace Domain：多平台二手商品監控（蝦皮、Yahoo、露天）| Accepted v1.1（Level 2）|

---

### 程式碼原型（Prototypes）

> PAOS 的第一段可執行程式碼。原型不是正式產品，位於 `prototypes/`，用於 Product Validation。

| 位置 | 說明 | 狀態 |
|---|---|---|
| [prototypes/marketplace-book-mvp/](../prototypes/marketplace-book-mvp/) | Marketplace Path A Lite MVP：判斷單篇 Facebook 二手書貼文是否值得通知。單平台、單品類、無 DB/Dashboard/排程。AI 存取經 `aiProvider.ts`（P-07 seam），Provider/Model 由環境變數決定（P-14） | ✅ 可執行；型別檢查通過；`npm run dry` 通過。真實 `npm start` 待使用者本機執行 |

---

### 模板（Templates）

| 文件 | 說明 | 狀態 |
|---|---|---|
| [templates/domain-template.md](./templates/domain-template.md) | Domain 設計模板：所有 Domain 必須使用此模板，含 21 個區塊（v1.1 由 Marketplace 實戰驗證擴充）| Accepted v1.1（Experimental）|

---

### 治理框架（Domain Governance）

> 所有 Domain 在進入實作前必須通過本框架的驗證。Marketplace 的目標是成為第一個 Level 5 Golden Domain。

| 文件 | 說明 | 狀態 |
|---|---|---|
| [governance/domain-validation-checklist.md](./governance/domain-validation-checklist.md) | 驗證清單（GOVR-001）：9 個維度、33 個驗證項目，Level 1/2 晉升判定 | Accepted v1.0 |
| [governance/domain-review-process.md](./governance/domain-review-process.md) | 審查流程（GOVR-002）：Level 1/2 審查步驟、角色分工、例外規則 | Accepted v1.0 |
| [governance/domain-maturity-model.md](./governance/domain-maturity-model.md) | 成熟度模型（GOVR-003）：Level 0–5 定義、PV Gate、Domain Registry、Golden Domain 列表 | Accepted v1.1 |
| [governance/product-validation-framework.md](./governance/product-validation-framework.md) | 產品驗證框架（GOVR-004）：User Stories、Success Criteria、KPI、PV Gate（PV-G1~G8）、Domain PV Spec 模板 | Accepted v1.0 |
| [governance/benchmark-strategy.md](./governance/benchmark-strategy.md) | Benchmark 策略（GOVR-005）：AI vs 手動基準、Manual Baseline 建立、4 個評估維度、5 個 AI 勝出條件 | Accepted v1.0 |
| [governance/golden-dataset-specification.md](./governance/golden-dataset-specification.md) | Golden Dataset 規格（GOVR-006）：資料結構、標注流程、品質要求、版本管理 | Accepted v1.0 |
| [governance/replay-regression-strategy.md](./governance/replay-regression-strategy.md) | Replay & Regression 策略（GOVR-007）：Replay Pipeline、Regression 門檻、Level Acceptance Criteria、根因分析框架 | Accepted v1.0 |
| [governance/template-evolution-policy.md](./governance/template-evolution-policy.md) | Template 演進政策與驗證史（GOVR-008）：穩定度生命週期（Experimental→Stable）、2-Domain 驗證原則、Template Validation History | Accepted v1.0 |
| [governance/execution-boundary.md](./governance/execution-boundary.md) | 自主執行邊界（GOVR-009）：AI 與 Owner 的決策權責、Milestone 內自主範圍、四類必須請示事項 | Accepted v1.0 |
| [governance/product-validation/marketplace-roadmap.md](./governance/product-validation/marketplace-roadmap.md) | Marketplace Roadmap（GOVR-PV-MKT-001）：7 階段完整生命週期、各階段 Entry/Exit Criteria、Prototype 驗收標準、Performance KPI、Golden Domain 條件、風險清單 | Accepted v1.0 |
| [governance/product-validation/marketplace-pv-execution-plan.md](./governance/product-validation/marketplace-pv-execution-plan.md) | Marketplace 產品驗證執行計畫（GOVR-PV-MKT-002）：8 項驗證操作化、兩條執行路徑、Golden Dataset 計畫、Manual Baseline 工具、誠信規則 | In Progress v1.0 |
| [governance/reviews/marketplace-v1.0-level2-review.md](./governance/reviews/marketplace-v1.0-level2-review.md) | Marketplace Level 2 審查報告（REV-MKT-001）：9 維度評分、Reusability Assessment、架構風險、Conditional Pass | Accepted v1.0 |

---

### Architecture Decision Records（ADR）

| ADR | 標題 | 狀態 | 版本 |
|---|---|---|---|
| [ADR-0001](./decisions/ADR-0001-repo-strategy.md) | Repository Strategy | Accepted | 2.0 |
| [ADR-0002](./decisions/ADR-0002-platform-strategy.md) | Platform Strategy | Accepted | 1.0 |
| [ADR-0003](./decisions/ADR-0003-ai-provider-strategy.md) | AI Provider Strategy | Accepted | 1.0 |
| [ADR-0004](./decisions/ADR-0004-knowledge-strategy.md) | Knowledge Strategy | Accepted | 1.0 |
| [ADR-0005](./decisions/ADR-0005-workflow-strategy.md) | Workflow Strategy | Accepted | 1.0 |
| [ADR-0006](./decisions/ADR-0006-memory-strategy.md) | Memory Strategy | Accepted | 1.0 |
| [ADR-0007](./decisions/ADR-0007-notification-strategy.md) | Notification Strategy | Accepted | 1.0 |
| [ADR-0008](./decisions/ADR-0008-validation-strategy.md) | Validation Strategy | Accepted | 1.0 |
| [ADR-0009](./decisions/ADR-0009-security-permission.md) | Security & Permission Strategy | Accepted | 1.0 |
| [ADR-0010](./decisions/ADR-0010-domain-expansion.md) | Domain Expansion Strategy | Accepted | 1.0 |
| [ADR-0011](./decisions/ADR-0011-runtime-strategy.md) | Runtime Strategy | Accepted | 2.0 |
| [ADR-0012](./decisions/ADR-0012-execution-model.md) | Execution Model | Accepted | 1.0 |
| [ADR-0013](./decisions/ADR-0013-storage-strategy.md) | Storage Strategy | Accepted | 1.0 |
| [ADR-0014](./decisions/ADR-0014-communication-strategy.md) | Communication Strategy | Accepted | 1.0 |
| [ADR-0015](./decisions/ADR-0015-deployment-strategy.md) | Deployment Strategy | Accepted | 1.0 |
| [ADR-template](./decisions/ADR-template.md) | ADR 模板 | — | — |

---

### 待建立的文件

| 文件 | 優先級 | 說明 |
|---|---|---|
| architecture/platform-blueprint.md v1.0 | 🔴 高 | 目前為 Draft v0.9，待升級為正式版本（ADR-0001/0011 已 Accepted） |
| architecture/domains/stocks.md | 🟡 中 | Stocks Domain 設計（使用 domain-template.md） |
| architecture/component-map.md | 🟡 中 | 詳細的元件地圖與依賴關係（含 Event Bus 拓撲） |
| guides/setup.md | 🟡 中 | 開發環境設定指南（V1 Windows） |
| guides/add-new-domain.md | 🟡 中 | 如何新增一個 Domain Module（含 Workflow 和 Notification 規則） |
| guides/add-new-channel.md | 🟡 低 | 如何新增一個 Channel Adapter |

---

## 決策狀態摘要

| 類別 | 已決定（ADR） | 重要開放問題 |
|---|---|---|
| Repo 策略 | Hybrid Monorepo + Split Criteria（ADR-0001 v2.0）| paos 主倉庫建在哪裡？ |
| 平台策略 | Dev/Arch/Runtime 三層分離（ADR-0002）| Runtime 語言（Node.js vs Bun）|
| AI Provider | 重度抽象層（ADR-0003）| — |
| 知識管理 | 三層分類 + 審核管線（ADR-0004）| — |
| Workflow | 完全模組化 Step（ADR-0005）| — |
| 記憶管理 | 三層記憶模型（ADR-0006）| sqlite-vss 相容性 |
| 通知 | 四層優先級（ADR-0007）| — |
| 驗證 | 三層驗證 L1/L2/L3（ADR-0008）| — |
| 安全權限 | 四層 P-R/A/W/E 模型（ADR-0009）| — |
| Domain 擴充 | Domain Plugin System（ADR-0010）| — |
| Runtime | Hybrid Core + Event Bus + Worker（ADR-0011 v2.0）| — |
| Execution | 六種 Trigger（ADR-0012）| AI-initiated rate limiting |
| Storage | SQLite 作為 V1 主後端（ADR-0013）| sqlite-vss Windows 相容性 |
| Communication | 四種合法模式 + 禁止直接呼叫（ADR-0014）| — |
| Deployment | D1/D2/D3 三目標 + 12-Factor（ADR-0015）| V2 systemd vs Docker |

---

*最後更新：2026-07-13*  
*ADR 總數：15 份（ADR-0001 ~ ADR-0015），全部 Accepted*  
*架構原則：14 條（P-01 ~ P-14），architecture-principles v1.2（含 P-14 Secrets Never Leave the Runtime）*  
*Glossary：GLOSS-001 v2.0，31 個核心術語（Anti-Definition + Canonical/Aliases + Stability + Ownership + Relationships）*  
*通用語言文件：4 份（glossary, concept-map, naming-convention, architecture-principles）*  
*Domain 文件：1 份（marketplace v1.1，Level 2 Validated），模板：1 份（domain-template v1.1 Experimental）*  
*治理框架：10 份（GOVR-001~003 架構驗證 + GOVR-004~007 產品驗證 + GOVR-008 Template 演進 + GOVR-009 執行邊界 + GOVR-PV-MKT-001 Marketplace Roadmap）+ 審查紀錄 1 份（REV-MKT-001）*  
*程式碼原型：1 份（prototypes/marketplace-book-mvp — Path A Lite MVP，PAOS 第一段可執行程式碼）*  
*接手指南：session-handoff.md（HANDOFF-001，Living v1.0）*
