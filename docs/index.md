---
doc_type: vision
doc_id: INDEX-001
title: PAOS Documentation Index
status: accepted
version: "1.0"
date: 2026-06-27
---

# PAOS 文件總索引

> 這是整個 PAOS 文件系統的入口點。  
> **AI 接手時請從這裡開始閱讀。**

---

## 建議閱讀順序（AI / 新加入者）

```
1. vision-scope.md              → 理解為什麼這個系統存在
2. system/documentation-system.md → 理解文件的規則和格式
3. system/glossary.md           → 統一術語（避免誤解）
4. architecture/platform-blueprint.md → 理解整體系統架構
5. decisions/ADR-000*.md        → 理解所有重要決策的來龍去脈
```

---

## 文件地圖

### 願景與範圍

| 文件 | 說明 | 狀態 |
|---|---|---|
| [vision-scope.md](./vision-scope.md) | PAOS 的願景、範圍、已確認決策與開放問題 | Accepted |

---

### 系統規範

| 文件 | 說明 | 狀態 |
|---|---|---|
| [system/documentation-system.md](./system/documentation-system.md) | 文件格式標準、目錄規範、版本控制規則 | Accepted |
| system/glossary.md | 全局術語表（待建立） | 待建立 |

---

### 架構文件

| 文件 | 說明 | 狀態 |
|---|---|---|
| [architecture/platform-blueprint.md](./architecture/platform-blueprint.md) | 平台分層架構、資料流、Repo 結構建議 | Draft |

---

### Architecture Decision Records（ADR）

| ADR | 標題 | 狀態 |
|---|---|---|
| [ADR-0001](./decisions/ADR-0001-repo-strategy.md) | Repository Strategy | Proposed |
| [ADR-0002](./decisions/ADR-0002-platform-strategy.md) | Platform Strategy | Accepted |
| [ADR-0003](./decisions/ADR-0003-ai-provider-strategy.md) | AI Provider Strategy | Accepted |
| [ADR-0004](./decisions/ADR-0004-knowledge-strategy.md) | Knowledge Strategy | Accepted |
| [ADR-0005](./decisions/ADR-0005-workflow-strategy.md) | Workflow Strategy | Accepted |
| [ADR-0006](./decisions/ADR-0006-memory-strategy.md) | Memory Strategy | Accepted |
| [ADR-0007](./decisions/ADR-0007-notification-strategy.md) | Notification Strategy | Accepted |
| [ADR-0008](./decisions/ADR-0008-validation-strategy.md) | Validation Strategy | Accepted |
| [ADR-0009](./decisions/ADR-0009-security-permission.md) | Security & Permission Strategy | Accepted |
| [ADR-0010](./decisions/ADR-0010-domain-expansion.md) | Domain Expansion Strategy | Accepted |
| [ADR-0011](./decisions/ADR-0011-runtime-strategy.md) | Runtime Strategy | Proposed |
| [ADR-template](./decisions/ADR-template.md) | ADR 模板 | — |

---

### 待建立的文件

| 文件 | 優先級 | 說明 |
|---|---|---|
| system/glossary.md | 🔴 高 | 全局術語表（Memory vs Knowledge 等邊界定義） |
| ADR-0012-data-storage.md | 🔴 高 | 資料儲存策略（OQ-03） |
| ADR-0012-data-storage.md | 🔴 高 | 資料儲存策略（OQ-03） |
| architecture/component-map.md | 🟡 中 | 詳細的元件地圖與依賴關係 |
| guides/add-new-domain.md | 🟡 中 | 如何新增一個 Domain Module |
| guides/setup.md | 🟡 中 | 開發環境設定指南 |

---

## 決策狀態摘要

| 類別 | 已決定 | 待決定 |
|---|---|---|
| 平台策略 | D-02 Dev/Arch/Runtime 三層分離 | OQ-01 Repo 策略 |
| AI Provider | D-03 重度抽象層 | OQ（Runtime 語言） |
| 知識管理 | D-07 六層資訊架構；ADR-0004 審核管線 | OQ-03 儲存後端 |
| 工作記憶 | ADR-0006 三層記憶模型 | OQ-04 Priority Engine 判斷依據 |
| 安全 | D-05/D-06 AI 提議人工確認；禁止自動刪除 | OQ-02 Runtime Strategy |
| Domain 擴充 | ADR-0010 Domain Plugin System | — |

---

*最後更新：2026-06-27*
