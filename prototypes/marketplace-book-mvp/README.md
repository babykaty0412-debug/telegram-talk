# Marketplace Book MVP (Path A Lite)

> First running code in PAOS. A deliberately tiny prototype whose **only goal** is:
> **verify the AI can correctly judge whether one Facebook secondhand-book post is worth notifying.**
>
> Scope and rationale: GOVR-PV-MKT-002 (Product Validation Execution Plan), Path A Lite.
> This is a **prototype**, not production — it lives under `prototypes/`, has no DB, no
> Dashboard, no scheduler, and covers one platform (Facebook) and one category (books).

## What it does (the 6 MVP steps)

1. **Parse** a Facebook post → structured `BookListing` (`facebookBookParser.ts`, deterministic)
2. **Identify** whether it's a book (`is_book`) — AI (`bookValueAnalyzer.ts`)
3. **Judge price** vs. estimated used-book market price → `deal_score` / `value_verdict` — AI
4. **Match** against a hardcoded `WatchRule` (`watchRuleMatcher.ts`, deterministic)
5. **Decide notification** P1/P2/skip (`notify.ts`, deterministic; BR-MKT-10/11)
6. **Confidence** — AI outputs `confidence` on every judgment

The AI step uses **`claude-haiku-4-5`** — the exact model DOMAIN-001 §12 names for the
analyzer, so this is a faithful test of the production choice. All AI access goes through
the `AIProvider` seam (`aiProvider.ts`), the only file importing the Anthropic SDK (P-07).

## Run it

```bash
npm install

# Real run — needs an Anthropic API key (never hardcode it; ADR-0009/0015):
export ANTHROPIC_API_KEY=sk-ant-...
npm start

# Offline wiring check — no key, no AI (uses a transparent stub analyzer):
npm run dry

# Type-check only:
npm run typecheck
```

`npm run dry` exercises **parse → match → notify** end-to-end and proves the pipeline
wiring; it does **not** test AI judgment (the stub is a fixed price heuristic, clearly
labelled). `npm start` is the actual product-validation run.

## Out of scope (deferred — see GOVR-PV-MKT-001 phased plan)

Comment analysis · sold detection · 套裝/bundle listings · OCR of post images ·
full Replay/Golden Dataset scoring · multi-platform · persistence · scheduler · Telegram delivery.

## Fixtures

`fixtures/posts.json` are **illustrative test inputs**, not Golden Dataset ground truth
(GOVR-006). They cover: clear good deal, overpriced, suspicious low-price, a non-book,
a "徵求/wanted" post (excluded keyword), an over-budget book, and a free giveaway.

## How this feeds Product Validation

A real run is the seed of **Price Analysis Accuracy** (GOVR-PV-MKT-002 #6): once a human
annotates these (and more) real posts with ground-truth verdicts, compare the AI's
`value_verdict` / `deal_score` against the annotations. This MVP makes that comparison
runnable; it does not by itself constitute the validation.
