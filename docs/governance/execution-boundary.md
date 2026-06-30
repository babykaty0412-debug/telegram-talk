---
doc_type: governance
doc_id: GOVR-009
title: Execution Boundary & Decision Authority
status: accepted
version: "1.0"
date: 2026-06-29
related: [GOVR-002, GOVR-003, GOVR-008, ADR-0009]
tags: [collaboration, autonomy, decision-authority, governance, workflow]
---

# Execution Boundary & Decision Authority

> 定義 AI Architect 與 System Owner 之間的**決策權責邊界**。  
> 目的：在同一個 Milestone 內讓 AI 連續推進，不必每一步都停下確認；  
> 只有遇到真正屬於 Owner 的決策時，才停下來請示。
>
> 這份規則的目標不是「放手」，而是「把停下來的時機，對準真正需要 Owner 判斷的點」。

---

## 一、核心原則（GOVR-009-P1）

> **AI 可以自行完成同一個 Milestone 內的所有工作，不需要每一步都停下確認。**  
> **只有遇到架構決策、ADR 變更、Template 變更、或新增 Core 元件時，才必須停下來請 Owner 決策。**

---

## 二、AI 可自主執行的範圍（Inside the Boundary）

在同一個 Milestone 內，以下工作 AI 可連續完成、不需逐步確認：

| 類別 | 範例 |
|---|---|
| **撰寫 / 修改文件** | Domain 設計、治理文件、審查報告、Roadmap |
| **框架內填寫** | 在既有 Template / ADR / 架構原則的框架內填入實質內容 |
| **修補審查發現** | 修正 Must Fix、Should Improve、Nice-to-Have |
| **衍生記錄更新** | 更新 index、Changelog、Domain Registry、Validation History |
| **版本控制** | commit 並 push 到指定開發分支 |

> 判準：若一項工作只是「在已決定的架構/規格內執行」，就在邊界內，AI 自主完成。

---

## 三、必須停下請示的範圍（On the Boundary）

以下四類事項屬於 Owner 的決策權，AI 必須停下、說明選項與建議，由 Owner 決定：

| # | 觸發點 | 為什麼是 Owner 決策 |
|---|---|---|
| 1 | **架構決策** | 跨 Domain 的結構、分層、通訊模式選擇，影響整個系統 |
| 2 | **ADR 變更** | 新增或修改 ADR 是對「已定案決策」的改動，必須留下 Owner 的批准軌跡 |
| 3 | **Template 變更** | 修改 TMPL-001 結構會影響所有未來 Domain（且受 GOVR-008 的 2-Domain 驗證約束）|
| 4 | **新增 Core 元件** | 新增 Core 規格 / 共用 Service / 跨 Domain 共用文件，是提前抽象化的風險點 |

> 判準：若一項工作會「改變未來所有工作所依賴的基礎」，就在邊界上，必須請示。

---

## 四、邊界上的特別規則

1. **發現 Template 需要改 → 先回報，不自行擴張**  
   若在實作 Domain 時發現 Template 不足，**先回報原因**，由 Owner 決定是否更新 Template。  
   不可繞過 Template、自行新增 Core / 共用文件來補洞。

2. **共用規格由多 Domain 共同需求驅動**  
   Core Spec、共用 Template 等抽象，必須由**至少兩個真實 Domain 的共同需求**證明後才建立，  
   不提前抽象化（與 GOVR-008 的 2-Domain 驗證原則一致）。

3. **文件數量最小化**  
   避免新增「沒有立即價值」的文件。每份新文件都要能回答「現在就有什麼用」。

---

## 五、與其他治理文件的關係

| 文件 | 關係 |
|---|---|
| GOVR-002（審查流程）| Review 的角色分工是本邊界在「審查」情境的具體化 |
| GOVR-003（成熟度模型）| 一個 Milestone 通常對應一次等級晉升；等級晉升的批准屬 Owner |
| GOVR-008（Template 演進）| 「Template 變更需請示」與 GOVR-008 的 Experimental→Stable 流程銜接 |
| ADR-0009（安全權限）| 本邊界不豁免任何安全規則；安全規則永遠優先 |

> **備註**：本規則的內容亦鏡像於 repo 根目錄的 `CLAUDE.md`（供 Claude Code 自動載入；該檔在本 repo 被 gitignore，故以本治理文件為權威來源）。

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-29 | 初版：定義自主執行邊界、四類必須請示事項、邊界特別規則 |
