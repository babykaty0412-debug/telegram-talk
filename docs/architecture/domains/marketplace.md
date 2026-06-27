---
doc_type: architecture
doc_id: DOMAIN-001
title: Marketplace Domain
status: accepted
version: "1.0"
date: 2026-06-27
related: [GLOSS-001, ADR-0004, ADR-0005, ADR-0007, ADR-0008, ADR-0010, ADR-0011, TMPL-001]
tags: [domain, marketplace, secondhand, ecommerce, shopee, yahoo-auctions]
---

# Marketplace Domain

## 狀態

`Accepted`（自 2026-06-27）

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
| **ConditionNorm** | 平台特定描述到標準 Condition 的轉換規則 | 「八成新」→ like_new；「七成新」→ good |

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

## 7. Collectors（資料收集器）

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

---

## 8. Parsers（資料解析器）

| Parser 名稱 | 輸入來源 | 輸出 Entity | 關鍵邏輯 |
|---|---|---|---|
| `ShopeeListingParser` | `ShopeeSearchCollector` | `Listing[]` | 解析 API JSON，映射 condition |
| `YahooAuctionParser` | `YahooAuctionCollector` | `Listing[]` | 解析 RSS + HTML，計算 total_price（含拍賣運費）|
| `RutenListingParser` | `RutenCollector` | `Listing[]` | 解析 RSS XML |

### `ShopeeListingParser` 詳細規格

**輸入**：`ShopeeSearchCollector` 的 `CollectorOutput`  
**輸出**：`Listing[]`

**Condition 映射規則**（BR-MKT-05 的實作）：

| 原始描述（Shopee 標籤）| 標準 Condition |
|---|---|
| 全新 / New | `new` |
| 二手 9 成新 / 近全新 | `like_new` |
| 二手 8 成新 / 八成新 | `like_new` |
| 二手 7 成新 / 七成新 | `good` |
| 二手 6 成新以下 | `fair` |
| 零件機 / 瑕疵品 / 損壞 | `poor` |
| 其他 / 未標示 | `unknown` |

**Category 映射規則**：

| 搜尋關鍵字中包含 | 推測 Category |
|---|---|
| LEGO、樂高 | `lego` |
| 相機、鏡頭、Canon、Nikon、Sony Alpha | `cameras` |
| iPhone、Android、手機、平板、筆電 | `electronics` |
| 書、小說、漫畫、教科書 | `books` |
| 家具、桌、椅、床 | `furniture` |
| 其他 | `other` |

**無效資料處理**：
- title 為空 → 丟棄整筆
- price < 0 → 丟棄整筆
- url 無法解析 → 丟棄整筆

---

## 9. Analyzers（AI 分析器）

| Analyzer 名稱 | 輸入 | 輸出 | AI 模型偏好 | Prompt 策略 |
|---|---|---|---|---|
| `ListingValueAnalyzer` | `Listing` + MarketPrice Knowledge | `ListingAnalysis` | claude-haiku-4-5（速度優先）| Structured output + few-shot |
| `ListingRiskAnalyzer` | `Listing` | Risk flags | claude-haiku-4-5 | Rule-based + AI 輔助 |

### `ListingValueAnalyzer` 詳細規格

**目的**：判斷一個 Listing 相對於市場行情是否值得購買，輸出 DealScore。  
**輸入**：
```typescript
interface ListingValueInput {
  listing: Listing
  market_price: number | null       // 從 Knowledge 查詢，可能為 null
  category_thresholds: {            // 從 Knowledge 查詢
    great_deal_ratio: number        // e.g., 0.6（低於市場價 40%）
    good_deal_ratio: number         // e.g., 0.75
    fair_price_ratio: number        // e.g., 0.9
  }
  similar_listings: Listing[]       // 同類商品最近 20 筆（來自 DB）
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
- `marketplace.{category}.market_price` — 特定商品型號的市場行情
- `marketplace.{category}.thresholds` — 各類別的好物門檻設定  

**最低 Confidence 門檻**：0.65（低於此值 → L2 驗證：用不同 Prompt 再跑一次）

---

## 10. Validators（驗證器）

### L1 自動驗證

| 驗證項目 | 規則 | 失敗處理 |
|---|---|---|
| Schema 完整性 | title、price、url、platform 必填 | 丟棄 Listing |
| 價格合法性 | price ≥ 0，shipping_cost ≥ 0 | 丟棄 Listing |
| URL 合法性 | 必須為可解析的 HTTP URL | 丟棄 Listing |
| 疑似詐騙價格 | total_price < MarketPrice × 0.35 | 標記 `price_suspiciously_low`，仍保留 |
| Confidence 篩選 | Analyzer confidence < 0.65 | 升級至 L2 |

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

## 11. Notification Rules（通知規則）

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

## 12. Workflows（工作流程）

| Workflow 名稱 | 觸發方式 | 排程 | 預估執行時間 |
|---|---|---|---|
| `marketplace-scan` | Scheduled | 每 30 分鐘 `*/30 * * * *` | 3–10 分鐘 |
| `listing-status-check` | Scheduled | 每天 08:00 `0 8 * * *` | 5–15 分鐘 |
| `marketplace-daily-digest` | Scheduled | 每天 09:00 `0 9 * * *` | < 1 分鐘 |

### Workflow：`marketplace-scan`

**觸發**：Scheduler 發出 `workflow.triggered` Event，payload 包含 `workflow_id: 'marketplace-scan'`  
**目的**：對所有 active WatchRule 掃描各平台新商品，分析後觸發通知

```
Step 1: WatchRuleLoader            [Repository Query]
  → 查詢所有 is_active = true 的 WatchRule
  → 輸出：WatchRule[]

Step 2: ShopeeSearchCollector      [Collector Worker]  ─┐
        YahooAuctionCollector      [Collector Worker]   ├─ 並行執行
        RutenCollector             [Collector Worker]  ─┘
  → 輸入：各 WatchRule 的關鍵字集合
  → 輸出：CollectorOutput[]（各平台原始資料）
  → 錯誤：任一 Collector 失敗 → 記錄錯誤，繼續其他平台

Step 3: ShopeeListingParser        [Parser Worker]  ─┐
        YahooAuctionParser         [Parser Worker]   ├─ 並行執行
        RutenListingParser         [Parser Worker]  ─┘
  → 輸入：各 Collector 的 CollectorOutput
  → 輸出：Listing[]（已解析）
  → 去重：platform + platform_listing_id 已存在 DB → 更新 last_seen_at，跳過分析

Step 4: WatchRuleMatcher           [Core Logic]
  → 輸入：新 Listing[]、WatchRule[]
  → 輸出：{ listing, watch_rules: WatchRule[] }[]（每個新 Listing 符合的規則）
  → 只有符合至少一個 WatchRule 的 Listing 才進入分析

Step 5: ListingValueAnalyzer       [Analyzer Worker]  ← 並行，每 Listing 一個
        ListingRiskAnalyzer        [Analyzer Worker]  ← 與 ValueAnalyzer 並行
  → 輸入：Listing + 相關 Knowledge（MarketPrice、Thresholds）
  → 輸出：ListingAnalysis

Step 6: L1 Validator               [Validator]
  → 過濾低品質分析結果
  → confidence < 0.65 → 觸發 L2（再分析一次）

Step 7: Notification Dispatcher    [Core]
  → 依 BR-MKT-10 / BR-MKT-11 決定 P1 立即通知 或加入 P2 批次佇列
  → 套用 Cooldown 規則（BR-MKT-13）
```

### Workflow：`listing-status-check`

**觸發**：Scheduler 每天 08:00  
**目的**：確認追蹤中的 Listing 是否已售出或下架

```
Step 1: 查詢 status = 'active' 且 last_seen_at < 24 小時前的 Listing
Step 2: 對各 Listing 發出 HEAD 請求確認 URL 存活
Step 3: 404 / 403 → 更新 status = 'removed'
        商品頁顯示「已售出」→ 更新 status = 'sold'
Step 4: 若 status 有變更 → Event: marketplace.listing_status_changed
```

---

## 13. Knowledge（知識庫）

### 知識項目清單

| 知識項目 | 類型 | 初始來源 | 更新方式 | 審核要求 |
|---|---|---|---|---|
| 各類別市場行情價 | Reference | 使用者手動輸入 | 使用者指令 / AI 建議 | L3 人工確認（AI 建議）|
| 各類別好物門檻（PriceRatio）| Rule | 系統預設 | 使用者調整 | L1 自動 |
| 條件轉換規則（ConditionNorm）| Rule | 系統內建 | 版本更新 | — |
| 各平台已知詐騙模式 | Fact | 使用者回報 / AI 建議 | 使用者確認 | L3 人工確認 |
| 商品類別辨識規則 | Rule | 系統內建 + AI 建議 | AI 建議 + L3 | L3 人工確認 |

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

## 14. Test Cases（測試案例）

### Unit Test Cases

| 測試案例 | 測試對象 | 輸入 | 預期輸出 | 覆蓋規則 |
|---|---|---|---|---|
| `TC-MKT-U01` | `ShopeeListingParser` | 正常的 Shopee 商品 JSON | 完整的 `Listing` 物件 | BR-MKT-01 |
| `TC-MKT-U02` | `ShopeeListingParser` | 缺少 title 的資料 | 丟棄（空陣列）| BR-MKT-03 |
| `TC-MKT-U03` | `ShopeeListingParser` | `condition_raw = "八成新"` | `condition = 'like_new'` | BR-MKT-05 |
| `TC-MKT-U04` | `ShopeeListingParser` | `condition_raw = "七成新"` | `condition = 'good'` | BR-MKT-05 |
| `TC-MKT-U05` | `WatchRuleMatcher` | Listing（LEGO City，NT$300）+ Rule（LEGO，max NT$400）| Match | BR-MKT-10 |
| `TC-MKT-U06` | `WatchRuleMatcher` | Listing（LEGO City，NT$500）+ Rule（LEGO，max NT$400）| No match | BR-MKT-10 |
| `TC-MKT-U07` | `WatchRuleMatcher` | Listing（含排除關鍵字「零件」）| No match（exclude_keywords）| — |
| `TC-MKT-U08` | `L1 Validator` | total_price = 50，market_price = 1000 | 標記 `price_suspiciously_low` | BR-MKT-12 |

### Integration Test Cases

| 測試案例 | 測試流程 | 前置條件 | 驗證點 |
|---|---|---|---|
| `TC-MKT-I01` | `marketplace-scan` 完整執行 | Mock Shopee 回傳 10 筆商品，其中 3 筆符合 WatchRule | 3 筆 Listing 進入 DB，Analyzer 被呼叫 3 次 |
| `TC-MKT-I02` | 重複 Listing 去重 | 同一 platform_listing_id 在兩次掃描中出現 | 第二次只更新 last_seen_at，不重複分析 |
| `TC-MKT-I03` | P1 通知觸發 | DealScore = 0.85，符合 WatchRule | Notification Dispatcher 發出 P1 通知 |
| `TC-MKT-I04` | Cooldown 防止重複通知 | 同一 Listing 在 24 小時內再次被掃描到 | 不重複發送通知 |
| `TC-MKT-I05` | Collector 失敗不中斷流程 | Shopee Collector 回傳 HTTP 500 | Yahoo/Ruten 繼續執行，只記錄 Shopee 失敗 |

### Edge Cases

| 情況描述 | 預期行為 |
|---|---|
| 所有平台同時不可用 | 標記所有 Collector Task 為 failed；P2 通知「掃描暫時中斷」|
| AI API 超時 | Analyzer Task 標記 failed；此 Listing 不發通知，等下次掃描重試 |
| WatchRule 的關鍵字包含特殊字元 | Parser 做 HTML entity decode 後再比對 |
| 商品價格為 0（免費送）| 合法情況，不觸發 suspicious_ratio 規則（0 < threshold × market_price 永遠為 false）|
| Listing 在 24 小時內價格變動 | 偵測到 raw_hash 改變 → 觸發重新分析 |

---

## 15. Sample Data（範例資料）

### 原始資料範例（ShopeeSearchCollector 輸出）

```json
{
  "raw": "{\"items\":[{\"item_id\":123456789,\"name\":\"LEGO 60197 城市系列 客運火車 二手 九成新\",\"price\":89000,\"price_min\":89000,\"price_max\":89000,\"item_rating\":{\"rating_star\":0},\"seller_id\":98765432,\"shop_name\":\"小明的玩具店\",\"shop_rating\":4.8,\"image\":\"xxxxxx.jpg\",\"stock\":1,\"liked_count\":3,\"sold\":0,\"cmt_count\":0,\"shop_location\":\"台北市\",\"shipping_fee_info\":{\"item_shop_free_ship_limit\":0}}]}",
  "source": "shopee",
  "query": "LEGO 城市系列",
  "fetched_at": "2026-06-27T10:00:00Z",
  "metadata": { "result_count": 1, "page": 1 }
}
```

### 解析後資料範例（Parser 輸出）

```json
{
  "id": "uuid-here",
  "platform": "shopee",
  "platform_listing_id": "123456789",
  "url": "https://shopee.tw/product/98765432/123456789",
  "title": "LEGO 60197 城市系列 客運火車 二手 九成新",
  "description": null,
  "condition": "like_new",
  "condition_raw": "九成新",
  "category": "lego",
  "subcategory": "城市系列",
  "images": ["https://cf.shopee.tw/file/xxxxxx.jpg"],
  "price": 890,
  "shipping_cost": 0,
  "total_price": 890,
  "seller_id": "98765432",
  "seller_name": "小明的玩具店",
  "seller_rating": 4.8,
  "location": "台北市",
  "status": "active",
  "listed_at": null,
  "last_seen_at": "2026-06-27T10:00:00Z",
  "raw_hash": "sha256:abcdef...",
  "created_at": "2026-06-27T10:00:05Z",
  "updated_at": "2026-06-27T10:00:05Z"
}
```

> 補充說明：Shopee 原始 price 欄位通常是「台幣 × 100」格式（89000 = NT$890），Parser 需做轉換。

### 分析後資料範例（Analyzer 輸出）

```json
{
  "deal_score": 0.82,
  "value_verdict": "good_deal",
  "condition_assessment": "賣家標示九成新，對 LEGO 而言通常表示積木完整、無缺件，但描述未提及說明書是否完整。",
  "risk_flags": [],
  "reason": "LEGO 60197 全新市場價約 NT$1,499，此件以 NT$890 出售（約 59% 市場價），狀況良好，賣家評分 4.8，整體評估為值得考慮的好物。建議詢問說明書是否完整。",
  "confidence": 0.88,
  "market_price_reference": 1499,
  "price_ratio": 0.59,
  "model_used": "claude-haiku-4-5-20251001"
}
```

---

## 16. Future Extensions（未來擴充）

### V2 計劃

- **Facebook Marketplace Collector**：需要維護一個已登入的 session，計劃在 V2 實作，屆時需要解決 auth token 的安全儲存問題（使用 Keychain / 加密 SQLite 欄位）
- **價格走勢分析**（`PriceTrendAnalyzer`）：追蹤特定商品類別的價格趨勢，在「LEGO 城市系列近期價格偏高，建議等待」時通知
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
