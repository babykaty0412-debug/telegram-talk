// AIProvider seam — the ONLY module allowed to import the Anthropic SDK (P-07).
// Business logic (the analyzer) depends on the AIProvider interface, never on the SDK.
// Swapping providers, adding retries/rate-limiting, or routing to a different model
// happens here without touching domain logic.

import Anthropic from '@anthropic-ai/sdk';

export interface GenerateJSONParams {
  system: string;
  user: string;
  /** JSON Schema constraining the output (Anthropic structured outputs). */
  schema: Record<string, unknown>;
  model: string;
}

export interface AIProvider {
  /** Returns the model's response parsed as JSON, validated against `schema`. */
  generateJSON(params: GenerateJSONParams): Promise<unknown>;
  readonly label: string;
}

/** Real provider. Reads ANTHROPIC_API_KEY from the environment (never hardcoded). */
export class AnthropicProvider implements AIProvider {
  readonly label = 'anthropic';
  private client = new Anthropic(); // resolves ANTHROPIC_API_KEY from env

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
