// MVP subset of DOMAIN-001 data model. Single platform (facebook), single category (books).
// Intentionally narrower than the full Domain spec — see README "Out of scope".

export type Condition = 'new' | 'like_new' | 'good' | 'fair' | 'poor' | 'unknown';

export type ValueVerdict =
  | 'great_deal'
  | 'good_deal'
  | 'fair_price'
  | 'overpriced'
  | 'suspicious';

/** Structured listing parsed from a raw Facebook post (DOMAIN-001 §6, books-only subset). */
export interface BookListing {
  platform: 'facebook';
  category: 'books';
  title: string;
  description: string | null;
  condition: Condition;
  condition_raw: string | null;
  price: number; // TWD
  shipping_cost: number; // TWD, 0 = 免運 / 面交
  total_price: number; // price + shipping_cost
  image_count: number;
  seller_note: string | null;
}

/** Hardcoded WatchRule for the MVP (DOMAIN-001 §6). */
export interface WatchRule {
  name: string;
  keywords: string[];
  exclude_keywords: string[];
  max_total_price: number | null;
  min_condition: Condition | null;
  min_deal_score: number; // default 0.6
  notification_priority: 'P1' | 'P2' | 'P3';
}

/** AI judgment output (DOMAIN-001 §12 ListingValueAnalysis subset). */
export interface BookAnalysis {
  is_book: boolean;
  deal_score: number; // 0.0–1.0
  value_verdict: ValueVerdict;
  market_price_reference: number | null; // TWD the AI judged as the going used price
  price_ratio: number | null; // total_price / market_price_reference
  reason: string; // 繁體中文, shown to the user
  confidence: number; // 0.0–1.0
}

export type WatchRuleMatch =
  | { matched: true }
  | { matched: false; failed: string[] };

export type NotificationDecision =
  | { action: 'notify'; priority: 'P1' | 'P2' | 'P3'; message: string }
  | { action: 'skip'; reason: string };

/** End-to-end result for one post. */
export interface PipelineResult {
  listing: BookListing;
  analysis: BookAnalysis;
  match: WatchRuleMatch;
  notification: NotificationDecision;
  model_used: string;
}
