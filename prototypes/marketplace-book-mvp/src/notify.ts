// Deterministic notification decision + rendering (DOMAIN-001 §11/§15). No AI.
// Implements BR-MKT-10 (P1 ≥ 0.8) and BR-MKT-11 (P2 0.5–0.8), gated on WatchRule match
// and the rule's min_deal_score.

import type {
  BookAnalysis,
  BookListing,
  NotificationDecision,
  WatchRule,
  WatchRuleMatch,
} from './types.js';

const CONDITION_ZH: Record<string, string> = {
  new: '全新',
  like_new: '九成新',
  good: '良好',
  fair: '普通',
  poor: '差',
  unknown: '未知',
};

function renderP1(listing: BookListing, analysis: BookAnalysis, ruleName: string): string {
  return [
    `🎯 好物發現：${ruleName}`,
    ``,
    `📦 ${listing.title}`,
    `💰 NT$${listing.total_price}（含運）`,
    `✨ 狀況：${CONDITION_ZH[listing.condition]}｜DealScore：${(analysis.deal_score * 10).toFixed(1)}/10`,
    `📍 Facebook`,
    ``,
    `💬 ${analysis.reason}`,
  ].join('\n');
}

export function decideNotification(
  listing: BookListing,
  analysis: BookAnalysis,
  match: WatchRuleMatch,
  rule: WatchRule,
): NotificationDecision {
  if (!analysis.is_book) {
    return { action: 'skip', reason: 'AI 判斷這不是一本書。' };
  }
  if (!match.matched) {
    return { action: 'skip', reason: `不符合 WatchRule：${match.failed.join(', ')}` };
  }
  if (analysis.value_verdict === 'suspicious') {
    return { action: 'notify', priority: 'P3', message: `⚠️ 疑似異常：${analysis.reason}` };
  }
  if (analysis.deal_score < rule.min_deal_score) {
    return {
      action: 'skip',
      reason: `DealScore ${analysis.deal_score.toFixed(2)} 低於門檻 ${rule.min_deal_score}。`,
    };
  }
  if (analysis.deal_score >= 0.8) {
    return { action: 'notify', priority: 'P1', message: renderP1(listing, analysis, rule.name) };
  }
  // 0.5–0.8 → P2 (daily digest in the full Domain; here we just flag it)
  return {
    action: 'notify',
    priority: 'P2',
    message: `📊 候選好書（待每日摘要）：${listing.title} — NT$${listing.total_price}（${(analysis.deal_score * 10).toFixed(1)}/10）`,
  };
}
