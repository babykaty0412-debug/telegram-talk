---
doc_type: vision
doc_id: INDEX-001
title: PAOS Documentation Index
status: accepted
version: "1.3"
date: 2026-06-27
---

# PAOS 文件總索引

> 這是整個 PAOS 文件系統的入口點。  
> **AI 接手時請從這裡開始閱讀。**

---

## 建議閱讀順序（AI / 新加入者）

```
1. glossary.md                  → 統一術語（先建立共同語言，避免一切誤解）
2. vision-scope.md              → 理解為什麼這個系統存在
3. system/documentation-system.md → 理解文件的規則和格式（含 ADR Lifecycle）
4. architecture/platform-blueprint.md → 理解整體系統架構
5. decisions/ADR-000*.md        → 理解所有重要決策的來龍去脈
```

---

## 文件地圖

### 通用語言（Ubiquitous Language）

> **所有讀者必讀。** 術語表定義整個系統的共同語言。不讀術語表直接讀其他文件，會產生概念誤解。

| 文件 | 說明 | 狀態 |
|---|---|---|
| [glossary.md](./glossary.md) | PAOS 架構術語表：31 個核心概念、命名規範、概念地圖 | Accepted v1.0 |

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

---

### 架構文件

| 文件 | 說明 | 狀態 |
|---|---|---|
| [architecture/platform-blueprint.md](./architecture/platform-blueprint.md) | 平台分層架構、資料流、Repo 結構建議 | Draft |

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

*最後更新：2026-06-27*  
*ADR 總數：15 份（ADR-0001 ~ ADR-0015），全部 Accepted*  
*Glossary：GLOSS-001 v1.0，31 個核心術語（Accepted）*
