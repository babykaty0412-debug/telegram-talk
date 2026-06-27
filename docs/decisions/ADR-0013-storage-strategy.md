---
doc_type: adr
doc_id: ADR-0013
title: Storage Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0004, ADR-0006, ADR-0009, ADR-0011]
tags: [storage, database, persistence, sqlite]
---

# ADR-0013: Storage Strategy

## 狀態

`Accepted`（自 2026-06-27）

## 背景（Context）

PAOS 管理的資料類型非常多樣：
- 對話記憶（短期、長期、工作中）
- 領域知識（版本化、需要審核）
- 任務佇列（需要崩潰安全）
- Audit Log（不可篡改）
- 設定檔（很少改動）
- 外部 API 快取（有 TTL）

不同的資料有不同的讀寫頻率、生命週期、存取模式和一致性要求。如果把所有東西都塞進同一種儲存方案，要麼效能低落，要麼維護複雜。

本 ADR 定義：**哪種資料存在哪裡、為什麼、如何存取。**

---

## 資料分類與對應儲存策略

### 分類 1：Working Memory（工作記憶）

| 屬性 | 說明 |
|---|---|
| 生命週期 | Session 結束即消失 |
| 讀寫頻率 | 極高（每個 AI 呼叫都需要） |
| 一致性要求 | 低（Session 結束就拋棄） |
| **儲存方案** | **In-process Memory（進程記憶體）** |

**理由**：最快的存取方式；Session 結束本來就不需要持久化。  
**風險**：進程重啟即消失，使用者需要重新建立對話情境。

---

### 分類 2：Short-term Memory（短期記憶）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 7–30 天（TTL，可設定） |
| 讀寫頻率 | 中（每次新對話開始時讀取摘要） |
| 一致性要求 | 中 |
| **儲存方案** | **SQLite（含 TTL 欄位）** |

**理由**：SQLite 對個人規模完全夠用；單一檔案便於備份；TTL 欄位讓過期資料自動清除。

---

### 分類 3：Long-term Memory（長期記憶）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 永久，直到明確更新 |
| 讀寫頻率 | 低（按相關性召回） |
| 存取模式 | 語意搜尋（Embedding 相似度） |
| **儲存方案** | **SQLite + sqlite-vss（向量索引）** |

**理由**：sqlite-vss 讓 SQLite 支援向量搜尋，不需要額外的向量資料庫服務；維持單一 SQLite 檔案的簡單性。

**備選方案**（當資料量超過 SQLite 瓶頸）：遷移至 Chroma、Qdrant、Weaviate。

---

### 分類 4：Knowledge Base（知識庫）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 永久，版本化 |
| 讀寫頻率 | 低（按需查詢，偶爾更新） |
| 一致性要求 | 高（每次修改需要 Audit Trail） |
| **儲存方案** | **SQLite（結構化記錄）+ JSON files（Domain Schema 定義）** |

**理由**：Domain Schema（知識的「形狀」定義）以 JSON 文件存儲，可 git diff 追蹤修改；實際的知識記錄在 SQLite 中，支援快速查詢。

---

### 分類 5：Task Queue（任務佇列）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 任務完成即刪除（或保留 N 天的歷史） |
| 讀寫頻率 | 高（Worker 持續 poll / push） |
| 一致性要求 | 高（任務不能遺失，崩潰後可重跑） |
| **儲存方案** | **SQLite（append-only task table）** |

**理由**：SQLite 的 WAL 模式支援並發寫入；任務記錄在 SQLite 中，進程崩潰後可以從 `status = 'pending'` 的任務繼續執行。

---

### 分類 6：Audit Log（稽核日誌）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 永久（不得刪除） |
| 讀寫頻率 | 高寫（每次 AI 行動）、低讀（查詢時） |
| 一致性要求 | 極高（不可篡改） |
| **儲存方案** | **SQLite（append-only table，禁止 UPDATE / DELETE）** |

**理由**：SQLite 的 append-only 設計透過應用層限制實現（禁止 UPDATE/DELETE 語句）；定期匯出為 CSV 快照作為不可變備份。

---

### 分類 7：Configuration（設定）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 永久，很少改動 |
| 讀寫頻率 | 極低（啟動時讀取一次） |
| **儲存方案** | **環境變數（`.env`）+ JSON 設定檔（`config/`）** |

**理由**：符合 12-factor app 原則；`.env` 存放 secrets（不進 git）；`config/*.json` 存放非敏感設定（進 git）。

---

### 分類 8：External Data Cache（外部 API 快取）

| 屬性 | 說明 |
|---|---|
| 生命週期 | 有 TTL（依 API 資料的更新頻率而定） |
| 讀寫頻率 | 中（每次 Collector 執行後更新） |
| **儲存方案** | **SQLite（含 cached_at、expires_at 欄位）** |

**理由**：防止同一份資料在短時間內重複呼叫外部 API；TTL 過期後 Collector 重新抓取。

---

## 儲存方案總覽

| 資料類型 | 儲存方案 | V1 |
|---|---|---|
| Working Memory | In-process Memory | ✅ |
| Short-term Memory | SQLite | ✅ |
| Long-term Memory | SQLite + sqlite-vss | ✅（基礎版） |
| Knowledge Base | SQLite + JSON files | ✅ |
| Task Queue | SQLite | ✅ |
| Audit Log | SQLite（append-only） | ✅ |
| Configuration | .env + config/*.json | ✅ |
| External Cache | SQLite | ✅ |

**V1 核心原則**：**SQLite 作為唯一的持久化後端。** 單一檔案，不需要伺服器，跨平台，易備份。

---

## 儲存抽象層（Storage Abstraction）

所有模組**不得直接執行 SQL 語句**，必須透過對應的 Repository 介面存取資料：

```
Memory Manager  → MemoryRepository  → SQLite
Knowledge Base  → KnowledgeRepository → SQLite + JSON
Task Queue      → TaskRepository    → SQLite
Audit Log       → AuditRepository   → SQLite (append-only)
```

**理由**：如果未來需要從 SQLite 遷移到其他後端（PostgreSQL、DynamoDB），只需要替換 Repository 實作，不需要修改業務邏輯。

---

## 後果（Consequences）

### 正面影響
- V1 只需要一個 SQLite 檔案（加上設定檔），部署極簡單
- 所有持久化資料都可以透過備份這個 SQLite 檔案來保護

### 負面影響（需接受的取捨）
- SQLite 的並發寫入有限制（WAL 模式下可以多讀單寫）
- Long-term Memory 的向量搜尋需要安裝 sqlite-vss 擴充

### 遷移路徑

| 觸發條件 | 遷移方向 |
|---|---|
| SQLite 寫入瓶頸（> 1000 writes/s） | PostgreSQL |
| Long-term Memory 超過 100萬筆 | 獨立向量資料庫（Qdrant） |
| Task Queue 需要分散式 | Redis Streams / BullMQ |

---

## 實施原則

1. 所有 SQL 操作封裝在 Repository 層，禁止在業務邏輯中直接寫 SQL
2. Audit Log 的 Repository 層**只允許 INSERT，禁止 UPDATE 和 DELETE**
3. SQLite 檔案統一放在 `data/paos.db`（路徑透過 `PAOS_DB_PATH` 環境變數設定）
4. 敏感資料（如 API Keys、使用者個資）不存入 SQLite，只存在 `.env`
5. 定期（每日）匯出 Audit Log 為 CSV 快照

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | sqlite-vss 在 Windows 上的安裝複雜度？是否需要替代方案？ | Open |
| 2 | SQLite 檔案的備份策略：手動 vs 自動定期備份？ | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，定義八種資料類型的儲存策略 |
