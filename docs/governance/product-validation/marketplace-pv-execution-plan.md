---
doc_type: governance
doc_id: GOVR-PV-MKT-002
title: Marketplace Product Validation Execution Plan
status: in_progress
version: "1.0"
date: 2026-06-29
domain: marketplace
related: [DOMAIN-001, GOVR-004, GOVR-005, GOVR-006, GOVR-007, GOVR-PV-MKT-001, REV-MKT-001]
tags: [product-validation, execution, golden-dataset, benchmark, replay, marketplace]
---

# Marketplace Product Validation Execution Plan

> Product Validation 是 PAOS 第一次**接觸真實世界**的步驟。  
> 它的全部價值在於：**用真實資料證明 Marketplace 真的能幫使用者找到值得買的二手商品，且比人工搜尋更有效率。**  
>
> 因此這一步**無法當成文件作業完成**——不能用「設計得很完整」代替「在真實資料上被驗證」。  
> 本文件把 Product Validation 變成一個**可真正執行的計畫**，並誠實標示哪些部分需要真實資料與人工輸入。

---

## 〇、進度：Path A Lite Prototype 已建立（2026-06-29）

採用 Path A 的最小版本（**Path A Lite**）：單一平台 Facebook、單一類型二手書，目標只驗證  
「AI 能否正確判斷一篇貼文是否值得通知」。程式碼位於 `prototypes/marketplace-book-mvp/`。

| 項目 | 狀態 |
|---|---|
| 6 步驟管線（解析→判斷商品→判斷價格→WatchRule→通知建議→Confidence）| ✅ 已實作 |
| 確定性部分（Parser / WatchRuleMatcher / Notification）| ✅ 已驗證（`npm run dry` 端到端跑通 + `tsc` 通過）|
| AI 判斷步驟（透過 AIProvider 介面 P-07；Provider 與模型由執行環境決定）| ⏳ 已實作，**待擁有金鑰的執行環境執行** |
| Template v1.1 是否需要修改 | ❌ 否（MVP 僅用既有設計，無新缺口）|

> 說明：依 **P-14（機密永不離開執行環境）**，金鑰不交給 AI、不進對話、不進文件。  
> 由 **System Owner 在本機執行**（路線 1）：在自己的環境設定 Provider 金鑰後 `npm start`，  
> 產生真實判斷，回傳結果共同 Review。這成為下方 #6 Price Analysis Accuracy 的種子。

---

## ⚠️ 一、目前狀態（誠實聲明）

**狀態：Blocked — 等待真實世界輸入。**

Product Validation 尚無法產出真實結果，因為它依賴以下**無法由 AI 憑空產生**的輸入：

| 缺少的輸入 | 為什麼不能由 AI 產生 | 由誰提供 |
|---|---|---|
| **真實 Marketplace 資料** | 目前無 Collector 程式碼，repo 內無真實 listing | 實作 Collector，或人工/工具蒐集真實 listing |
| **獨立的人工 Ground Truth** | 若由 AI 同時產生資料、標註答案、再評分 → 等於「改自己的考卷」，準確率無意義 | **使用者親自標註**（GOVR-006 要求 ≥ 50%）|
| **真實 Manual Baseline** | 那是使用者親自瀏覽各平台 2 週的實測時間/結果 | **使用者實測**或提供既有經驗數據 |
| **可執行的 Analyzer** | Replay 需要實際對真實資料跑 AI 推理 | Path A 的薄原型，或 Path B 的 API 直呼 |

> **本計畫不會產出任何「捏造的準確率數字」。** 任何 Precision / Recall / 通過判定，都必須來自對真實資料、獨立標註的實際量測。

---

## 二、兩條可行的執行路徑

要讓 Product Validation 真正跑起來，選擇其一：

### Path A — 薄原型（Thin Prototype）

實作最小可運行的管線（單一平台，如 Shopee；硬編碼一個 WatchRule；無錯誤處理），足以：
- 真實抓取 listing（真實 Collector）
- 真實解析（真實 Parser）→ 可量測 **Parser Accuracy**
- 真實呼叫 AI 分析（透過 AIProvider 介面；Provider 與模型由執行環境提供，預設 claude-haiku-4-5）→ 可量測 **Price Analysis Accuracy**
- 真實偵測售出（重複抓取同一 URL）→ 可量測 **Sold Detection Accuracy**
- 真實渲染通知 → 可量測 **Notification Accuracy**

> ⚠️ 實作屬於「寫程式」，且建立薄原型需要 Owner 同意進入實作階段（見 GOVR-PV-MKT-001 Phase 3 Prototype）。這超出目前「純架構/治理」範圍，需 Owner 決策。

### Path B — 資料 + 人工標註的 Dry-Run（不寫程式）

不實作完整系統，改用以下方式取得真實但有限的驗證：
1. **蒐集真實 listing**：由使用者提供，或（若網路政策允許）由 AI 用 Web 工具抓取 30 筆真實公開 listing 的原始資料。
2. **使用者獨立標註** Ground Truth（DealScore、verdict、is_good_deal、risk_flags）→ 形成 Golden Dataset V1.0。
3. **AI 盲測 Replay**：AI 在**看不到標註**的情況下對同一批資料做分析。
4. **計算真實準確率**：比對 AI 輸出 vs 使用者標註。

> ⚠️ **模型告誡**：Dry-Run 中執行分析的是當前對話模型，**非生產目標 claude-haiku-4-5**。  
> 故 Path B 屬於 GOVR-007 定義的「設計原型評估」，可作為 Level 3 入場參考，但不等於生產效能。

> ⚠️ **獨立性鐵律**：標註（Ground Truth）與分析（Replay）**必須由不同主體完成**。  
> 使用者標註、AI 分析 → 有效。AI 同時標註與分析 → **無效，禁止**。

---

## 三、八項驗證的操作化定義

每一項都定義：量測什麼、Ground Truth 來源、指標、通過門檻、現況。

| # | 驗證項目 | 量測內容 | Ground Truth 來源 | 指標 | 通過門檻 | 現況 |
|---|---|---|---|---|---|---|
| 1 | **Golden Dataset 建立** | ≥ 30 筆真實、已標註 listing | 使用者標註 | 筆數 + 分布達標（GOVR-006）| 30 筆，分布符合 §五 | ⏳ 待真實資料 + 標註 |
| 2 | **Manual Baseline** | 人工搜尋的時間/覆蓋/準確/認知負擔 | 使用者 14 天實測 | 4 維度基準值（GOVR-005）| 完成 14 天記錄 | ⏳ 待使用者實測 |
| 3 | **Replay 驗證** | AI 對 Golden Dataset 的分析準確率 | Golden Dataset 標註 | Precision / Recall / F1 | Lvl3：P≥65% R≥50% F1≥0.56 | ⏳ 待 #1 完成 |
| 4 | **Parser Accuracy** | 解析欄位是否正確 | 原始資料的客觀值 | 欄位正確率 | ≥ 95% 必填欄位正確 | ⏳ 待 Path A 或真實原始資料 |
| 5 | **Sold Detection Accuracy** | 售出/下架偵測是否正確 | 平台實際狀態（人工核對）| Precision / Recall | P≥90%，無誤報 active→sold | ⏳ 待 Path A（需時間序列）|
| 6 | **Price Analysis Accuracy** | DealScore/verdict 是否符合人工判斷 | 使用者標註 | verdict Precision；DealScore 對人工排序 Spearman | verdict P≥65%；Spearman≥0.6 | ⏳ 待 #1 完成 |
| 7 | **Notification Accuracy** | 通知是否該發、格式/優先級正確、無重複 | 規則 + 使用者接受度 | 規則正確率；Alert Acceptance | 規則 100% 正確；Acceptance≥60% | ⏳ 待 Path A 或 Dry-Run 渲染 |
| 8 | **End-to-End Workflow** | marketplace-scan 全流程是否產出正確結果 | 上述各項組合 | 流程完成率 + 各步正確 | 端到端跑通 + 各項達標 | ⏳ 待 Path A |

> **可在 Path B（不寫程式）下取得真實結果的項目**：#1、#2、#3、#6，以及 #7 的「規則正確性」部分。  
> **需要 Path A（薄原型）才能真實量測的項目**：#4 Parser（需跑解析程式）、#5 Sold Detection（需時間序列重抓）、#8 端到端、以及 #7 的時效/重複部分。

---

## 四、量測指標公式（引用 GOVR-005 / GOVR-007）

```
Precision = 正確判為「好物」的數量 / AI 判為「好物」的總數
Recall    = 正確判為「好物」的數量 / 實際「好物」的總數（標註）
F1        = 2 × P × R / (P + R)
Spearman  = AI 的 DealScore 排序 與 人工排序 的等級相關係數（−1~1）
MAE       = mean(|AI_deal_score − annotated_deal_score|)
Alert Acceptance = 使用者標記「這通知有用」的數量 / 總通知數
```

---

## 五、Golden Dataset 建立計畫（驗證 #1）

詳細結構與標註規範見 GOVR-006；資料檔位於：  
`docs/governance/golden-datasets/marketplace/golden-dataset-v1.0.json`（目前為**待標註骨架**，`entries: []`）

### 完成步驟

```
1. 蒐集     → 30 筆真實 listing 原始資料（Shopee 15 / Yahoo 10 / Ruten 5）
2. 篩選     → 確保分布：5 verdict 各 6 筆；5 類別各 ≥ 6 筆；難度 40/40/20
3. 必含難案 → ≥ 11 筆 hard cases（3 明顯詐騙 / 3 疑惑低價 / 2 描述不符 / 2 無照片 / 1 新賣家好價）
4. 標註     → 使用者依 GOVR-006 決策樹標註，annotation_reason ≥ 20 字
5. 審查     → Final Approver 抽查 ≥ 20%
6. 發布     → 版本 v1.0，status: published
```

### 完成驗收（DoD）

- [ ] entries 達 30 筆真實資料
- [ ] 分布符合 §五 目標
- [ ] hard cases ≥ 11 筆
- [ ] 每筆有 annotator、annotation_confidence、annotation_reason
- [ ] Final Approver 抽查通過

---

## 六、Manual Baseline 量測工具（驗證 #2）

> 使用者親自執行；AI 無法代填。建議連續 14 天，記錄「不靠 PAOS、純人工搜尋」的真實狀況。

### 14 天量測記錄表（使用者填寫）

| 日期 | 搜尋平台 | 搜尋次數 | 投入時間(分) | 看過的 listing 數 | 找到的好物數 | 備註 |
|---|---|---|---|---|---|---|
| D1 | | | | | | |
| D2 | | | | | | |
| ... | | | | | | |
| D14 | | | | | | |

### Baseline 彙總（14 天後計算，對應 GOVR-005 四維度）

| 維度 | 量測 | 值 |
|---|---|---|
| **Time Investment** | 平均每週投入分鐘數 | |
| **Coverage** | 每次搜尋平均看過的 listing 數 | |
| **Accuracy** | 人工判斷好物的命中比例（事後回看）| |
| **Cognitive Load** | 主觀疲勞度（1–5）+ 漏看好物的感受 | |

---

## 七、最終產出（驗證跑完後產生，非現在）

以下三份報告是 Product Validation **執行完成後**的產物。在取得真實量測前不產生空殼。

| 報告 | 內容 | 產出時機 |
|---|---|---|
| **Product Validation Report** | 8 項驗證的真實結果 + 是否通過 PV Gate（PV-G1~G8）+ Level 3 入場判定 | Replay + 各準確率量測完成後 |
| **Benchmark Report（AI vs Manual）** | AI 對比 Manual Baseline 的 4 維度 + 5 個 Win / 3 個 Fail 條件判定（GOVR-005）| Manual Baseline + AI 量測都完成後 |
| **Lessons Learned** | 真實資料暴露的設計問題、Prompt/Knowledge 調整、對 Template 的回饋 | 驗證過程中持續記錄，結束時定稿 |

> 報告路徑（產出時）：`docs/governance/product-validation/marketplace-pv-report.md` 等。

---

## 八、誠信規則（Integrity Rules）

1. **不捏造指標**：任何準確率/通過判定必須來自真實量測，不得估算或虛構。
2. **標註與分析分離**：Ground Truth 由使用者提供，AI 不得同時標註與分析同一資料。
3. **模型透明**：若 Replay 使用非生產模型，必須在報告中標明，結果僅作設計原型評估。
3b. **機密永不離開執行環境（P-14）**：金鑰只在執行環境（環境變數 / Secret Manager）；不交給 AI、不進對話、不進文件、不進 Git。驗證不得要求把金鑰交給第三方。
4. **失敗照實報告**：若 AI 準確率不達門檻，照實記錄並進入 GOVR-007 根因分析，不美化。
5. **若過程需改 Template**：先回報原因 → Owner 決定 → 記錄到 GOVR-008 Template Evolution History（不自行擴張）。

---

## 八之一、AI Provider 抽象與機密管理（P-14）

> Product Validation 驗證的是**平台能力**，不是特定 API。流程因此不綁定任何 AI 廠商或模型。

| 設計點 | 規則 |
|---|---|
| **AI Provider 由執行環境提供** | 業務邏輯只依賴 `AIProvider` 介面（P-07）。Provider 以環境變數選擇（`MARKETPLACE_MVP_PROVIDER`，預設 anthropic）。新增廠商 = 新增一個實作 `AIProvider` 的類別，不改 Domain 邏輯。|
| **模型由執行環境提供** | 模型以環境變數指定（`MARKETPLACE_MVP_MODEL`，預設 claude-haiku-4-5）。驗證流程不寫死模型。|
| **金鑰由環境變數 / Secret Manager 管理** | 各 Provider 自行從執行環境讀取自己的憑證。呼叫端**不傳入明文金鑰**。|
| **機密永不離開執行環境（P-14）** | 金鑰不寫入 Git、文件、AI 對話；`.env` 一律 gitignore，只提交 `.env.example`（無值）。|

**目前實例**：以 Anthropic 作為 Provider、claude-haiku-4-5 作為模型，完成 Marketplace MVP 驗證。  
這是**目前的一個實例，不是唯一方案**——文件與流程均不假設 Anthropic 是唯一選擇。

---

## 九、Template 影響追蹤

> 本次 Product Validation 若暴露 Template v1.1 的不足，記錄於此並回報 Owner，再決定是否更新 TMPL-001（依 GOVR-008 / GOVR-009）。

| 日期 | 發現 | 是否需改 Template | 處理 |
|---|---|---|---|
| （尚無）| — | — | — |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-29 | 初版：誠實狀態聲明、兩條執行路徑、8 項驗證操作化、Golden Dataset 計畫、Manual Baseline 量測工具、產出報告定義、誠信規則 |
