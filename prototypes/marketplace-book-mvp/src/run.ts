// MVP orchestrator (DOMAIN-001 §17 marketplace-scan, single-post slice).
// Pipeline: parse -> analyze (AI) -> match WatchRule -> decide notification.
//
//   npm start        real run; requires ANTHROPIC_API_KEY
//   npm run dry      runs parse -> match -> notify with a STUB analyzer (no API key,
//                    no AI). Verifies the deterministic pipeline wiring only.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import { AnthropicProvider, type AIProvider, type GenerateJSONParams } from './aiProvider.js';
import { MarketplaceBookValueAnalyzer } from './bookValueAnalyzer.js';
import { parseFacebookBookPost, type RawFacebookPost } from './facebookBookParser.js';
import { matchWatchRule } from './watchRuleMatcher.js';
import { decideNotification } from './notify.js';
import type { PipelineResult, WatchRule } from './types.js';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');

const DRY = process.argv.includes('--dry');
const MODEL = process.env.MARKETPLACE_MVP_MODEL ?? 'claude-haiku-4-5';

/** Stub provider for --dry: a transparent price heuristic, NOT real AI judgment. */
class StubProvider implements AIProvider {
  readonly label = 'dry-stub (NOT real AI)';
  async generateJSON(params: GenerateJSONParams): Promise<unknown> {
    const totalMatch = params.user.match(/總價（含運）：NT\$([0-9]+)/);
    const total = totalMatch ? Number(totalMatch[1]) : 300;
    // Naive heuristic so the wiring is exercisable offline.
    const market = 400;
    const ratio = total / market;
    const deal_score = Math.max(0, Math.min(1, 1 - ratio * 0.8));
    const verdict =
      ratio <= 0.5 ? 'great_deal' : ratio <= 0.7 ? 'good_deal' : ratio <= 1.1 ? 'fair_price' : 'overpriced';
    return {
      is_book: true,
      deal_score,
      value_verdict: verdict,
      market_price_reference: market,
      price_ratio: ratio,
      reason: `[DRY STUB] 以固定行情 NT$${market} 估算，總價 NT$${total}，price_ratio ${ratio.toFixed(2)}。此為離線佔位結果，非真實 AI 判斷。`,
      confidence: 0.3,
    };
  }
}

function loadJSON<T>(rel: string): T {
  return JSON.parse(readFileSync(join(root, rel), 'utf8')) as T;
}

async function main(): Promise<void> {
  const rule = loadJSON<WatchRule>('fixtures/watchrule.json');
  const posts = loadJSON<RawFacebookPost[]>('fixtures/posts.json');

  const provider: AIProvider = DRY ? new StubProvider() : new AnthropicProvider();
  const analyzer = new MarketplaceBookValueAnalyzer(provider, MODEL);

  console.log(`Marketplace Book MVP — provider=${provider.label} model=${DRY ? '(none)' : MODEL}`);
  console.log(`WatchRule: ${rule.name}\n`);

  const results: PipelineResult[] = [];
  for (const post of posts) {
    let listing;
    try {
      listing = parseFacebookBookPost(post); // step 1: parse
    } catch (e) {
      console.log(`— DROPPED: ${(e as Error).message}\n`);
      continue;
    }
    const analysis = await analyzer.analyze(listing); // steps 2,3,6: identify + price + confidence
    const match = matchWatchRule(listing, rule); // step 4: WatchRule
    const notification = decideNotification(listing, analysis, match, rule); // step 5: notify

    results.push({ listing, analysis, match, notification, model_used: DRY ? 'dry-stub' : MODEL });

    console.log(`📄 ${listing.title}`);
    console.log(
      `   parsed: NT$${listing.total_price} (price ${listing.price} + ship ${listing.shipping_cost}), condition=${listing.condition}`,
    );
    console.log(
      `   AI: is_book=${analysis.is_book} verdict=${analysis.value_verdict} deal=${analysis.deal_score.toFixed(2)} conf=${analysis.confidence.toFixed(2)} mkt=${analysis.market_price_reference ?? 'n/a'}`,
    );
    console.log(`   match: ${match.matched ? 'YES' : 'NO (' + match.failed.join(',') + ')'}`);
    console.log(
      `   notify: ${notification.action === 'notify' ? notification.priority : 'skip'} — ${notification.action === 'notify' ? notification.message.split('\n')[0] : notification.reason}`,
    );
    console.log('');
  }

  const notified = results.filter((r) => r.notification.action === 'notify').length;
  console.log(`Done. ${results.length} listing(s) analyzed, ${notified} would notify.`);
  if (DRY) {
    console.log('\n⚠️  DRY mode: AI judgment was a stub. Run `npm start` with ANTHROPIC_API_KEY for real judgment.');
  }
}

main().catch((e) => {
  console.error('Error:', (e as Error).message);
  process.exitCode = 1;
});
