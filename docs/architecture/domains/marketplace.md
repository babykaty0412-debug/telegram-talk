---
doc_type: domain
doc_id: DOMAIN-001
title: Marketplace Domain
status: accepted
version: "1.1"
date: 2026-06-29
maturity_level: 2
template_version: "1.1"
related: [GLOSS-001, ADR-0004, ADR-0005, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0014, TMPL-001, GOVR-008, REV-MKT-001]
tags: [domain, marketplace, secondhand, ecommerce, shopee, yahoo-auctions]
---

# Marketplace Domain

## 狀態

`Accepted`（自 2026-06-27）｜成熟度 **Level 2（Validated）**（自 2026-06-29，見 REV-MKT-001）｜對齊 Template **v1.1**

---

## 1. Purpose（目的）

**核心目的**：  
監控多個二手交易平台（Shopee、Yahoo 拍賣、露天拍賣等）的商品列表，在符合使用者追蹤條件的好物出現時即時告知。

**使用者價值**：  
使用者有多個長期想找的商品（LEGO 特定系列、特定鏡頭、二手書）但無法全天候盯著各平台。Marketplace Domain 代替使用者持續監控，只在真正「值得注意」的商品出現時才通知，避免資訊噪音。

**為什麼是獨立 Domain，不是 Stocks 或其他 Domain 的一部分**：  
Marketplace 的資料來源（多平台爬蟲）、核心概念（Listing、WatchRule、Condition、DealScore）和業務規則（二手定價邏輯、平台差異、詐騙偵測）完全不同於股票追蹤或新聞監控，且未來商品類別可以無限擴充，是一個獨立的業務邊界。

> ⚠️ **命名說明**：Domain 命名為 `marketplace`（市場）而非 `secondhand`（二手），原因是未來可能追蹤全新商品的特賣、預購或限量商品，不限於二手。

---

## 2. Scope（範圍）

### In Scope（本 Domain 負責）

- 定期掃描各平台的新商品列表
- 依使用者設定的 WatchRule 過濾相關商品
- AI 評估商品是否為「值得注意的好物」（DealScore）
- 偵測可疑詐騙商品（明顯低價、描述可疑）
- 發出即時通知（高分商品）或批次摘要（日常監控）
- 管理商品狀態（上架 → 已售出 / 已下架）
- 維護各商品類別的市場行情知識

### Out of Scope（明確不負責）

- 自動購買或出價（不做任何寫入操作到外部平台）
- 管理使用者的購買記錄（由未來的 Finance Domain 負責）
- 比較全新商品的電商售價（全新商品僅在明顯優惠時提及）
- 追蹤賣家的歷史記錄（賣家評分只讀取平台現有資料）

### 版本邊界

| 功能 | V1 | V2 | V3 |
|---|---|---|---|
| Shopee 商品掃描 | ✅ 包含 | — | — |
| Yahoo 拍賣監控 | ✅ 包含 | — | — |
| 露天拍賣監控 | ✅ 包含 | — | — |
| WatchRule 管理（Telegram 指令） | ✅ 基礎 | — | — |
| AI 好物評分（DealScore） | ✅ 包含 | — | — |
| 詐騙偵測 | ✅ 基礎規則 | ✅ AI 強化 | — |
| Facebook Marketplace | ❌ 需要登入 | ✅ 計劃 | — |
| 價格走勢分析 | ❌ | ✅ 計劃 | — |
| 跨平台同款商品比較 | ❌ | ❌ | ✅ 考慮 |
| 賣家信譽追蹤 | ❌ | ✅ 考慮 | — |
| 自動出價策略（Yahoo 拍賣） | ❌ 永不做 | — | — |

---

## 3. Core Concepts（核心概念）

以下概念僅在本 Domain 使用，不在全域 Glossary 中。

| 概念 | 定義 | 說明 |
|---|---|---|
| **Listing** | 在特定平台上一個商品的一個特定銷售條目 | 同一個商品在兩個平台上是兩個不同的 Listing |
| **Platform** | 提供二手買賣功能的網路平台 | shopee / yahoo_auction / ruten / facebook / carousell |
| **Condition** | 商品的實體狀況，標準化為五個等級 | new / like_new / good / fair / poor |
| **WatchRule** | 使用者定義的商品追蹤條件 | 包含關鍵字、最高價格、最低狀況等條件 |
| **DealScore** | AI 對「這個 Listing 有多值得購買」的評分（0.0–1.0）| 綜合市場行情、商品狀況、賣家信譽等 |
| **MarketPrice** | 某商品在當前市場的參考行情價格 | 存在 Knowledge 中，由使用者維護或 AI 建議 |
| **PriceRatio** | Listing 的 total_price / MarketPrice | 低於 0.6 = 疑似好物或疑似詐騙 |
| **ConditionNorm** | 平台特定描述到標準 Condition 的轉換規則 | 「八成新」→ like_new；「七成新」→ good（Knowledge 驅動，見 Section 11）|

---

## 4. Business Rules（業務規則）

### 資料有效性規則

| 規則 ID | 規則描述 | 錯誤處理 |
|---|---|---|
| BR-MKT-01 | total_price = price + shipping_cost | 計算欄位，Parser 自動計算 |
| BR-MKT-02 | price 和 shipping_cost 必須 ≥ 0 | 小於 0 → 丟棄整筆 |
| BR-MKT-03 | title 不可為空 | 空 title → 丟棄整筆 |
| BR-MKT-04 | platform + platform_listing_id 組合必須唯一 | 重複 → 更新現有記錄的 last_seen_at |
| BR-MKT-05 | condition 必須映射到標準五級 | 無法映射 → 設為 unknown |

### 業務邏輯規則

| 規則 ID | 規則描述 | 觸發條件 |
|---|---|---|
| BR-MKT-10 | DealScore ≥ 0.8 AND 符合 WatchRule → 立即 P1 通知 | Analyzer 完成後 |
| BR-MKT-11 | DealScore 0.5–0.8 AND 符合 WatchRule → 加入每日批次 P2 通知 | Analyzer 完成後 |
| BR-MKT-12 | price < MarketPrice × 0.35 → 疑似詐騙，標記 risk flag | L1 Validator |
| BR-MKT-13 | 同一 WatchRule 的相同 Listing 不重複通知（24 小時 Cooldown）| Notification Dispatcher |
| BR-MKT-14 | 一個 WatchRule 在同一天最多發 3 次 P1 通知 | Notification Dispatcher |
| BR-MKT-15 | Listing status 變為 sold/removed → 停止對此 Listing 的後續通知 | 每日狀態檢查後 |

### 限制規則

| 規則 ID | 規則描述 | 原因 |
|---|---|---|
| BR-MKT-20 | Collector 不得在同一來源的請求間隔少於 30 秒 | 避免觸發平台反爬蟲機制 |
| BR-MKT-21 | 每個 WatchRule 每次掃描最多處理 100 筆 Listing | 控制 AI 分析成本 |
| BR-MKT-22 | 超過 90 天未更新的 Listing 自動標記為 unknown status | 減少陳舊資料 |
| BR-MKT-23 | 單次 marketplace-scan Workflow 的 AI 呼叫總數上限 500 次 | 控制總分析成本（對應 REV-MKT-001 R-04）|

---

## 5. Data Sources（資料來源）

| 來源名稱 | 類型 | 認證方式 | 建議頻率 | 穩定性 | 說明 |
|---|---|---|---|---|---|
| Shopee Taiwan | Scraping（非公開 API）| None（公開頁面）| 每 30 分鐘 | Medium | 格式偶爾改變 |
| Yahoo 奇摩拍賣 | RSS + HTML Scraping | None | 每 30 分鐘 | High | RSS 格式穩定 |
| 露天拍賣 (Ruten) | RSS + API | None | 每 30 分鐘 | Medium | |
| Facebook Marketplace | Scraping（需登入）| Session Cookie | 每 60 分鐘 | Low | V2 實作 |

### 頻率設定原則

- Shopee：每 30 分鐘一次，每次請求間隔 ≥ 2 秒，使用隨機 User-Agent
- Yahoo/露天：RSS 每 30 分鐘，HTML 補充爬取間隔 ≥ 5 秒
- 若偵測到 HTTP 429 → 停止當次掃描，下次延遲 2 倍間隔（最多 2 小時）

---

## 6. Data Model（資料模型）

### 主要 Entity：Listing

```typescript
interface Listing {
  id: string                  // UUID

  // 來源資訊
  platform: 'shopee' | 'yahoo_auction' | 'ruten' | 'facebook' | 'carousell'
  platform_listing_id: string // 平台上的原始 ID（確保唯一性）
  url: string

  // 商品資訊
  title: string
  description: string | null
  condition: 'new' | 'like_new' | 'good' | 'fair' | 'poor' | 'unknown'
  condition_raw: string | null  // 原始描述（「八成新」）保留以供審核
  category: 'books' | 'lego' | 'electronics' | 'cameras' | 'furniture' | 'other'
  subcategory: string | null   // 更細分類（「相機 > 單眼相機」）
  images: string[]             // URL 陣列

  // 價格資訊
  price: number                // TWD，賣家標價
  shipping_cost: number        // TWD，0 = 免運
  total_price: number          // price + shipping_cost（計算欄位）

  // 賣家資訊
  seller_id: string | null
  seller_name: string | null
  seller_rating: number | null // 0.0–5.0

  // 地點
  location: string | null      // 縣市（「台北市」）

  // 狀態與時間
  status: 'active' | 'sold' | 'removed' | 'unknown'
  listed_at: string | null     // 商品刊登時間（ISO 8601）
  last_seen_at: string         // 最後一次確認仍在架上（ISO 8601）
  raw_hash: string             // 原始資料的 hash，偵測商品資訊變更

  created_at: string
  updated_at: string
}
```

### 主要 Entity：WatchRule

```typescript
interface WatchRule {
  id: string

  // 規則基本資訊
  name: string                 // 使用者命名（「找 LEGO 城市系列」）
  category: 'books' | 'lego' | 'electronics' | 'cameras' | 'furniture' | 'other' | null
                               // null = 所有分類

  // 搜尋條件
  keywords: string[]           // 必須在 title 或 description 中包含至少一個
  exclude_keywords: string[]   // 必須不包含（排除「零件」「損壞」等）
  max_total_price: number | null  // 含運費上限（null = 無限制）
  min_condition: 'new' | 'like_new' | 'good' | 'fair' | 'poor' | null
  platforms: ('shopee' | 'yahoo_auction' | 'ruten' | 'facebook')[]
             // 空陣列 = 所有平台

  // 觸發設定
  min_deal_score: number       // 最低 DealScore（預設 0.6）
  notification_priority: 'P1' | 'P2' | 'P3'  // 符合時的通知優先級

  // 狀態
  is_active: boolean
  last_triggered_at: string | null

  created_at: string
  updated_at: string
}
```

### 次要 Entity：ListingAnalysis

```typescript
interface ListingAnalysis {
  id: string
  listing_id: string           // FK to Listing

  // AI 分析結果
  deal_score: number           // 0.0–1.0（綜合評分）
  value_verdict: 'great_deal' | 'good_deal' | 'fair_price' | 'overpriced' | 'suspicious'
  condition_assessment: string // AI 對商品狀況描述的解讀
  risk_flags: RiskFlag[]       // 風險標記
  reason: string               // AI 的推理說明（給使用者看）
  confidence: number           // 0.0–1.0

  // 分析參考資訊
  market_price_reference: number | null  // 分析時使用的市場行情價
  price_ratio: number | null   // total_price / market_price_reference

  // AI 模型資訊
  model_used: string           // 實際使用的 AI 模型

  created_at: string
}

type RiskFlag =
  | 'price_suspiciously_low'   // 低於市場價 35% 以下
  | 'vague_description'        // 描述過於模糊（可能隱瞞問題）
  | 'new_seller'               // 賣家評價不足 10 筆
  | 'no_images'                // 沒有商品圖片
  | 'condition_mismatch'       // 標示狀況與描述文字不符
  | 'possible_replica'         // 可能是仿製品（AI 判斷）
```

### SQLite Table 設計

```sql
-- Listings
CREATE TABLE marketplace_listings (
  id TEXT PRIMARY KEY,
  platform TEXT NOT NULL,
  platform_listing_id TEXT NOT NULL,
  url TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  condition TEXT NOT NULL DEFAULT 'unknown',
  condition_raw TEXT,
  category TEXT NOT NULL DEFAULT 'other',
  subcategory TEXT,
  images TEXT NOT NULL DEFAULT '[]',  -- JSON array
  price REAL NOT NULL,
  shipping_cost REAL NOT NULL DEFAULT 0,
  total_price REAL NOT NULL,
  seller_id TEXT,
  seller_name TEXT,
  seller_rating REAL,
  location TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  listed_at TEXT,
  last_seen_at TEXT NOT NULL,
  raw_hash TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(platform, platform_listing_id)
);

CREATE INDEX idx_listings_status ON marketplace_listings(status);
CREATE INDEX idx_listings_category ON marketplace_listings(category);
CREATE INDEX idx_listings_total_price ON marketplace_listings(total_price);
CREATE INDEX idx_listings_last_seen ON marketplace_listings(last_seen_at);

-- Watch Rules
CREATE TABLE marketplace_watch_rules (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  keywords TEXT NOT NULL DEFAULT '[]',     -- JSON array
  exclude_keywords TEXT NOT NULL DEFAULT '[]',
  max_total_price REAL,
  min_condition TEXT,
  platforms TEXT NOT NULL DEFAULT '[]',    -- JSON array
  min_deal_score REAL NOT NULL DEFAULT 0.6,
  notification_priority TEXT NOT NULL DEFAULT 'P2',
  is_active INTEGER NOT NULL DEFAULT 1,
  last_triggered_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Listing Analyses
CREATE TABLE marketplace_listing_analyses (
  id TEXT PRIMARY KEY,
  listing_id TEXT NOT NULL REFERENCES marketplace_listings(id),
  deal_score REAL NOT NULL,
  value_verdict TEXT NOT NULL,
  condition_assessment TEXT NOT NULL,
  risk_flags TEXT NOT NULL DEFAULT '[]',   -- JSON array
  reason TEXT NOT NULL,
  confidence REAL NOT NULL,
  market_price_reference REAL,
  price_ratio REAL,
  model_used TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_analyses_listing ON marketplace_listing_analyses(listing_id);
CREATE INDEX idx_analyses_deal_score ON marketplace_listing_analyses(deal_score);
```

---

## 7. Repository Interfaces（資料存取介面）

> 對應 P-05。業務邏輯不直接寫 SQL；所有資料存取透過以下介面。Repository 不含業務邏輯，不跨 Domain 查詢。

| Repository | 負責 Entity | 關鍵方法 |
|---|---|---|
| `ListingRepository` | `Listing` | findById / save / findByPlatformId / findActiveOlderThan / findSimilar / updateStatus |
| `WatchRuleRepository` | `WatchRule` | findById / save / findActive / updateLastTriggered |
| `ListingAnalysisRepository` | `ListingAnalysis` | findByListingId / save / findByDealScoreAbove |

```typescript
interface ListingRepository {
  findById(id: string): Promise<Listing | null>
  save(listing: Listing): Promise<void>
  // 去重用：以平台 + 平台 ID 查詢既有 Listing（BR-MKT-04）
  findByPlatformId(platform: string, platformListingId: string): Promise<Listing | null>
  // 狀態檢查用：找出 active 且 last_seen_at 早於指定時間的 Listing
  findActiveOlderThan(isoTime: string): Promise<Listing[]>
  // Analyzer 參考用：同類商品最近 N 筆
  findSimilar(category: string, limit: number): Promise<Listing[]>
  updateStatus(id: string, status: Listing['status']): Promise<void>
}

interface WatchRuleRepository {
  findById(id: string): Promise<WatchRule | null>
  save(rule: WatchRule): Promise<void>
  findActive(): Promise<WatchRule[]>          // is_active = true
  updateLastTriggered(id: string, isoTime: string): Promise<void>
}

interface ListingAnalysisRepository {
  findByListingId(listingId: string): Promise<ListingAnalysis | null>
  save(analysis: ListingAnalysis): Promise<void>
  findByDealScoreAbove(threshold: number): Promise<ListingAnalysis[]>
}
```

> 切換後端（SQLite → PostgreSQL）只需替換實作，介面與業務邏輯不變。

---

## 8. Entity Status Lifecycle（實體狀態生命週期）

### Listing 狀態機

```
        ┌──────────────────────────────┐
        │                              ▼
  active ──(狀態檢查發現「已售出」)──▶ sold（終態）
  active ──(HTTP 404 / 403)──────────▶ removed（終態）
  active ──(90 天未更新, BR-MKT-22)───▶ unknown
  unknown ──(再次掃描到仍在架上)──────▶ active
```

| 從 | 到 | 觸發條件 | 發出的 Event |
|---|---|---|---|
| （新解析）| active | Parser 產出新 Listing | `marketplace.listing_matched`（若符合 WatchRule）|
| active | sold | listing-status-check 發現商品頁顯示「已售出」| `marketplace.listing_status_changed` |
| active | removed | listing-status-check 收到 HTTP 404/403 | `marketplace.listing_status_changed` |
| active | unknown | last_seen_at 超過 90 天（BR-MKT-22）| `marketplace.listing_status_changed` |
| unknown | active | 後續掃描再次確認商品在架上 | `marketplace.listing_status_changed` |

> **規則**：`sold` 與 `removed` 是終態，不可再轉回。所有狀態變更必須寫入 Audit Log（Section 14，類型 `status_change`）。  
> WatchRule 僅有 `is_active` 布林狀態（啟用/停用），無複雜狀態機。

---

## 9. Collectors（資料收集器）

| Collector 名稱 | 對應資料來源 | 觸發方式 | 輸出格式 | 逾時設定 | 重試次數 |
|---|---|---|---|---|---|
| `ShopeeSearchCollector` | Shopee Taiwan | Scheduled（每 30 分鐘）| Raw JSON | 30s | 2 |
| `YahooAuctionCollector` | Yahoo 奇摩拍賣 | Scheduled（每 30 分鐘）| RSS XML + HTML | 20s | 2 |
| `RutenCollector` | 露天拍賣 | Scheduled（每 30 分鐘）| RSS XML | 20s | 2 |

### `ShopeeSearchCollector` 詳細規格

**目的**：對每個 active WatchRule 的關鍵字集合，在 Shopee 搜尋並取得最新商品列表。  
**輸入**：
```typescript
interface ShopeeSearchInput {
  keywords: string[]    // 每個 WatchRule 的 keywords
  category_id?: string  // Shopee 的分類 ID（可選）
  max_price?: number
  limit: number         // 最多 100 筆
}
```
**輸出**：
```typescript
interface CollectorOutput {
  raw: string           // Shopee API 或 HTML 回應的原始內容
  source: 'shopee'
  query: string         // 實際送出的搜尋關鍵字
  fetched_at: string
  metadata: {
    result_count: number
    page: number
  }
}
```
**快取**：原始資料存入 SQLite `external_cache`，TTL 2 小時（避免重複分析相同商品）  
**錯誤處理**：
- HTTP 429 → 停止當次掃描，在 Event 中標記 `rate_limited: true`，下次間隔加倍（最多 2 小時）
- HTTP 5xx → 標記 Task 為 `failed`，不重試此次掃描
- 逾時 30 秒 → 標記 `failed`，記錄到 Audit Log
- 連續 3 次 failed → P3 通知使用者「Shopee 掃描暫時中斷」

> 每次外部請求均寫入 Audit Log（Section 14，類型 `external_call`）。

---

## 10. Parsers（資料解析器）

> Parser 不使用 AI，只做確定性格式轉換。狀況/分類等標準化映射一律從 Section 11 Normalization Rules 載入，**不在 Parser 中硬編碼**。

| Parser 名稱 | 輸入來源 | 輸出 Entity | 關鍵邏輯 |
|---|---|---|---|
| `ShopeeListingParser` | `ShopeeSearchCollector` | `Listing[]` | 解析 API JSON，套用 ConditionNorm，price ÷ 100 |
| `YahooAuctionParser` | `YahooAuctionCollector` | `Listing[]` | 解析 RSS + HTML，計算 total_price（含拍賣運費）|
| `RutenListingParser` | `RutenCollector` | `Listing[]` | 解析 RSS XML |

### `ShopeeListingParser` 詳細規格

**輸入**：`ShopeeSearchCollector` 的 `CollectorOutput`  
**輸出**：`Listing[]`  
**標準化依賴**：ConditionNorm、CategoryNorm（從 Knowledge 載入，見 Section 11）  
**平台特定處理（Parser 內建，因屬穩定平台格式）**：Shopee 原始 price 為「台幣 × 100」（89000 = NT$890），Parser 固定 ÷100。  
**無效資料處理**：
- title 為空 → 丟棄整筆（BR-MKT-03）
- price < 0 → 丟棄整筆（BR-MKT-02）
- url 無法解析 → 丟棄整筆

### `YahooAuctionParser` / `RutenListingParser` 詳細規格

**輸入**：對應 Collector 的 RSS/HTML 輸出  
**輸出**：`Listing[]`  
**標準化依賴**：ConditionNorm、CategoryNorm（從 Knowledge 載入）  
**平台特定處理**：
- Yahoo 拍賣：condition 文字格式如「全新品」「二手良品」，total_price 須加計拍賣運費表
- 露天：RSS 不含 condition 細節，condition 多為 `unknown`，由後續分析補強

---

## 11. Normalization Rules（標準化規則）

> 解決 REV-MKT-001 EXT-02（ConditionNorm 雙重定義）：以下映射的**唯一權威位置為 Knowledge 層**，Parser 從 Knowledge Service 載入，不硬編碼。當平台改變描述格式時，使用者可直接更新 Knowledge，無需改程式。

| 映射規則 | 來源值範例 | 標準值 | 儲存位置 | 更新方式 |
|---|---|---|---|---|
| **ConditionNorm** | 「八成新」「9 成新」「二手良品」| Condition 五級 | Knowledge `marketplace/norm/condition` | 使用者指令 / 版本更新 |
| **CategoryNorm** | 關鍵字「樂高」「鏡頭」| Category 列舉 | Knowledge `marketplace/norm/category` | 使用者指令 / 版本更新 |

### ConditionNorm 映射內容（初始值，BR-MKT-05 的實作）

```
全新 / New                      → new
二手 9 成新 / 近全新 / 八成新     → like_new
二手 7 成新 / 七成新             → good
二手 6 成新以下                  → fair
零件機 / 瑕疵品 / 損壞           → poor
其他 / 未標示                    → unknown
```

### CategoryNorm 映射內容（初始值）

```
LEGO、樂高                              → lego
相機、鏡頭、Canon、Nikon、Sony Alpha    → cameras
iPhone、Android、手機、平板、筆電        → electronics
書、小說、漫畫、教科書                   → books
家具、桌、椅、床                         → furniture
其他                                    → other
```

> **平台價格換算（不在此 Section）**：Shopee 的 price ×100 換算屬於「永久穩定的平台格式」，內建於 Parser（Section 10），不放 Knowledge。

---

## 12. Analyzers（AI 分析器）

> ⚠️ **架構約束（P-07）**：以下 Analyzer 的所有 AI 呼叫必須透過 `AIProvider` 介面，**不得直接 import Anthropic / OpenAI SDK**。

| Analyzer 名稱 | 輸入 | 輸出 | AI 模型偏好 | Prompt 策略 |
|---|---|---|---|---|
| `MarketplaceValueAnalyzer` | `Listing` + MarketPrice Knowledge | `ListingAnalysis` | claude-haiku-4-5（速度優先）| Structured output + few-shot |
| `MarketplaceRiskAnalyzer` | `Listing` | Risk flags | claude-haiku-4-5 | Rule-based + AI 輔助 |

> **命名說明（REV-MKT-001 SI-02）**：採用 `Marketplace{Function}Analyzer` 形式（Domain 前綴），與 GOVR-006 一致；取代舊版 `ListingValueAnalyzer` / `ListingRiskAnalyzer`。

### `MarketplaceValueAnalyzer` 詳細規格

**目的**：判斷一個 Listing 相對於市場行情是否值得購買，輸出 DealScore。  
**輸入**：
```typescript
interface MarketplaceValueInput {
  listing: Listing
  market_price: number | null       // 從 Knowledge 查詢，可能為 null
  category_thresholds: {            // 從 Knowledge 查詢
    great_deal_ratio: number        // e.g., 0.6（低於市場價 40%）
    good_deal_ratio: number         // e.g., 0.75
    fair_price_ratio: number        // e.g., 0.9
  }
  similar_listings: Listing[]       // 同類商品最近 20 筆（來自 ListingRepository.findSimilar）
}
```
**輸出 Schema**（`ListingAnalysis` 欄位的子集）：
```typescript
interface ValueAnalysisOutput {
  deal_score: number              // 0.0–1.0
  value_verdict: 'great_deal' | 'good_deal' | 'fair_price' | 'overpriced' | 'suspicious'
  condition_assessment: string    // AI 解讀商品狀況描述
  reason: string                  // 給使用者看的說明（繁體中文）
  confidence: number
  price_ratio: number | null
}
```
**Prompt 策略**：Few-shot with structured output。提供 3 個範例（good_deal、overpriced、suspicious），要求 JSON 輸出。  
**Knowledge 依賴**：
- `marketplace/{category}/market_price` — 特定商品型號的市場行情
- `marketplace/{category}/thresholds` — 各類別的好物門檻設定

**最低 Confidence 門檻**：0.65（低於此值 → L2 驗證：用不同 Prompt 再跑一次）

### `MarketplaceRiskAnalyzer` 詳細規格

**目的**：偵測詐騙與風險，輸出 `RiskFlag[]`。  
**輸入**：`Listing`（含 price、market_price 參考、seller_rating、images、description）  
**輸出**：`RiskFlag[]` + 每個 flag 的 confidence  
**規則 + AI 混合**：明確規則（price < market×0.35 → `price_suspiciously_low`；image_count = 0 → `no_images`；seller 評價 < 10 → `new_seller`）先行，AI 補強模糊判斷（`vague_description`、`condition_mismatch`、`possible_replica`）。  
**`possible_replica` 門檻**：AI confidence ≥ 0.7 才標記（避免偽陽性，REV-MKT-001 R-07）。

---

## 13. Validators（驗證器）

### L1 自動驗證

| 驗證項目 | 規則 | 失敗處理 |
|---|---|---|
| Schema 完整性 | title、price、url、platform 必填 | 丟棄 Listing |
| 價格合法性 | price ≥ 0，shipping_cost ≥ 0 | 丟棄 Listing |
| URL 合法性 | 必須為可解析的 HTTP URL | 丟棄 Listing |
| 疑似詐騙價格 | total_price < MarketPrice × 0.35 | 標記 `price_suspiciously_low`，仍保留 |
| Confidence 篩選 | Analyzer confidence < 0.65 | 升級至 L2 |
| AI 輸出 Schema | deal_score / value_verdict / confidence 欄位齊全且型別正確 | 缺欄位 → 視為分析失敗，不發通知，等下次重試 |

### L2 交叉驗證

| 驗證項目 | 方法 | 觸發條件 |
|---|---|---|
| 低 Confidence 結果 | 用不同 System Prompt 再分析一次，取兩次平均 | L1 confidence < 0.65 |
| 高風險商品（有 risk_flags）| 額外一次 Risk 專用 Prompt 確認 | risk_flags 不為空 |

### L3 人工確認

| 驗證項目 | 通知內容 | 使用者操作 |
|---|---|---|
| DealScore > 0.9 的商品（高分要確認一下）| P1 通知：「發現高分商品，DealScore {score}，請確認是否真的有興趣」| 確認（加入 Watch List）/ 略過 |
| 有 `possible_replica` flag | 「此商品可能為仿製品，請自行判斷」| 確認仍要追蹤 / 略過 |

---

## 14. Auditable Operations（可審計操作）

> 對應 P-09 與 ADR-0009。Audit Log 的記錄格式、儲存、append-only 保證由 **Core 統一提供**；本 Domain 只宣告以下操作必須寫入 Audit Log，並提供 metadata 欄位。

| 操作 | 類型 | 必須審計？ | metadata 關鍵欄位 |
|---|---|---|---|
| 各平台搜尋/狀態 HTTP 請求 | `external_call` | ✅ | platform, endpoint, status_code, rate_limited |
| P1 / P2 通知發送 | `notification` | ✅ | rule_id, listing_id, priority, channel |
| MarketPrice / CategoryThresholds 寫入 | `knowledge_write` | ✅ | knowledge_key, old_value→new_value, approved_by |
| ConditionNorm / CategoryNorm 更新 | `knowledge_write` | ✅ | knowledge_key, old_value→new_value, approved_by |
| Listing 狀態變更（active→sold/removed/unknown）| `status_change` | ✅ | entity_id, from, to, trigger |

> Core 自動填入的共用欄位：`operation_type, domain('marketplace'), entity_id, action, actor, timestamp, result, metadata`。  
> **絕對禁止（P-09）**：不自動購買、不自動出價、不代發訊息給賣家。

---

## 15. Notification Rules（通知規則）

| 規則 ID | 觸發條件 | 優先級 | 管道 | Cooldown | 格式 |
|---|---|---|---|---|---|
| NR-MKT-01 | Listing 符合 WatchRule AND deal_score ≥ 0.8 | P1 | Telegram | 24 小時（同一 Listing）| 即時告知格式 |
| NR-MKT-02 | Listing 符合 WatchRule AND deal_score 0.5–0.8 | P2 | Telegram | 批次（每日 09:00）| 每日摘要格式 |
| NR-MKT-03 | 每日 09:00 批次摘要 | P2 | Telegram | — | 摘要格式 |
| NR-MKT-04 | Listing 已售出，使用者曾查看過 | P3 | Dashboard | 不限 | 文字記錄 |
| NR-MKT-05 | WatchRule 7 天無符合 | P3 | Dashboard | 7 天 | 建議調整規則 |
| NR-MKT-06 | 平台掃描連續 3 次失敗 | P2 | Telegram | 6 小時 | 系統狀態告知 |

### 通知訊息格式

**P1 立即通知（NR-MKT-01）**：
```
🎯 好物發現：{WatchRule.name}

📦 {listing.title}
💰 NT${listing.total_price}（含運）
✨ 狀況：{condition 中文}｜DealScore：{score}/10
📍 {platform 中文名稱}

💬 {analysis.reason}

👉 {listing.url}
```

**P2 每日摘要（NR-MKT-03）**：
```
📊 今日市場摘要（{日期}）

📌 {WatchRule.name}（{N} 筆新符合）
  • {listing.title} — NT${price}（{deal_score}/10）
  • {listing.title} — NT${price}（{deal_score}/10）

📌 {另一個 WatchRule.name}（{N} 筆）
  ...

共 {total} 筆，詳見 Dashboard
```

---

## 16. Event Catalogue（事件目錄）

> 對應 COMPAT-01 與命名規範 SYS-002（`{namespace}.{subject}_{past_verb}`）。所有 Event 名稱定義於 `packages/core/events.ts`。

| Event 名稱 | 觸發時機 | Payload 關鍵欄位 | 訂閱者 |
|---|---|---|---|
| `marketplace.listing_matched` | WatchRuleMatcher 確認 Listing 符合至少一個 WatchRule | listing_id, watch_rule_ids[] | Analyzer 排程 |
| `marketplace.listing_analyzed` | Analyzer 完成 ListingAnalysis | listing_id, deal_score, value_verdict | Validator、Notification Dispatcher |
| `marketplace.listing_status_changed` | listing-status-check 偵測狀態轉換 | listing_id, from_status, to_status | Notification Dispatcher（P3）|
| `marketplace.notification_sent` | Notification Dispatcher 完成發送 | rule_id, listing_id, priority | Audit、Dashboard |
| `marketplace.scan_completed` | marketplace-scan Workflow 結束 | scanned_count, matched_count, analyzed_count, ai_calls | Dashboard、月度統計 |

---

## 17. Workflows（工作流程）

| Workflow 名稱 | 觸發方式 | 排程 | 預估執行時間 |
|---|---|---|---|
| `marketplace-scan` | Scheduled | 每 30 分鐘 `*/30 * * * *` | 3–10 分鐘 |
| `listing-status-check` | Scheduled | 每天 08:00 `0 8 * * *` | 5–15 分鐘 |
| `marketplace-daily-digest` | Scheduled | 每天 09:00 `0 9 * * *` | < 1 分鐘 |

### Workflow：`marketplace-scan`

**觸發**：Scheduler 發出 `workflow.triggered` Event，payload 包含 `workflow_id: 'marketplace-scan'`（ADR-0014）  
**目的**：對所有 active WatchRule 掃描各平台新商品，分析後觸發通知

```
Step 1: WatchRuleLoader            [Repository Query — WatchRuleRepository.findActive()]
  → 輸出：WatchRule[]
  → 失敗行為：查詢失敗 → abort workflow（無規則可掃描）

Step 2: ShopeeSearchCollector      [Collector Worker]  ─┐
        YahooAuctionCollector      [Collector Worker]   ├─ 並行執行
        RutenCollector             [Collector Worker]  ─┘
  → 輸入：各 WatchRule 的關鍵字集合
  → 輸出：CollectorOutput[]
  → 失敗行為：任一 Collector 失敗 → 記錄錯誤（Audit external_call），skip 該平台，繼續其他平台

Step 3: ShopeeListingParser        [Parser Worker]  ─┐
        YahooAuctionParser         [Parser Worker]   ├─ 並行執行
        RutenListingParser         [Parser Worker]  ─┘
  → 輸入：各 Collector 的 CollectorOutput
  → 輸出：Listing[]（已解析）
  → 去重：ListingRepository.findByPlatformId 已存在 → 更新 last_seen_at，跳過分析
  → 失敗行為：單筆解析失敗 → skip 該筆，不中斷；整個 Parser 失敗 → skip 該平台

Step 4: WatchRuleMatcher           [Core Logic]
  → 輸入：新 Listing[]、WatchRule[]
  → 輸出：{ listing, watch_rules: WatchRule[] }[]
  → 發出 marketplace.listing_matched
  → 失敗行為：單筆比對異常 → 記錄 failed，skip 該筆，繼續下一筆

Step 5: MarketplaceValueAnalyzer   [Analyzer Worker]  ← 並行，每 Listing 一個
        MarketplaceRiskAnalyzer    [Analyzer Worker]  ← 與 ValueAnalyzer 並行
  → 輸入：Listing + 相關 Knowledge（MarketPrice、Thresholds）
  → 輸出：ListingAnalysis；發出 marketplace.listing_analyzed
  → 成本上限：本 Workflow AI 呼叫總數 ≤ 500（BR-MKT-23），達上限則停止分析剩餘 Listing 並記錄
  → 失敗行為：單筆分析失敗（含 AI 超時）→ 標記 failed，該 Listing 不發通知，等下次掃描重試

Step 6: L1 Validator               [Validator]
  → 過濾低品質分析結果；confidence < 0.65 → 觸發 L2
  → 失敗行為：AI 輸出 schema 不符 → 視為分析失敗，skip 該筆

Step 7: Notification Dispatcher    [Core]
  → 依 BR-MKT-10 / BR-MKT-11 決定 P1 立即通知 或加入 P2 批次佇列
  → 套用 Cooldown 規則（BR-MKT-13/14）；發出 marketplace.notification_sent（Audit notification）
  → 失敗行為：發送失敗 → 重試 1 次，仍失敗則記錄 failed，不阻斷其他通知

最後：發出 marketplace.scan_completed
```

### Workflow：`listing-status-check`

**觸發**：Scheduler 每天 08:00  
**目的**：確認追蹤中的 Listing 是否已售出或下架

```
Step 1: ListingRepository.findActiveOlderThan(now - 24h)
  → 失敗行為：查詢失敗 → abort workflow
Step 2: 對各 Listing 發出 HEAD 請求確認 URL 存活（Audit external_call）
  → 失敗行為：單筆請求失敗 → skip 該筆，繼續其他
Step 3: 404 / 403 → status = 'removed'；商品頁顯示「已售出」→ status = 'sold'
Step 4: 若 status 有變更 → ListingRepository.updateStatus + Audit status_change
        + 發出 marketplace.listing_status_changed
```

---

## 18. Knowledge（知識庫）

### 知識項目清單

| 知識項目 | 類型 | 初始來源 | 更新方式 | 審核要求 |
|---|---|---|---|---|
| 各類別市場行情價 | Reference | 使用者手動輸入 | 使用者指令 / AI 建議 | L3 人工確認（AI 建議）|
| 各類別好物門檻（PriceRatio）| Rule | 系統預設 | 使用者調整 | L1 自動 |
| 條件轉換規則（ConditionNorm）| Rule | 系統內建 | 使用者指令 / 版本更新 | L3 人工確認（使用者更新）|
| 分類辨識規則（CategoryNorm）| Rule | 系統內建 | 使用者指令 / AI 建議 | L3 人工確認 |
| 各平台已知詐騙模式 | Fact | 使用者回報 / AI 建議 | 使用者確認 | L3 人工確認 |

> ConditionNorm / CategoryNorm 為 Section 11 Normalization Rules 的權威儲存位置；Parser 從此載入。

### 知識 Schema

```typescript
// 市場行情價（MarketPriceKnowledge）
interface MarketPriceKnowledge {
  domain: 'marketplace'
  topic: 'market_price'
  content: {
    item_name: string           // 商品名稱（「Canon EF 50mm f/1.8」）
    category: string
    price_new: number           // 全新品市場價（TWD）
    price_like_new: number      // 九成新市場價
    price_good: number          // 八成新市場價
    source: string              // 「使用者判斷」「蝦皮均價」「Yahoo 均價」
    last_verified: string       // ISO 8601
  }
  confidence: number
  requires_approval: boolean    // AI 建議的價格 = true
}

// 類別門檻設定（CategoryThresholds）
interface CategoryThresholds {
  domain: 'marketplace'
  topic: 'category_thresholds'
  content: {
    category: string
    great_deal_ratio: number    // total_price / price_good 低於此 = great_deal（預設 0.6）
    good_deal_ratio: number     // 低於此 = good_deal（預設 0.75）
    suspicious_ratio: number    // 低於此 = 疑似詐騙（預設 0.35）
  }
}

// 標準化映射（NormalizationKnowledge）— ConditionNorm / CategoryNorm
interface NormalizationKnowledge {
  domain: 'marketplace'
  topic: 'norm'
  content: {
    norm_type: 'condition' | 'category'
    mappings: { from: string; to: string }[]
  }
  confidence: number
  requires_approval: boolean
}
```

### 預設知識初始值

```json
{
  "category_thresholds": {
    "books":       { "great_deal_ratio": 0.50, "good_deal_ratio": 0.70, "suspicious_ratio": 0.20 },
    "lego":        { "great_deal_ratio": 0.60, "good_deal_ratio": 0.75, "suspicious_ratio": 0.35 },
    "electronics": { "great_deal_ratio": 0.65, "good_deal_ratio": 0.80, "suspicious_ratio": 0.40 },
    "cameras":     { "great_deal_ratio": 0.60, "good_deal_ratio": 0.78, "suspicious_ratio": 0.35 },
    "furniture":   { "great_deal_ratio": 0.55, "good_deal_ratio": 0.72, "suspicious_ratio": 0.30 }
  }
}
```

---

## 19. Test Cases（測試案例）

> 依 Template v1.1：每個 Parser 套用 Parser Test Template（正常解析 / 必填缺失丟棄 / Normalization 對應 / 格式邊界），每個 Analyzer 套用 Analyzer Test Template（分數範圍 / verdict 合法性 / confidence 門檻 / Golden Sample Replay）。

### Unit Test Cases — Parsers

| 測試案例 | 測試對象 | 測試類型 | 輸入 | 預期輸出 | 覆蓋規則 |
|---|---|---|---|---|---|
| `TC-MKT-U01` | `ShopeeListingParser` | 正常解析 | 正常 Shopee 商品 JSON | 完整 `Listing`，price ÷100 正確 | BR-MKT-01 |
| `TC-MKT-U02` | `ShopeeListingParser` | 必填缺失丟棄 | 缺少 title 的資料 | 丟棄（空陣列）| BR-MKT-03 |
| `TC-MKT-U03` | `ShopeeListingParser` | Normalization 對應 | `condition_raw = "八成新"` | `condition = 'like_new'` | BR-MKT-05 |
| `TC-MKT-U04` | `ShopeeListingParser` | 格式邊界 | price 欄位為 `89000`（×100 格式）| `price = 890` | BR-MKT-02 |
| `TC-MKT-U09` | `YahooAuctionParser` | 正常解析 | 正常 Yahoo 拍賣 RSS + HTML | 完整 `Listing`，total_price 含拍賣運費 | BR-MKT-01 |
| `TC-MKT-U10` | `YahooAuctionParser` | 必填缺失丟棄 | RSS item 缺少標題 | 丟棄該筆 | BR-MKT-03 |
| `TC-MKT-U11` | `YahooAuctionParser` | Normalization 對應 | `condition_raw = "二手良品"` | `condition = 'good'`（依 ConditionNorm）| BR-MKT-05 |
| `TC-MKT-U12` | `RutenListingParser` | 正常解析 | 正常露天 RSS XML | 完整 `Listing` | BR-MKT-01 |
| `TC-MKT-U13` | `RutenListingParser` | 必填缺失丟棄 | RSS 缺少價格欄位 | 丟棄該筆 | BR-MKT-02 |
| `TC-MKT-U14` | `RutenListingParser` | 格式邊界 | RSS 無 condition 資訊 | `condition = 'unknown'`（不丟棄）| BR-MKT-05 |

### Unit Test Cases — Matcher / Validator

| 測試案例 | 測試對象 | 輸入 | 預期輸出 | 覆蓋規則 |
|---|---|---|---|---|
| `TC-MKT-U05` | `WatchRuleMatcher` | Listing（LEGO City，NT$300）+ Rule（LEGO，max NT$400）| Match | BR-MKT-10 |
| `TC-MKT-U06` | `WatchRuleMatcher` | Listing（LEGO City，NT$500）+ Rule（LEGO，max NT$400）| No match | BR-MKT-10 |
| `TC-MKT-U07` | `WatchRuleMatcher` | Listing（含排除關鍵字「零件」）| No match（exclude_keywords）| — |
| `TC-MKT-U08` | `L1 Validator` | total_price = 50，market_price = 1000 | 標記 `price_suspiciously_low` | BR-MKT-12 |
| `TC-MKT-U15` | `L1 Validator` | Analyzer 回傳 confidence = 0.5 | 升級至 L2 | — |
| `TC-MKT-U16` | `L1 Validator` | AI 輸出缺少 `deal_score` 欄位 | 視為分析失敗，不發通知 | — |

### Unit Test Cases — Analyzers

| 測試案例 | 測試對象 | 測試類型 | 輸入 | 預期輸出 |
|---|---|---|---|---|
| `TC-MKT-U17` | `MarketplaceValueAnalyzer` | 分數範圍 | 任意 Listing + market_price | `0.0 ≤ deal_score ≤ 1.0`，`0.0 ≤ confidence ≤ 1.0` |
| `TC-MKT-U18` | `MarketplaceValueAnalyzer` | verdict 合法性 | 任意 Listing | `value_verdict` ∈ 五個合法列舉值 |
| `TC-MKT-U19` | `MarketplaceValueAnalyzer` | Golden Sample Replay | Golden Sample stage_2 輸入 | DealScore 與人工標注的 Spearman 相關 ≥ 0.6 |
| `TC-MKT-U20` | `MarketplaceRiskAnalyzer` | 規則命中 | image_count = 0 的 Listing | risk_flags 含 `no_images` |
| `TC-MKT-U21` | `MarketplaceRiskAnalyzer` | 規則命中 | total_price < market×0.35 | risk_flags 含 `price_suspiciously_low` |
| `TC-MKT-U22` | `MarketplaceRiskAnalyzer` | 偽陽性門檻 | 正常商品，AI replica confidence = 0.5 | 不標記 `possible_replica`（門檻 0.7）|

### Integration Test Cases

| 測試案例 | 測試流程 | 前置條件 | 驗證點 |
|---|---|---|---|
| `TC-MKT-I01` | `marketplace-scan` 完整執行 | Mock Shopee 回傳 10 筆，其中 3 筆符合 WatchRule | 3 筆 Listing 進入 DB，Analyzer 被呼叫 3 次 |
| `TC-MKT-I02` | 重複 Listing 去重 | 同一 platform_listing_id 在兩次掃描中出現 | 第二次只更新 last_seen_at，不重複分析 |
| `TC-MKT-I03` | P1 通知觸發 | DealScore = 0.85，符合 WatchRule | Notification Dispatcher 發出 P1 通知 |
| `TC-MKT-I04` | Cooldown 防止重複通知 | 同一 Listing 在 24 小時內再次被掃描到 | 不重複發送通知 |
| `TC-MKT-I05` | Collector 失敗不中斷流程 | Shopee Collector 回傳 HTTP 500 | Yahoo/Ruten 繼續執行，只記錄 Shopee 失敗 |
| `TC-MKT-I06` | AI 成本上限 | 單次掃描可分析 600 筆 | 達 500 筆後停止，記錄並發出 scan_completed |

### Edge Cases

| 情況描述 | 預期行為 |
|---|---|
| 所有平台同時不可用 | 標記所有 Collector Task 為 failed；P2 通知「掃描暫時中斷」|
| AI API 超時 | Analyzer Task 標記 failed；此 Listing 不發通知，等下次掃描重試 |
| WatchRule 的關鍵字包含特殊字元 | Parser 做 HTML entity decode 後再比對 |
| 商品價格為 0（免費送）| 合法情況，不觸發 suspicious_ratio 規則（0 < threshold × market_price 永遠為 false）|
| Listing 在 24 小時內價格變動 | 偵測到 raw_hash 改變 → 觸發重新分析 |

---

## 20. Golden Sample（黃金樣本）

> 依 Template v1.1：保存資料流經每一層的完整快照，使 Replay（GOVR-007）可直接重跑，並作為 Golden Dataset（GOVR-006）種子。

### GS-001：正常情境（LEGO 好物，Shopee）

```json
{
  "sample_id": "marketplace-gs-001",
  "stage_0_raw": {
    "source": "shopee",
    "raw": "{\"items\":[{\"item_id\":123456789,\"name\":\"LEGO 60197 城市系列 客運火車 二手 九成新\",\"price\":89000,\"shop_rating\":4.8,\"shop_location\":\"台北市\",\"image\":\"xxxxxx.jpg\",\"cmt_count\":0}]}",
    "fetched_at": "2026-06-29T10:00:00Z"
  },
  "stage_1_preprocessed": { "note": "Shopee 為結構化 JSON，無需 OCR", "content": null },
  "stage_2_parsed": {
    "platform": "shopee",
    "platform_listing_id": "123456789",
    "title": "LEGO 60197 城市系列 客運火車 二手 九成新",
    "condition": "like_new",
    "condition_raw": "九成新",
    "category": "lego",
    "price": 890,
    "shipping_cost": 0,
    "total_price": 890,
    "seller_rating": 4.8,
    "location": "台北市",
    "status": "active"
  },
  "stage_3_analyzed": {
    "deal_score": 0.82,
    "value_verdict": "good_deal",
    "condition_assessment": "賣家標示九成新，對 LEGO 通常表示積木完整、無缺件，但未提及說明書。",
    "risk_flags": [],
    "reason": "LEGO 60197 全新市場價約 NT$1,499，此件 NT$890（約 59% 市場價），狀況良好，賣家評分 4.8，值得考慮。建議詢問說明書是否完整。",
    "confidence": 0.88,
    "market_price_reference": 1499,
    "price_ratio": 0.59,
    "model_used": "claude-haiku-4-5-20251001"
  },
  "stage_4_notification": {
    "priority": "P1",
    "rendered_message": "🎯 好物發現：找 LEGO 城市系列\n\n📦 LEGO 60197 城市系列 客運火車 二手 九成新\n💰 NT$890（含運）\n✨ 狀況：九成新｜DealScore：8.2/10\n📍 蝦皮\n\n💬 全新市場價約 NT$1,499，此件約 59% 市場價，狀況良好，賣家評分 4.8。\n\n👉 https://shopee.tw/product/98765432/123456789"
  }
}
```

### GS-002：異常情境（疑似詐騙，異常低價無照片）

```json
{
  "sample_id": "marketplace-gs-002",
  "stage_0_raw": {
    "source": "ruten",
    "raw": "<item><title>Canon EF 50mm f/1.8 鏡頭 便宜出清</title><price>450</price><desc>限量 快搶</desc></item>",
    "fetched_at": "2026-06-29T10:05:00Z"
  },
  "stage_1_preprocessed": { "note": "RSS 純文字，無需 OCR", "content": null },
  "stage_2_parsed": {
    "platform": "ruten",
    "platform_listing_id": "R-998877",
    "title": "Canon EF 50mm f/1.8 鏡頭 便宜出清",
    "condition": "unknown",
    "condition_raw": null,
    "category": "cameras",
    "price": 450,
    "shipping_cost": 0,
    "total_price": 450,
    "seller_rating": null,
    "status": "active"
  },
  "stage_3_analyzed": {
    "deal_score": 0.15,
    "value_verdict": "suspicious",
    "condition_assessment": "無狀況描述、無照片、賣家無評分，價格遠低於市場。",
    "risk_flags": ["price_suspiciously_low", "no_images", "new_seller", "vague_description"],
    "reason": "Canon EF 50mm f/1.8 市場行情約 NT$3,000，此件僅 NT$450（15% 市場價），無照片、描述模糊、賣家無評分，高度疑似詐騙，不建議交易。",
    "confidence": 0.91,
    "market_price_reference": 3000,
    "price_ratio": 0.15,
    "model_used": "claude-haiku-4-5-20251001"
  },
  "stage_4_notification": {
    "priority": "P3",
    "rendered_message": "⚠️ 此商品疑似詐騙，已自動標記，未推送 P1。詳見 Dashboard。"
  }
}
```

### WatchRule 範例（驅動上述掃描的輸入）

```json
{
  "id": "wr-001",
  "name": "找 LEGO 城市系列",
  "category": "lego",
  "keywords": ["LEGO", "樂高", "城市系列", "60197"],
  "exclude_keywords": ["零件", "缺件", "說明書", "貼紙"],
  "max_total_price": 1200,
  "min_condition": "good",
  "platforms": ["shopee", "yahoo_auction", "ruten"],
  "min_deal_score": 0.6,
  "notification_priority": "P1",
  "is_active": true,
  "last_triggered_at": null,
  "created_at": "2026-06-29T09:00:00Z",
  "updated_at": "2026-06-29T09:00:00Z"
}
```

> `min_deal_score` 預設 0.6 的理由：低於 0.6 多為「公平價格」或「偏貴」，對「主動找好物」的使用者價值低；0.6 在 Manual Baseline 測試中平衡了通知量與品質（見 GOVR-005）。

---

## 21. Future Extensions（未來擴充）

### V2 計劃

- **Facebook Marketplace Collector**：需要維護一個已登入的 session，計劃在 V2 實作，屆時需要解決 auth token 的安全儲存問題（使用 Keychain / 加密 SQLite 欄位）
- **價格走勢分析**（`MarketplacePriceTrendAnalyzer`）：追蹤特定商品類別的價格趨勢，在「LEGO 城市系列近期價格偏高，建議等待」時通知
- **賣家信譽追蹤**：跨時間記錄同一賣家的評分變化和成交率

### V3 考慮

- **跨平台同款商品比較**：偵測同一商品在不同平台的 Listing，彙整最低價
- **自動建立議價訊息草稿**：AI 根據市場行情生成議價建議，使用者一鍵發送（需要 P-E 授權）

### 已知限制

| 限制 | 原因 | 可能的解決方案 |
|---|---|---|
| 無法取得商品的詳細描述頁 | V1 只掃描列表頁，不點進詳細頁（節省頻寬、避免封鎖）| V2 選擇性地對高分 Listing 爬詳細頁 |
| Shopee 格式可能隨更新改變 | 蝦皮平台更新 UI 或 API | 加入格式版本偵測；建立快速修復機制 |
| 無法得知商品的 "真實" 狀況 | 只能依賴賣家描述 + AI 推理 | 這是根本性限制，L3 驗證讓使用者自行判斷 |
| DealScore 精準度依賴 MarketPrice 知識 | 若 Knowledge 中無市場行情 → score 只能估算 | 鼓勵使用者維護常追蹤商品的行情知識 |

### 不在計劃中

- **自動出價或購買**：任何與外部平台的寫入互動永遠不做（安全原則 P-09）
- **評論 / 私信賣家**：不做任何代使用者發送訊息的功能（安全原則 P-09）
- **比較全新品電商（蝦皮官方店、momo）的售價**：這是 Price Comparison Domain 的範疇，不屬於 Marketplace

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，完整定義 Marketplace Domain 的 16 個 Section |
| 1.1 | 2026-06-29 | 對齊 Template v1.1（21 區塊）。新增 §7 Repository Interfaces、§8 Entity Status Lifecycle、§11 Normalization Rules、§14 Auditable Operations、§16 Event Catalogue。Must Fix：MF-01 Audit（§14）、MF-02 補 YahooAuctionParser/RutenListingParser/兩個 Analyzer 各 ≥3 測試（§19）、MF-03 WatchRule + Golden Sample（§20）。Should Improve：ConditionNorm 統一至 Knowledge（§11）、Analyzer 改名 Marketplace*（§12）、AIProvider 約束（§12）、Workflow 步驟失敗行為（§17）、新增 BR-MKT-23 AI 成本上限。晉升 Level 2（REV-MKT-001）。|
