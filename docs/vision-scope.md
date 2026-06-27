# PAOS — Vision & Scope

> **文件狀態**：Draft  
> **建立日期**：2026-06-27  
> **下一步**：解決 OQ-01（Repo 策略）、OQ-02（平台策略）後進入架構設計階段

---

## 一、願景陳述

PAOS（Personal AI Operating System）是一個**個人 AI 協作平台與智慧中樞**，作為所有 AI Agent、知識庫、工作流程、自動化與通知的統一協調中心。

> ⚠️ **命名備注**：「Operating System」是比喻，不是傳統作業系統。  
> 建議在 V1 完成後重新評估名稱，候選：**Personal Intelligence Platform（PIP）**、**AI Intelligence Hub**。  
> 在此之前，統一以 **PAOS** 作為工作代號。

---

## 二、核心職責

| 職責模組 | 說明 |
|---|---|
| AI Agent 管理 | 協調多個 AI Provider 與 Agent |
| Workflow 管理 | 定義與執行自動化工作流程 |
| Knowledge Base | 結構化、可查詢的領域知識 |
| Memory | 對話歷史、個人偏好、長期情境 |
| Task 管理 | 待辦、進行中任務、專案追蹤 |
| Notification | 跨管道、經優先級過濾的通知 |
| Decision Support | 優先級引擎（Priority Engine）—— 從雜訊中找出最重要的事 |

---

## 三、使用者範圍

| 版本 | 目標使用者 | 狀態 |
|---|---|---|
| V1 | 個人（單一使用者） | 當前開發階段 |
| V2 | 家人（共用知識庫、提醒、特定領域功能） | 架構必須支援 |
| V3 | 多人、多團隊、SaaS 可能性 | 架構預留，不在 V1 實作 |

**決策 D-08**：V1 以單人為主，但架構從第一天起就必須考慮多人的隔離性（auth、permission、data isolation），避免 V2 時需要大規模重寫。

---

## 四、互動管道藍圖

PAOS 核心與管道無關（channel-agnostic）。所有管道都是**介面卡（Adapter）**，不得將業務邏輯寫入任何特定管道。

| 版本 | 管道 |
|---|---|
| V1 | Claude Projects、ChatGPT（手動協作）、Telegram |
| V2 | Web Dashboard、Web UI |
| V3 | Line、Discord、Gmail、Google Calendar、GitHub |
| V4 | Voice、iOS / Android App、REST API、MCP、Browser Extension |

> ⚠️ **架構師備注（需確認）**：  
> V1 列了「Claude Projects」與「ChatGPT」，但這兩者是**互動式網頁介面**，不是可程式化的管道。  
> 請確認你的意思是：  
> （A）透過 API（Anthropic API / OpenAI API）接入，作為 AI Provider，而非互動管道？  
> （B）V1 先以 Telegram 為唯一程式化管道，Claude/ChatGPT 屬於 Provider 層而非 Channel 層？  
> 這個區分會影響架構的第一層分層設計。

---

## 五、資訊架構（六層記憶模型）

PAOS 以六個層次管理所有資訊，各層有獨立的更新規則與存取權限。

| 層 | 名稱 | 內容範例 | 更新者 |
|---|---|---|---|
| L1 | User Profile | 偏好、常用 AI、通知方式 | 使用者 |
| L2 | Memory | 對話紀錄、想法、備忘、長期目標 | AI + 使用者 |
| L3 | Knowledge | 股票知識、二手商品規則、AI 動態、法律常識 | AI 提議 → 使用者確認 |
| L4 | Task | 進行中任務、待辦清單、專案 | AI + 使用者 |
| L5 | External Data | FB、GitHub、RSS、股市即時資料 | 自動爬取 |
| L6 | Learning | AI 修正紀錄、Prompt 優化紀錄、驗證結果 | AI（自動） |

> ⚠️ **架構師備注**：  
> L2 Memory 與 L3 Knowledge 的邊界需要進一步定義。  
> 建議原則：**Memory 是情境相關的（context-aware）**，會隨時間衰減或更新；**Knowledge 是領域正確的（domain-correct）**，需要明確版本控制與確認機制。  
> 這個邊界不清楚，之後的設計很容易衝突。

---

## 六、AI Provider 策略

**決策 D-03**：採用**重度抽象**（Provider Abstraction Layer）。

- V1 以 Claude 為主要開發工具
- 所有 AI 呼叫都透過統一的 `AIProvider` 介面
- 切換 Provider 不得修改業務邏輯
- 未來支援的 Provider：Claude、ChatGPT (OpenAI)、Gemini、Ollama（本地模型）

---

## 七、AI 權限模型

**原則**：AI 提議，人類確認。核心知識的任何變更，必須經人工審核後才正式生效。

| 動作 | 權限 |
|---|---|
| 收集資料 | ✅ 自動 |
| 分析資料 | ✅ 自動 |
| 發送通知 | ✅ 自動 |
| 新增知識（提議） | ✅ AI 可提議 |
| 修改核心知識（規則、門檻、Workflow） | ⚠️ 需使用者確認 |
| 刪除任何資料 | ❌ 永遠不自動 |
| 自動下單 / 執行金融操作 | ❌ 永遠不自動（V1） |
| 自動發文到社群媒體 | ❌ 永遠不自動（V1） |

---

## 八、Priority Engine（優先級引擎）

這是 PAOS 最核心的差異化價值。

**問題**：每天系統可能處理數百至數千筆資訊，使用者不可能全部看。  
**解法**：優先級引擎將龐大的資訊流過濾成「今天最值得處理的 N 件事」。

**範例情境**：
- AI 動態 500 則
- 股票更新 300 則  
- 二手商品 200 則

→ 優先級引擎輸出：**今天最值得處理的 5 件事**

**開放問題（OQ-04）**：優先級的判斷依據是什麼？
- 規則型（Rule-based）：使用者定義觸發條件
- AI 推斷型（AI-inferred）：根據歷史行為推斷重要性
- 混合型（Hybrid）：規則作為硬性門檻，AI 在門檻內排序

---

## 九、已確認決策

| # | 決策 | 說明 |
|---|---|---|
| D-01 | 架構優先，不急著實作 | 防止第一天就產生技術債 |
| D-02 | 所有設計必須可擴充 | V1 的決策不能阻斷 V2/V3 |
| D-03 | AI Provider 重度抽象層 | 不綁定任何 AI 廠商 |
| D-04 | 核心與管道無關 | Telegram 是 Adapter，不是平台本身 |
| D-05 | AI 提議，人工確認核心變更 | 安全性與可稽核性 |
| D-06 | V1 禁止自動刪除與自動執行 | 信任需要逐步建立 |
| D-07 | 六層資訊架構 | 知識管理的關注點分離 |
| D-08 | 多人架構預留，V1 單人 | 設計考慮未來，不過度工程化當下 |

---

## 十、待確認事項（Open Questions）

| # | 問題 | 優先級 | 備注 |
|---|---|---|---|
| OQ-01 | Repo 策略：Monorepo vs. 多倉庫？ | 🔴 高 | `telegram-talk` 是子系統還是主倉庫？ |
| OQ-02 | 平台策略：Windows-first、雲端、還是跨平台？ | 🔴 高 | 現有腳本全為 .bat / .ps1 |
| OQ-03 | 主要資料儲存方案？ | 🔴 高 | 檔案型、SQLite、Postgres、Notion？ |
| OQ-04 | Priority Engine 的優先級判斷依據？ | 🔴 高 | 規則型、AI 推斷型、混合型？ |
| OQ-05 | 文件標準：格式、位置、版本控制方式？ | 🟡 中 | 本文件是第一個測試案例 |
| OQ-06 | PAOS 如何處理 AI 額度與 Rate Limit？ | 🟡 中 | 已是 telegram-talk 的痛點 |
| OQ-07 | V1 vs V2 的認證策略？ | 🟡 中 | 單人可簡單處理；多人需要正式 Auth |
| OQ-08 | 什麼觸發 Workflow？（事件驅動、排程、手動？） | 🟡 中 | |
| OQ-09 | PAOS 是持續進程（Daemon）還是觸發式（Invocation-based）？ | 🔴 高 | 這影響整個部署模型 |
| OQ-10 | Channel 與 Provider 的邊界如何定義？ | 🔴 高 | 見第四節備注 |

---

## 十一、PAOS 不是什麼

- **不是聊天應用程式**（管道是 Adapter）
- **不是要取代現有工具**（而是協調它們）
- **不是封閉系統**（必須可透過 Plugin/Integration 擴充）
- **不綁定任何 AI 廠商**

---

## 十二、現狀 vs 目標

| 面向 | 現狀（telegram-talk） | 目標（PAOS V1） |
|---|---|---|
| 架構 | 單一管道、單一 AI | 多管道、多 AI、統一協調 |
| 知識管理 | 無 | 六層資訊架構 |
| 平台 | Windows only（.bat / .ps1） | 待定（目標跨平台） |
| Repo 結構 | 單倉庫、扁平結構 | 待定（Monorepo 或結構化多倉庫） |
| 文件 | 只有 README | 持續維護的架構文件集 |

---

*下一個文件建議：解決 OQ-01 與 OQ-02 後，產出 `architecture-overview.md`（系統架構概覽）。*
