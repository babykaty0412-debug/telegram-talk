---
doc_type: system
doc_id: SYS-003
title: PAOS Decision Log
status: accepted
version: "1.0"
date: 2026-06-27
related: [GLOSS-001, ARCH-003]
tags: [decision-history, terminology, pivots, adr-index]
---

# PAOS Decision Log

> 本文件記錄術語變更、概念重新定義與架構重大轉折。  
> ADR 記錄「決定了什麼」；本文件記錄「改變了什麼、為什麼改」。

---

## 用途

1. **術語歷史**：任何 Canonical Name 的更改都在這裡記錄
2. **架構轉折**：任何重大設計方向改變的記錄
3. **棄用追蹤**：哪些術語/模式被棄用，替代方案是什麼
4. **AI 交接**：AI 接手時可以快速了解「哪些東西已經改了，不要按舊的做」

---

## 術語變更記錄

| 日期 | 舊名稱 / 舊概念 | 新名稱 / 新概念 | 原因 | 影響範圍 | ADR |
|---|---|---|---|---|---|
| 2026-06-27 | `apps/telegram/` | `apps/telegram-bot/` | `telegram` 太模糊，未來可能有 telegram-admin、telegram-notify；`{service}-{role}` 模式更清晰 | ADR-0001, naming-convention.md | ADR-0001 v2.0 |
| 2026-06-27 | ADR status: `proposed` | ADR status: `review` | `proposed` 語意不夠明確（誰在 propose？）；`review` 表示「開放討論中」更清晰 | docs/system/documentation-system.md, 所有 ADR | SYS-001 v1.1 |

---

## 架構重大轉折

### 轉折 T-01：從「V2 multi-process」到「V2 Distributed-capable」

**日期**：2026-06-27  
**ADR**：ADR-0011 v1.0 → v2.0  
**舊設計**：V2 計劃為「多進程」架構  
**新設計**：V2 為「Distributed-capable」——可以是多進程、Docker、Kubernetes、Cloud 或 Serverless，不預先指定  
**原因**：「多進程」是實作細節，不應該在架構決策層面固定；PAOS V2 可能跑在任何分散式環境  
**影響**：Worker 的設計必須假設它可能在任何進程/容器中執行，不能依賴共用記憶體

---

### 轉折 T-02：新增 Event Bus 作為通訊樞紐

**日期**：2026-06-27  
**ADR**：ADR-0011 v2.0, ADR-0014  
**舊設計**：模組之間可以直接呼叫  
**新設計**：所有跨模組通訊必須透過 Event Bus  
**原因**：直接呼叫導致緊耦合，阻礙未來的分散式演進  
**影響**：所有新代碼必須使用 `eventBus.emit()` / `eventBus.on()`，禁止 `moduleA.callModuleB()`

---

### 轉折 T-03：新增 Formal Split Criteria

**日期**：2026-06-27  
**ADR**：ADR-0001 v2.0  
**舊設計**：「未來可能拆分」（模糊條件）  
**新設計**：五個明確的 Split Criteria（可獨立部署、獨立 Release Cycle、獨立 CI/CD、獨立 Team、不再依賴 Core），全部滿足才拆分  
**原因**：模糊條件導致提前拆分（增加維護成本）或過晚拆分（阻礙擴展）

---

### 轉折 T-04：Glossary 升為 Single Source of Truth

**日期**：2026-06-27  
**文件**：GLOSS-001 v2.0  
**舊設計**：Glossary 是術語表（可選讀）  
**新設計**：Glossary 是整個系統的唯一真實來源，所有文件和代碼必須引用 Glossary 中已定義的術語  
**原因**：隨著 ADR 數量增加，不同文件開始使用不同術語；需要強制一致性  
**影響**：Glossary 升為第一優先閱讀文件；新增術語必須先更新 Glossary

---

## 棄用記錄（Deprecated Patterns）

### 棄用 D-01：Manager 命名模式

**棄用日期**：2026-06-27  
**棄用術語**：`XxxManager`（如 `StockManager`、`KnowledgeManager`）  
**原因**：Manager 是過時的反模式（god class 陷阱）；沒有清晰的架構含義  
**替代方案**：使用精確角色（`Collector`、`Analyzer`、`Service`）  
**文件**：naming-convention.md

### 棄用 D-02：Helper / Utils 命名模式

**棄用日期**：2026-06-27  
**棄用術語**：`XxxHelper`、`XxxUtils`  
**原因**：沒有架構含義；通常掩蓋了職責不清晰的設計  
**替代方案**：根據具體職責命名；如果真的是工具函數，放在 `packages/core/utils/` 並以功能命名（`dateFormat.ts`）  
**文件**：naming-convention.md

### 棄用 D-03：Bot 作為 AI 功能的名稱

**棄用日期**：2026-06-27  
**棄用術語**：`XxxBot` 作為 AI 功能的命名（如 `StockBot`）  
**原因**：`Bot` 特指 Telegram Bot（Application 層），與 AI 推理功能（Agent/Analyzer）混淆  
**替代方案**：AI 推理功能 → `{Domain}Analyzer`；Telegram 相關 → `telegram-bot`（Application）  
**文件**：naming-convention.md, GLOSS-001（Agent 的 Deprecated Names）

### 棄用 D-04：直接 SQL 在業務邏輯中

**棄用日期**：2026-06-27  
**棄用模式**：業務邏輯直接執行 `db.query()`  
**原因**：違反 Repository Abstraction Principle（P-05），阻礙未來資料庫遷移  
**替代方案**：所有資料存取透過 Repository 介面  
**文件**：ADR-0013, architecture-principles.md（P-05）

---

## 開放決策（待確認）

以下決策尚未最終確定，未來可能產生術語或架構變更：

| # | 問題 | 相關 ADR | 預計影響 |
|---|---|---|---|
| OD-01 | V2 選擇 systemd 還是 Docker？ | ADR-0015 | Worker 的部署形態 |
| OD-02 | sqlite-vss Windows 相容性問題 | ADR-0013 | Memory Long-term 的實作 |
| OD-03 | AI-initiated trigger 的 rate limiting 機制 | ADR-0012 | Trigger 和 Scheduler 的行為 |
| OD-04 | V3 選擇哪個雲端平台？ | ADR-0015 | Platform 和 Worker 的部署形態 |
| OD-05 | Event Bus 的 Dead Letter Queue | ADR-0014 | Event 的可靠性保障 |

---

## 版本里程碑

| 版本 | 日期 | 重要事件 |
|---|---|---|
| V0.1 | 2026-06-27 | 架構設計阶段開始：建立 Vision, 15 個 ADR, Glossary v2.0 |
| V1.0 | 待定 | 第一個可運行版本（Windows 環境，Telegram Bot + 至少一個 Domain）|
| V2.0 | 待定 | Distributed-capable（Linux Server 或 Docker）|
| V3.0 | 待定 | Cloud-native（Fly.io / Cloud Run / Kubernetes）|

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，記錄四個架構轉折、四個棄用模式、開放決策與版本里程碑 |
