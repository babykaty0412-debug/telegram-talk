// MarketplaceBookValueAnalyzer — the AI judgment step (DOMAIN-001 §12).
// Decides: is this a book? is the price a good deal? how confident?
// All AI access goes through the AIProvider seam (P-07) — no SDK import here.

import type { AIProvider } from './aiProvider.js';
import type { BookAnalysis, BookListing } from './types.js';

const OUTPUT_SCHEMA: Record<string, unknown> = {
  type: 'object',
  additionalProperties: false,
  properties: {
    is_book: { type: 'boolean' },
    deal_score: { type: 'number' },
    value_verdict: {
      type: 'string',
      enum: ['great_deal', 'good_deal', 'fair_price', 'overpriced', 'suspicious'],
    },
    market_price_reference: { type: ['number', 'null'] },
    price_ratio: { type: ['number', 'null'] },
    reason: { type: 'string' },
    confidence: { type: 'number' },
  },
  required: [
    'is_book',
    'deal_score',
    'value_verdict',
    'market_price_reference',
    'price_ratio',
    'reason',
    'confidence',
  ],
};

const SYSTEM = `你是二手書交易的價值評估助手。針對一筆 Facebook 二手書貼文，判斷：
1. 這是否真的是一本「書」（is_book）。
2. 相對於台灣二手書市場行情，這個價格是否值得購買。

評分規則：
- 先估計這本書在台灣二手市場的合理成交價（market_price_reference，新台幣；若無法判斷填 null）。
- price_ratio = 商品總價 / market_price_reference（market_price 為 null 時填 null）。
- deal_score 為 0.0–1.0，越高代表越划算。
- value_verdict 對應：
  great_deal(ratio ≤ 0.5) / good_deal(0.5–0.7) / fair_price(0.7–1.1) /
  overpriced(> 1.1) / suspicious（異常低價且無合理解釋、或明顯詐騙）。
- reason 用繁體中文，向使用者說明判斷依據，需具體（提到書名、行情、狀況）。
- confidence 為你對本次判斷的把握程度 0.0–1.0；行情不明確時降低。
只輸出符合 schema 的 JSON。`;

function buildUserPrompt(listing: BookListing): string {
  return [
    `平台：Facebook 二手書社團`,
    `標題：${listing.title}`,
    `描述：${listing.description ?? '（無）'}`,
    `標價：NT$${listing.price}`,
    `運費：NT$${listing.shipping_cost}`,
    `總價（含運）：NT$${listing.total_price}`,
    `狀況（已正規化）：${listing.condition}（原始描述：${listing.condition_raw ?? '無'}）`,
    `圖片數：${listing.image_count}`,
  ].join('\n');
}

function clamp01(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(1, n));
}

export class MarketplaceBookValueAnalyzer {
  constructor(
    private readonly ai: AIProvider,
    private readonly model: string,
  ) {}

  async analyze(listing: BookListing): Promise<BookAnalysis> {
    const raw = (await this.ai.generateJSON({
      system: SYSTEM,
      user: buildUserPrompt(listing),
      schema: OUTPUT_SCHEMA,
      model: this.model,
    })) as Partial<BookAnalysis>;

    // L1-style normalization of the AI output (DOMAIN-001 §13).
    return {
      is_book: Boolean(raw.is_book),
      deal_score: clamp01(Number(raw.deal_score)),
      value_verdict: raw.value_verdict ?? 'fair_price',
      market_price_reference:
        typeof raw.market_price_reference === 'number' ? raw.market_price_reference : null,
      price_ratio: typeof raw.price_ratio === 'number' ? raw.price_ratio : null,
      reason: String(raw.reason ?? ''),
      confidence: clamp01(Number(raw.confidence)),
    };
  }
}
