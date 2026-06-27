---
doc_type: adr
doc_id: ADR-0001
title: Repository Strategy
status: accepted
version: "2.0"
date: 2026-06-27
supersedes: []
related: [ADR-0002]
tags: [infra, repo, monorepo]
---

# ADR-0001: Repository Strategy

## 狀態

`Accepted`（自 2026-06-27）

## 背景（Context）

PAOS 是一個平台（Platform），而不是單一功能。它將由以下部分組成：
- **Platform Core**：AI Provider 抽象、Knowledge、Memory、Workflow、Notification、Priority Engine
- **Applications / Adapters**：各類 Bot（Telegram、LINE、Discord）、Web UI、Dashboard、CLI、API Server
- **Tooling & Docs**：開發工具、架構文件

目前只有 `telegram-talk` 這個 repo，它是一個 Adapter，不是平台本身。  
我們需要決定：如何組織整個平台的程式碼與文件，並支撐 5–10 年的持續擴充？

---

## 考慮的選項

### 選項 A：Monorepo（單一倉庫）

所有 package、apps、docs 都在同一個 repo 下（例如 `paos/`）：

```
paos/
├── packages/
│   ├── core/
│   ├── ai-provider/
│   ├── knowledge/
│   ├── memory/
│   ├── workflow/
│   ├── notification/
│   └── priority-engine/
├── apps/
│   ├── telegram-bot/
│   ├── web-ui/
│   └── cli/
├── docs/
└── tools/
```

**優點**：單一真實來源、跨 package 重構簡單、統一 CI/CD、文件與程式碼不脫節  
**缺點**：Repo 隨時間增大；需要 Monorepo 工具支援  
**風險**：工具選擇本身有學習成本。

---

### 選項 B：Multi-repo（多倉庫）

每個 app 和 package 各自一個 repo。

**優點**：各 repo 職責絕對清晰；各 app 可獨立 CI/CD  
**缺點**：跨 repo 修改非常麻煩；文件分散；依賴版本不同步；對單人不友善  
**結論**：❌ 這個選項的複雜度遠超過目前 PAOS 的規模需求。

---

### 選項 C：Hybrid（Monorepo 為主，條件性拆出）

主倉庫採用 Monorepo，只有在符合明確 Split Criteria 時才拆出獨立 repo：

```
paos/（主倉庫）
├── packages/         ← 共用 library，不可依賴 apps
├── apps/             ← 所有可部署應用（多個 Bot 分別放在子目錄）
├── domains/          ← Domain 模組
├── docs/             ← 所有架構文件
└── tools/            ← 開發工具（Windows watchdog 等）
```

**優點**：起步效率等同 Monorepo；有明確的拆出規則；長期最靈活  
**缺點**：需要嚴格執行 Split Criteria，否則退化為 Multi-repo 的混亂

---

## 決策（Decision）

**採用選項 C：Hybrid Monorepo。**

以 Monorepo 為起點，只有在符合以下 Split Criteria 時，才允許拆出獨立 repo。

---

## Split Criteria（拆分條件）

當一個 App 或模組同時符合以下**任一**條件時，才允許拆出為獨立 repo：

| 條件 | 說明 |
|---|---|
| ① 可獨立部署 | 不依賴主倉庫的 build 流程就能獨立部署 |
| ② 獨立 Release Cycle | 有自己的版本號與 release 節奏，不跟隨主倉庫 |
| ③ 獨立 CI/CD | 需要完全隔離的測試/部署管線 |
| ④ 獨立 Team | 有獨立的開發團隊負責，與主倉庫 team 不重疊 |
| ⑤ 不再依賴 Core | 不再 import 任何 `packages/core` 的程式碼 |

**重要規則**：
- 拆分決策必須以文件記錄（產出新的 ADR），不可靠感覺決定
- 拆出的 repo 需要在主倉庫的 `docs/index.md` 中登記
- 拆出後的 repo 必須維護自己的 `README.md` 和文件

---

## Apps 目錄命名規則

`apps/` 目錄下的子目錄名稱遵循以下命名慣例：

```
apps/
├── telegram-bot/        ← Telegram 使用者 Bot（主要）
├── telegram-admin/      ← Telegram 管理員 Bot（未來）
├── telegram-notify/     ← Telegram 純通知 Bot（未來）
├── web-ui/              ← Web 前端介面
├── dashboard/           ← 管理 Dashboard
├── cli/                 ← 命令列工具
└── api/                 ← REST API Server（外部整合用）
```

**命名原則**：
- 同一個服務（如 Telegram）可能有多個 App，以 `{service}-{role}` 區分
- 不使用單一名詞（如 `telegram`）——因為未來可能有多個 Telegram Bot
- `{role}` 用途：`bot`（使用者互動）、`admin`（管理）、`notify`（純通知）

---

## 決策依據（Rationale）

1. **規模適配**：PAOS 目前是一人開發，Monorepo 的效率優勢最大
2. **架構演進**：Platform Core 與 Apps 在早期高度耦合，Monorepo 讓重構成本最低
3. **文件一致性**：文件與程式碼在同一個倉庫，AI 接手時不需要跨 repo 查詢
4. **Split Criteria**：明確化拆分條件，防止「感覺應該拆」造成不必要的分散

---

## 後果（Consequences）

### 正面影響
- 統一的 `docs/` 是整個平台的知識庫
- 平台核心變更立即反映到所有 apps
- Apps 命名規則支援未來同一服務多個 Bot 的情況

### 負面影響（需接受的取捨）
- `telegram-talk` 這個現有 repo 必須決定：遷移 or 成為 archived
- 主倉庫需要新建（命名為 `paos`）

### 風險與緩解措施

| 風險 | 緩解措施 |
|---|---|
| Monorepo 工具（pnpm/Turborepo）學習成本 | V1 先不引入工具，用最簡單的目錄結構起步，工具按需引入 |
| Split Criteria 未被遵守、悄悄拆出 repo | 所有拆分必須產出 ADR，沒有 ADR 的拆分視為違反本決策 |

---

## 實施原則

1. 主倉庫命名為 `paos`
2. 目錄結構：`packages/`（共用 library）、`apps/`（可部署應用）、`domains/`（Domain 模組）、`docs/`、`tools/`
3. `telegram-talk` 現有功能遷移至 `apps/telegram-bot/`
4. `packages/core/` 是平台核心，**不得依賴任何 app 或 domain 的程式碼**
5. 任何拆分決策必須先參照 Split Criteria，並產出新的 ADR

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | `paos` 主倉庫要建在哪個 GitHub account？ | Open |
| 2 | `telegram-talk` 是 archive 還是轉成 redirect？ | Open |
| 3 | Monorepo 工具：pnpm workspaces、Turborepo、Nx，還是先不用？ | Open（建議：先不用） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，分析三個策略並提出 Hybrid 建議 |
| 2.0 | 2026-06-27 | 新增正式 Split Criteria（5 個條件）；Apps 命名規則（telegram-bot 等）；狀態升為 Accepted |
