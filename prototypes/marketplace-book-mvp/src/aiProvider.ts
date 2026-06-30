// AIProvider seam (P-07). Business logic (the analyzer) depends ONLY on the AIProvider
// interface — never on a concrete SDK or a specific model. Which provider/model runs is
// decided by the EXECUTION ENVIRONMENT, not the domain logic.
//
// P-14 (Secrets Never Leave the Runtime): providers read their own credentials from the
// environment (env var / Secret Manager). The caller never passes a key — it only gets a
// Provider instance back. Adding a new provider = add a class here implementing AIProvider;
// no domain code changes. Anthropic below is the current instantiation, not the definition.

import Anthropic from '@anthropic-ai/sdk';

export interface GenerateJSONParams {
  system: string;
  user: string;
  /** Output shape the analyzer expects (provider-agnostic; given to the model as guidance). */
  schema: Record<string, unknown>;
  /** Model id, supplied by the execution environment. */
  model: string;
}

export interface AIProvider {
  /** Returns the model's response parsed as JSON. */
  generateJSON(params: GenerateJSONParams): Promise<unknown>;
  readonly label: string;
}

/**
 * Select the provider from the execution environment.
 * MARKETPLACE_MVP_PROVIDER picks the implementation (default: anthropic).
 * Each provider resolves its own credential from the env (P-14) — never from here.
 */
export function createProvider(name = process.env.MARKETPLACE_MVP_PROVIDER ?? 'anthropic'): AIProvider {
  switch (name) {
    case 'anthropic':
      return new AnthropicProvider();
    // Future: case 'openai': return new OpenAIProvider();  — same interface, no domain change.
    default:
      throw new Error(`Unknown MARKETPLACE_MVP_PROVIDER: ${name}`);
  }
}

/** Anthropic instantiation. Reads ANTHROPIC_API_KEY from the environment (never hardcoded). */
export class AnthropicProvider implements AIProvider {
  readonly label = 'anthropic';
  private client = new Anthropic(); // resolves ANTHROPIC_API_KEY from env (P-14)

  async generateJSON(params: GenerateJSONParams): Promise<unknown> {
    // JSON is requested via prompt instruction (version-robust across SDK releases).
    // The caller validates/normalizes the parsed object, so a strict response schema
    // is not required for this prototype.
    const system =
      `${params.system}\n\n只輸出一個符合下列 JSON Schema 的 JSON 物件，不要有任何其他文字或 markdown 圍欄：\n` +
      JSON.stringify(params.schema);

    const response = await this.client.messages.create({
      model: params.model,
      max_tokens: 1024,
      system,
      messages: [{ role: 'user', content: params.user }],
    });

    if (response.stop_reason === 'refusal') {
      throw new Error('AI refused the request (stop_reason=refusal).');
    }
    const textBlock = response.content.find((b) => b.type === 'text');
    if (!textBlock || textBlock.type !== 'text') {
      throw new Error('No text block in AI response.');
    }
    return JSON.parse(stripFences(textBlock.text));
  }
}

/** Tolerate ```json fences if the model adds them despite instructions. */
function stripFences(text: string): string {
  const t = text.trim();
  const m = t.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
  return m && m[1] ? m[1] : t;
}
