---
doc_type: adr
doc_id: ADR-0002
title: Platform Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0001]
tags: [platform, runtime, cross-platform]
---

# ADR-0002: Platform Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 的目標是長期維護的 AI 平台。目前開發環境是 Windows，現有的腳本（`.bat`、`.ps1`）完全依賴 Windows。

我們需要明確定義：開發環境、架構設計、Runtime 三個層次各自的平台策略。否則，Windows-first 的開發決策會不知不覺滲透進架構與部署，造成日後難以移植的技術債。

---

## 三層平台策略

PAOS 明確區分三個層次，每個層次有不同的平台要求：

---

### 層 1：Development Environment（開發環境）

**策略：Windows First，允許使用 Windows 工具**

- 開發過程中可以使用 PowerShell、Windows Terminal、WSL2
- 腳本工具（watchdog、health check）可以是 `.ps1` 或 `.bat`
- 不需要在開發環境強制跨平台

**理由**：開發者工具是個人偏好，強制跨平台只增加開發摩擦，沒有實質收益。

**約束**：
- 開發環境工具（`tools/`）和 `apps/` 的 Windows 腳本明確放在 `tools/windows/` 或標記為 dev-only
- 不能讓 dev 腳本的邏輯洩漏進 runtime 程式碼

---

### 層 2：Architecture（架構設計）

**策略：完全平台無關（Platform Agnostic）**

架構層的設計原則：

| 禁止 | 允許 |
|---|---|
| 硬編碼的 Windows 路徑（`C:\`、`E:\`） | 環境變數（`process.env.PAOS_DATA_DIR`） |
| 作業系統 API（Windows Registry、WMI） | 跨平台 Runtime API（Node.js fs、path） |
| `.exe`、`.bat` 特定邏輯 | 啟動命令透過 config 注入 |
| 程式碼內的 `\\` 路徑分隔符 | `path.join()` |

**理由**：架構決策的影響面最大、修改成本最高。一旦架構綁定 Windows，移植成本是全部重寫。

---

### 層 3：Runtime（執行環境）

**策略：跨平台目標（Windows → Linux → Docker）**

支援的 Runtime 目標：

| 階段 | Runtime | 說明 |
|---|---|---|
| V1 | Windows（直接執行） | 目前開發環境，也是 V1 的主要部署目標 |
| V2 | Linux（VPS / 雲端） | 24/7 服務需要 Linux 主機 |
| V2 | Docker | 可攜帶的部署方式，跨平台的終極解答 |
| V3 | Kubernetes / Cloud | 未來 SaaS 的可能性 |

**實施要求**：
- 所有 runtime 設定透過**環境變數**或**設定檔（JSON/YAML）**注入
- 不同環境的設定以 `config/` 目錄管理，不寫死在程式碼內
- Docker 支援從 V2 開始，但架構從 V1 起就不能阻礙 Docker 化

---

## 決策（Decision）

**開發環境 Windows First；架構完全平台無關；Runtime 目標為跨平台（Windows → Linux → Docker）。**

三層分離，互不干涉。

---

## 決策依據（Rationale）

1. **開發效率**：現有工具（PowerShell watchdog、bat 啟動腳本）繼續使用，不強制改寫
2. **架構乾淨**：防止 Windows 假設滲透進核心邏輯，避免未來移植成本
3. **部署靈活**：V1 Windows、V2 可以移到 Linux VPS 或 Docker，不需要重寫業務邏輯

---

## 後果（Consequences）

### 正面影響
- V1 可以快速使用現有 Windows 工具
- V2 遷移到 Linux/Docker 不需要修改核心邏輯
- 未來協作者可以在 Mac/Linux 開發

### 負面影響（需接受的取捨）
- 現有 `.bat`/`.ps1` 的邏輯必須被視為「dev tooling」，不能成為業務邏輯的一部分
- 需要一個明確的「平台適配層」（Platform Adapter）來包裝 OS-specific 操作

### 風險與緩解措施

| 風險 | 緩解措施 |
|---|---|
| 開發者無意間用了 Windows-only API | Code review checklist + 架構文件明確列出禁止項目 |
| 設定管理複雜化（多環境） | 使用 `.env` 加 `config/` 目錄，環境切換靠 `NODE_ENV` 或 `PAOS_ENV` |

---

## 實施原則

1. **Runtime 語言選擇**：Runtime 必須選擇跨平台的語言（Node.js/Bun/Python/Go）。不可以用 PowerShell 作為 runtime 語言（可以作為 dev 工具）
2. **路徑處理**：所有路徑使用 `path.join()` 或語言自帶的跨平台路徑工具
3. **進程管理**：Windows 的 watchdog（`.ps1`）只負責重啟服務，不負責業務邏輯。V2 以後改為 systemd / Docker restart policy
4. **設定注入**：`PAOS_ENV=development | production | docker`，所有環境差異透過此變數分支

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | Runtime 主要語言：Node.js 還是 Bun？（目前 telegram-talk 已用 Bun） | Open |
| 2 | V2 的部署目標：自建 VPS 還是 PaaS（Fly.io / Railway）？ | Open（不影響 V1） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，定義三層平台策略 |
