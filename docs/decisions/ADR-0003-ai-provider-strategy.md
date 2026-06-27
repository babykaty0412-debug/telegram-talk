---
doc_type: adr
doc_id: ADR-0003
title: AI Provider Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0006, ADR-0009]
tags: [ai, provider, abstraction]
---

# ADR-0003: AI Provider Strategy

## 狀態

`Accepted`

## 背景（Context）

PAOS 的核心能力依賴 AI。目前使用 Claude，未來可能需要 ChatGPT（OpenAI）、Gemini、Ollama（本地模型）等。

如果不抽象化 AI 呼叫，每次換模型都需要修改業務邏輯。這違反 PAOS 的可擴充原則。

---

## 決策（Decision）

**所有 AI 呼叫透過統一的 `AIProvider` 介面，禁止任何業務邏輯直接呼叫特定 AI 的 SDK。**

---

## AI Provider 介面設計原則

### 核心操作（必須抽象化）

| 操作 | 說明 |
|---|---|
| `complete(prompt, options)` | 單次文字生成 |
| `stream(prompt, options)` | 串流生成 |
| `embed(text)` | 文字向量化（用於知識庫語意搜尋） |
| `toolCall(prompt, tools, options)` | 帶工具呼叫的生成 |

### Provider 實作（Adapter 模式）

```
AIProvider（介面）
├── ClaudeProvider（實作）
├── OpenAIProvider（實作）
├── GeminiProvider（實作）
└── OllamaProvider（實作，本地模型）
```

### 路由策略（Router）

PAOS 支援為不同用途指定不同的 Provider：

| 用途 | 預設 Provider | 可替換 |
|---|---|---|
| 一般對話 | Claude | ✅ |
| 知識庫向量化 | OpenAI (embedding) | ✅ |
| 輕量任務（分類、摘要） | Claude Haiku / GPT-4o-mini | ✅ |
| 本地敏感資料處理 | Ollama | ✅ |

---

## 後果（Consequences）

### 正面影響
- 切換 Provider 不改業務邏輯
- 可以針對不同任務選擇最適合的模型
- 本地模型（Ollama）支援資料不出境的需求

### 負面影響（需接受的取捨）
- 需要維護多個 Provider 的 Adapter 實作
- 不同 Provider 的能力不對等（例如 tool calling 的支援程度不同），介面需要處理降級

### 風險與緩解措施
- **風險**：介面設計無法完美覆蓋所有 Provider 的差異
- **緩解**：介面設計以「最大公約數」為基礎，Provider-specific 功能透過 optional extensions 暴露

---

## 實施原則

1. `packages/ai-provider/` 是唯一可以 import AI SDK 的地方
2. 所有業務邏輯只 import `AIProvider` 介面，不 import 任何具體 SDK（`@anthropic-ai/sdk`、`openai` 等）
3. Provider 切換透過設定檔（`config/providers.json`），不改程式碼
4. 每個 Provider 的 adapter 都必須實作完整的介面，用 `NotImplemented` 標記尚不支援的操作

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | Embedding 是否需要獨立的抽象層？（有些模型不支援 embedding） | Open |
| 2 | 如何處理不同 Provider 的 context window 差異？ | Open |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版 |
