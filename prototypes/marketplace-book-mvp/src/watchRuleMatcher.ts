// Deterministic WatchRule matching (DOMAIN-001 §17 Step 4). No AI.

import type { BookListing, Condition, WatchRule, WatchRuleMatch } from './types.js';

const CONDITION_RANK: Record<Condition, number> = {
  poor: 1,
  fair: 2,
  good: 3,
  like_new: 4,
  new: 5,
  unknown: 0,
};

export function matchWatchRule(listing: BookListing, rule: WatchRule): WatchRuleMatch {
  const failed: string[] = [];
  const haystack = `${listing.title}\n${listing.description ?? ''}`.toLowerCase();

  // Must contain at least one keyword.
  if (rule.keywords.length > 0) {
    const hit = rule.keywords.some((k) => haystack.includes(k.toLowerCase()));
    if (!hit) failed.push('keywords');
  }

  // Must contain none of the exclude keywords.
  const excluded = rule.exclude_keywords.find((k) => haystack.includes(k.toLowerCase()));
  if (excluded) failed.push(`exclude_keyword:${excluded}`);

  // Price ceiling (BR-MKT, includes shipping).
  if (rule.max_total_price !== null && listing.total_price > rule.max_total_price) {
    failed.push('max_total_price');
  }

  // Minimum condition. unknown never satisfies a min_condition requirement.
  if (rule.min_condition !== null) {
    if (CONDITION_RANK[listing.condition] < CONDITION_RANK[rule.min_condition]) {
      failed.push('min_condition');
    }
  }

  return failed.length === 0 ? { matched: true } : { matched: false, failed };
}
