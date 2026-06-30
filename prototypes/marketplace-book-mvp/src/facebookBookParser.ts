// Deterministic parser: raw Facebook post text -> BookListing (DOMAIN-001 §10).
// No AI here. Extracts price, condition, shipping from free-form Chinese post text.
// ConditionNorm mapping is inlined for the MVP; in the full Domain it lives in
// the Knowledge layer (TMPL-001 §11 / DOMAIN-001 §11).

import type { BookListing, Condition } from './types.js';

const CONDITION_NORM: Array<[RegExp, Condition]> = [
  [/全新|未拆|未使用/, 'new'],
  [/九成新|9成新|近全新|幾乎全新/, 'like_new'],
  [/八成新|8成新|七成新|7成新|良好/, 'good'],
  [/六成新|6成新|五成新|5成新|普通|有使用痕跡/, 'fair'],
  [/破損|缺頁|嚴重|泛黃嚴重|筆記多/, 'poor'],
];

function normalizeCondition(text: string): { condition: Condition; raw: string | null } {
  for (const [re, cond] of CONDITION_NORM) {
    const m = text.match(re);
    if (m) return { condition: cond, raw: m[0] };
  }
  return { condition: 'unknown', raw: null };
}

/** Pulls the first NT$ / 元 price out of the text. Returns null if none found. */
function extractPrice(text: string): number | null {
  // Matches: NT$350 / $350 / 350元 / 售350 / 售價 350
  const patterns = [
    /(?:NT\$|\$)\s*([0-9][0-9,]*)/i,
    /(?:售價|售|價|只要|出)\s*\$?\s*([0-9][0-9,]*)\s*(?:元|塊)?/,
    /([0-9][0-9,]*)\s*元/,
  ];
  for (const re of patterns) {
    const m = text.match(re);
    if (m && m[1]) {
      const n = Number(m[1].replace(/,/g, ''));
      if (Number.isFinite(n)) return n;
    }
  }
  return null;
}

function extractShipping(text: string): number {
  if (/免運|含運|面交免費|自取/.test(text)) return 0;
  const m = text.match(/(?:運費|郵寄|寄送)\s*\+?\s*\$?\s*([0-9]+)/);
  if (m && m[1]) return Number(m[1]);
  return 0; // MVP default: assume face-to-face / free shipping when unspecified
}

function firstLineAsTitle(text: string): string {
  const line = text.split('\n').map((l) => l.trim()).find((l) => l.length > 0);
  return (line ?? text.trim()).slice(0, 120);
}

export interface RawFacebookPost {
  text: string;
  image_count: number;
}

/**
 * Parse a raw FB post into a BookListing.
 * Throws on invalid data (BR-MKT-02 / BR-MKT-03) so the caller can drop it.
 */
export function parseFacebookBookPost(post: RawFacebookPost): BookListing {
  const text = post.text;
  const title = firstLineAsTitle(text);
  if (!title) throw new Error('BR-MKT-03: empty title — dropped.');

  const price = extractPrice(text);
  if (price === null) throw new Error('Parser: no price found — dropped.');
  if (price < 0) throw new Error('BR-MKT-02: negative price — dropped.');

  const shipping_cost = extractShipping(text);
  const { condition, raw } = normalizeCondition(text);

  return {
    platform: 'facebook',
    category: 'books',
    title,
    description: text.length > title.length ? text : null,
    condition,
    condition_raw: raw,
    price,
    shipping_cost,
    total_price: price + shipping_cost, // BR-MKT-01
    image_count: post.image_count,
    seller_note: null,
  };
}
