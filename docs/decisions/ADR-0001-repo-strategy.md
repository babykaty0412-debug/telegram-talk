---
doc_type: adr
doc_id: ADR-0001
title: Repository Strategy
status: proposed
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0002]
tags: [infra, repo, monorepo]
---

# ADR-0001: Repository Strategy

## 狀態

`Proposed`（等待確認後改為 Accepted）

## 背景（Context）

PAOS 是一個平台（Platform），而不是單一功能。它將由以下部分組成：
- **Platform Core**：AI Provider 抽象、Knowledge、Memory、Workflow、Notification、Priority Engine
- **Applications / Adapters**：Telegram、Web UI、CLI、Discord、LINE 等
- **Tooling & Docs**：開發工具、架構文件

目前只有 `telegram-talk` 這個 repo，它是一個 Adapter，不是平台本身。  
我們需要決定：如何組織整個平台的程式碼與文件？

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
│   ├── telegram/       ← telegram-talk 遷移至此
│   ├── web/
│   └── cli/
├── docs/               ← 所有架構文件
└── tools/
```

**優點**：
- 單一真實來源（Single Source of Truth）
- 跨 package 重構簡單，影響立即可見
- 統一 CI/CD、統一版本控制
- 早期開發效率高（不需要管理跨 repo 依賴）
- 文件與程式碼在同一個地方，不會脫節

**缺點**：
- Repo 隨時間增大
- 需要工具支援（如 pnpm workspaces、Turborepo）
- 全部 CI 在同一個 pipeline，某個 app 失敗可能阻斷其他

**風險**：工具選擇（monorepo tooling）本身有學習成本。

---

### 選項 B：Multi-repo（多倉庫）

每個 app 和 package 各自一個 repo：

```
paos-core/
paos-ai-provider/
paos-knowledge/
paos-telegram/          ← telegram-talk 改名
paos-web/
```

**優點**：
- 每個 repo 職責清晰
- 各 app 可以獨立 CI/CD、獨立版本
- 大型團隊下，各 team 可以獨立移動

**缺點**：
- 跨 repo 的修改非常麻煩（改 API → 改 core → 改所有 app）
- 文件容易分散，難以維護
- 依賴管理複雜（版本不同步問題）
- 對單人或小團隊不友善

**風險**：這個選項的複雜度遠超過目前 PAOS 的規模需求。

---

### 選項 C：Hybrid（混合策略）

Platform Core 在一個主倉庫，各 App 可選擇留在主倉庫或獨立：

```
paos/                   ← 主倉庫（Platform + Apps）
  packages/core/
  apps/telegram/
  docs/

paos-web/               ← 獨立 repo（未來有獨立團隊時才拆出）
```

**優點**：
- 初期 Monorepo 的效率
- 有明確規則定義何時該拆出（團隊獨立、技術棧完全不同）
- 靈活應對未來情況

**缺點**：
- 需要提前定義「何時拆出」的標準
- 略微增加架構思維負擔

---

## 決策（Decision）

**建議採用選項 C：Hybrid，以 Monorepo 為起點，預留拆分規則。**

實際上，V1/V2 階段將完全以 Monorepo 運作，只有在以下情況才拆出獨立 repo：
- 某個 App 有獨立開發團隊
- 某個 App 的技術棧與其他完全不相容
- 某個 App 需要完全獨立的 release cycle

---

## 決策依據（Rationale）

1. **規模適配**：PAOS 目前是一人開發，Monorepo 的效率優勢最大
2. **架構演進**：Platform Core 與 Apps 在早期高度耦合，Monorepo 讓重構成本最低
3. **文件一致性**：文件與程式碼在同一個倉庫，AI 接手時不需要跨 repo 查詢
4. **拆分保留**：Hybrid 的定義明確，不是「永遠不拆」，而是「有理由才拆」

---

## 後果（Consequences）

### 正面影響
- 統一的 `docs/` 是整個平台的知識庫
- 平台核心變更立即反映到所有 apps
- CI/CD 只需要維護一套

### 負面影響（需接受的取捨）
- `telegram-talk` 這個現有 repo 必須決定：遷移 or 成為 archived
- 新 repo 的命名、位置需要另外決定

### 風險與緩解措施
- **風險**：Monorepo 工具（pnpm/Turborepo）的學習成本
- **緩解**：先不引入工具，用最簡單的目錄結構起步，工具可以後加

---

## 實施原則

1. 主倉庫命名為 `paos`（而不是 `telegram-talk`）
2. 目錄結構：`packages/`（共用 library）、`apps/`（可部署應用）、`docs/`、`tools/`
3. `telegram-talk` 目前的功能遷移至 `apps/telegram/`
4. `packages/core/` 是平台核心，**不得依賴任何 app 的程式碼**
5. 拆分條件：必須文件化並產出新的 ADR

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | 新的 `paos` repo 要建在哪個 GitHub account？ | Open |
| 2 | `telegram-talk` 是 archive 還是轉成 redirect？ | Open |
| 3 | Monorepo 工具：pnpm workspaces、Turborepo、Nx，還是先不用？ | Open（建議：先不用） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，分析三個策略並提出 Hybrid 建議 |
