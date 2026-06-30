---
doc_type: architecture
doc_id: ARCH-003
title: PAOS Architecture Principles
status: accepted
version: "1.2"
date: 2026-06-29
related: [GLOSS-001, ARCH-001, ARCH-002]
tags: [principles, architecture, design, constraints]
---

# PAOS Architecture Principles

> 本文件將所有 ADR 中隱含的設計哲學整理為明確的原則。  
> 當你面臨設計決策時，先問：哪個原則適用？

---

## 為什麼需要原則？

ADR 記錄「決定了什麼」，但不直接回答「在這個新情況下應該怎麼做」。原則是 ADR 的蒸餾——讓設計者在遇到未預見的情況時，仍能做出與整體架構一致的決策。

---

## 原則列表

### P-01：Glossary First（術語優先）

**來源**：GLOSS-001  
**規則**：創建任何新概念（類別、模組、事件、文件）前，先在 Glossary 中定義它。不能引用 Glossary 中未存在的術語。  
**Why**：防止不同文件各自發明名詞，維護 Single Source of Truth。  
**違反後果**：術語漂移，未來 AI 和工程師無法確定哪個名稱是正確的。

---

### P-02：Event Bus as the Spine（Event Bus 是脊椎）

**來源**：ADR-0011, ADR-0014  
**規則**：所有跨模組、跨層的通訊必須透過 Event Bus。禁止直接 import 並呼叫另一個模組的函數。  
**Why**：Event Bus 讓系統從 V1 單進程無縫演進到 V2/V3 分散式架構——替換 Event Bus 實作不影響任何業務邏輯。  
**違反後果**：緊耦合，修改一個模組需要同時修改其他模組。

```typescript
// ❌ 違反 P-02
import { StockCollector } from '../workers/StockCollector'
await StockCollector.run()

// ✅ 遵循 P-02
eventBus.emit(EVENTS.WORKFLOW_TRIGGERED, {
  type: 'collect_stocks',
  taskId: generateTaskId()
})
```

---

### P-03：Domain Isolation（Domain 隔離）

**來源**：ADR-0010, ADR-0014  
**規則**：Domain 之間不能直接呼叫。一個 Domain 需要另一個 Domain 的資料，必須透過 Knowledge Service 或 Event Bus。  
**Why**：防止 Domain 之間的依賴網形成，確保每個 Domain 可以獨立啟用、停用或修改。  
**違反後果**：Domain A 的變更意外破壞 Domain B。

---

### P-04：Architecture First, Implementation Later（架構優先）

**來源**：ADR-0011  
**規則**：設計介面和通訊協議時，假設 V2 分散式環境。即使 V1 是單進程，也要讓程式碼「看起來像」分散式的。  
**Why**：從單進程重構為分散式比從一開始就設計分散式要貴得多。  
**實踐**：使用 `dispatch()` 模式，不使用直接函數呼叫；使用 Task ID 追蹤，不使用同步回傳。

---

### P-05：Repository Abstraction（Repository 抽象）

**來源**：ADR-0013, ADR-0014  
**規則**：業務邏輯永遠不直接寫 SQL。所有資料存取透過 Repository 介面。  
**Why**：SQLite 是 V1 的選擇，但 V3 可能需要 PostgreSQL 或 Cloud DB。Repository 介面確保切換後端不影響業務邏輯。  
**違反後果**：資料庫遷移需要修改大量業務代碼。

```typescript
// ❌ 違反 P-05
const rows = await db.query('SELECT * FROM knowledge WHERE domain = ?', ['stocks'])

// ✅ 遵循 P-05
const rules = await knowledgeRepo.findByDomain('stocks')
```

---

### P-06：12-Factor App Compliance（12-Factor 合規）

**來源**：ADR-0015  
**規則**：所有設定透過環境變數；不寫本地日誌檔（輸出到 stdout/stderr）；進程是無狀態的。  
**Why**：確保從 D1（Windows 開發）到 D2（Linux Server）到 D3（Cloud）的部署遷移不需要修改代碼。  
**關鍵要求**：`GET /health` Endpoint 從 V1 起就必須實作；`SIGTERM` 必須觸發 Graceful Shutdown（最多等待 30 秒）。

---

### P-07：No Direct AI SDK Calls（不直接呼叫 AI SDK）

**來源**：ADR-0003  
**規則**：業務邏輯只能透過 `AIProvider` 介面呼叫 AI。`packages/ai-provider/` 是系統中**唯一**允許 import Anthropic/OpenAI SDK 的地方。  
**Why**：防止被任何一家 AI 廠商綁定；集中管理 API Key、重試、限流邏輯。  
**違反後果**：切換 AI Provider 需要修改業務邏輯代碼。

---

### P-08：AI Outputs Must Pass Validation（AI 輸出必須通過驗證）

**來源**：ADR-0008  
**規則**：AI 輸出在被用於決策或寫入 Knowledge 之前，必須通過至少 L1 驗證。高風險操作需要 L3（人工確認）。  
**Why**：AI 會產生幻覺。未驗證的 AI 輸出直接影響決策會導致系統不可靠。  
**違反後果**：錯誤的 AI 輸出可能導致錯誤的決策或 Knowledge 污染。

---

### P-09：Audit Everything（所有重要操作都記錄）

**來源**：ADR-0009  
**規則**：所有 Action（有副作用的操作）都必須寫入 Audit Log。Audit Log 是 append-only，不能修改或刪除。  
**Why**：可追蹤性是長期系統維護的基礎；安全審計需要完整的操作歷史。  
**絕對禁止**：AI 不能自動刪除資料、自動購買、自動在社群媒體發文。

---

### P-10：Fail Safe Defaults（安全預設）

**來源**：ADR-0009  
**規則**：不確定是否有權限時，預設拒絕（Deny by Default）。高風險操作需要明確的使用者確認。  
**Why**：在個人 AI 系統中，誤操作的代價可能很高（發送錯誤訊息、修改重要資料）。  
**實踐**：P-E（Execute）等級的操作默認需要人工確認；只有被明確標記為「auto-execute safe」的操作才能自動執行。

---

### P-11：Single Ownership（每個概念只有一個 Owner）

**來源**：GLOSS-001  
**規則**：每個概念有且只有一個模組負責它的生命週期。兩個模組不能同時「管理」同一個 Resource。  
**Why**：多個 Owner 導致狀態不一致、責任不清晰。  
**實踐**：Glossary 的 Ownership 表是權威來源。如果兩個模組都想管理同一個東西，需要重新設計邊界。

---

### P-12：Graceful Degradation（優雅降級）

**來源**：ADR-0011, ADR-0015  
**規則**：任何 Worker 崩潰不能影響 Core 的運行。Core 應繼續處理使用者請求，即使後台分析任務失敗。  
**Why**：Worker 做的是後台工作（收集、分析），不是即時回應。即使分析失敗，使用者的 Telegram 對話應繼續正常工作。  
**實踐**：Worker 的錯誤寫入 Task Queue 的狀態欄位（`failed`），而不是拋出到 Core。

---

### P-13：No New Domain Before Proven Value（價值證明前不擴張）

**來源**：GOVR-003, GOVR-004, 本專案演進經驗（Marketplace 作為第一個被驗證的 Domain）  
**規則**：在現有 Domain 通過 **Product Validation**（在真實資料上證明對使用者有實際價值）之前，**不開始設計或實作下一個 Domain**。  
**階段對應**：
- **Level 2** 證明*架構*可行（系統建得正確）
- **Product Validation** 證明*產品*可行（建的東西真的有用）
- 唯有產品價值被真實證明，才啟動第二個 Domain

**Why**：架構可行不等於產品有價值。先讓一個 Domain 真正證明有用，後繼 Domain 才有「**已被驗證的方法**」可以複製。否則 PAOS 會變成「擁有很多 Domain、卻沒有一個被真正驗證」的平台。  
**違反後果**：累積一堆未驗證的 Domain，技術債與維護成本上升，且沒有可複製的成功方法。  
**性質**：這是一條**流程閘門（process gate）**原則，由 GOVR-003 成熟度模型強制執行；不與 P-01~P-12 的技術衝突優先級競爭。

---

### P-14：Secrets Never Leave the Runtime（機密永不離開執行環境）

**來源**：ADR-0009, ADR-0015, 本專案 Product Validation 經驗（Marketplace MVP）  
**規則**：API Key、Token、密碼、憑證等任何機密，**只存在於執行環境**（環境變數或 Secret Manager），且：
- **絕不寫入 Git**（包含 commit、分支、歷史紀錄）
- **絕不寫入文件**（docs / README / Changelog / 範例）
- **絕不貼入 AI 對話或 prompt**
- **絕不硬編碼於程式碼**
- 一律透過**環境變數或 Secret Manager** 注入執行環境

**Why**：機密一旦進入 Git、文件或對話，就等同公開洩漏，而且幾乎無法撤銷（Git 歷史、對話記錄、文件副本都會留存）。將機密限制在執行環境，是 PAOS 未來接 Facebook、GitHub、Telegram、Google 等服務時共用的安全基礎。  
**違反後果**：憑證外洩、帳號被盜用、需緊急輪替所有受影響的金鑰。  
**實踐**：
- `.env` 必須被 gitignore；只提交 `.env.example`（**只有鍵名、沒有值**）。
- 程式一律從 `process.env` / Secret Manager 讀取，不接受呼叫端傳入明文憑證。
- **AI Provider 由執行環境注入憑證**：業務邏輯只拿到 Provider 介面，拿不到金鑰本身。
- 驗證/測試流程不得要求把金鑰交給第三方（包含 AI 助手）。  
**性質**：屬於**最高安全層級**，與 P-09、P-10 同級，優先於一切架構優雅性。

---

## 原則優先級

當兩個原則衝突時，以下優先級適用：

```
P-09（Audit Everything）> P-10（Fail Safe）> P-01（Glossary First）
> P-07（No Direct AI SDK）> P-02（Event Bus）> P-05（Repository）
> P-03（Domain Isolation）> P-04（Architecture First）
> P-06（12-Factor）> P-08（AI Validation）
> P-11（Single Ownership）> P-12（Graceful Degradation）
```

**安全性和可追蹤性（P-09, P-10, P-14）永遠優先於架構優雅性。**

---

## 原則 vs ADR

原則是 ADR 的蒸餾，但不取代 ADR：

| ADR | 關聯原則 |
|---|---|
| ADR-0002 Platform Strategy | P-04, P-06 |
| ADR-0003 AI Provider | P-07 |
| ADR-0004 Knowledge | P-08, P-11 |
| ADR-0005 Workflow | P-04, P-02 |
| ADR-0006 Memory | P-11 |
| ADR-0008 Validation | P-08 |
| ADR-0009 Security | P-09, P-10, P-14 |
| ADR-0010 Domain Expansion | P-03, P-11, P-13 |
| ADR-0011 Runtime | P-02, P-04, P-12 |
| ADR-0013 Storage | P-05 |
| ADR-0014 Communication | P-02, P-03 |
| ADR-0015 Deployment | P-06, P-12, P-14 |
| GLOSS-001 Glossary | P-01, P-11 |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，從所有 ADR 蒸餾 12 個架構原則 |
| 1.1 | 2026-06-29 | 新增 P-13 No New Domain Before Proven Value（流程閘門，由 GOVR-003 強制執行）|
| 1.2 | 2026-06-29 | 新增 P-14 Secrets Never Leave the Runtime（最高安全層級，與 P-09/P-10 同級）|
