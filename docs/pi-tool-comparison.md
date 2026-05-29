# Pi vs Bounce — Deep Research (2026-05-29)

Source: 微信公众号文章「Qwen3.6-35B-A3B本地代理终于有标准作业了！Pi + llama.cpp 完整配置公开，命令、坑点、Vision 一次讲透」
Author: 未来跃迁
URL: https://mp.weixin.qq.com/s/nznIdPiEZCopoUS9EgQlbQ

## What is Pi?

Pi is a **local agentic coding framework** endorsed by Hugging Face product lead Victor Mustar. 
It does NOT do model inference — it does **agent loop**:
- Connects to an LLM backend (via OpenAI-compatible API)
- Reads repo files, writes code, runs shell commands
- Iterates on tasks multi-turn

**Architecture:**
```
llama-server (推理层) → Pi (agent层) → 项目目录
```

**Config** (`~/.pi/agent/models.json`):
```json
{
  "providers": {
    "llama-cpp": {
      "baseUrl": "http://127.0.0.1:8080/v1",
      "api": "openai-completions",
      "apiKey": "none",
      "models": [{
        "id": "unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_XL",
        "input": ["text", "image"]     // ← Vision support
      }]
    }
  }
}
```

**Key insight**: Vision support requires explicit `"input": ["text", "image"]` — not auto-detected.

## Pi vs Bounce

| Dimension | Pi | Bounce |
|---|---|---|
| **Layer** | Agent (consumes LLM) | Infrastructure (between tool ↔ LLM) |
| **Job** | Write code, read files, run commands | Route requests, failover, unified endpoint |
| **Config** | One models.json → one backend | multi-tier config.json → many providers |
| **Vision** | `input: ["text","image"]` declaration | Transparent passthrough |
| **Provider** | Single at a time | Multi-tier with auto-failover |
| **Upstream** | OpenAI API (agent → LLM) | OpenAI API (tools → gateway) |
| **Downstream** | Developer CLI | Any tool (Claude Code, Continue, TRAE, Hermes) |
| **User** | Developer building local coding env | User needing HA + unified endpoint |
| **Philosophy** | "How to get a local model to work?" | "How to never break even when providers die?" |

> Pi = agent. Bounce = router. Complementary, not competing.

## What Bounce Can Learn from Pi

1. **Vision declaration pattern**: Pi's `"input": ["text", "image"]` is clean. Bounce could let providers declare capability flags, and skip tiers that can't handle the request type (e.g., skip local Qwen if it's a vision request going through a text-only model).

2. **Clean layer separation**: llama.cpp ↔ Pi is the same pattern as providers ↔ Bounce. The article's insight "推理层归推理层，代理层归代理层" applies directly.

3. **SOP-ified config**: Article's value is "command + JSON together". Bounce's `bounce provider add` already does this; keep pushing templates with complete, copy-paste-ready configs.

4. **Smoke test workflow**: Pi's 3-step test (read README → create → fix bug) is a model. Bounce could offer `bounce test` to verify each tier end-to-end.

## Customer Pain Points (from the article + Bounce context)

| Pain | Manifestation | Bounce's Solution |
|---|---|---|
| **Config fragmentation** | Every tool needs its own endpoint/key | One endpoint localhost:3001 for all |
| **Provider failure opaque** | Tool breaks, user doesn't know why | Auto failover, transparent */
| **Local vs cloud anxiety** | "Should I use DeepSeek or local Qwen?" | Voltage: cloud first → fallback to local → demo |
| **Context window traps** | Ollama default 2k silently drops context | Bounce passes requests through unmodified |
| **Demo → real work gap** | Works in isolation, breaks in production | UPS design = never down |
| **GGUF quantization paralysis** | Too many versions, don't know which to pick | Bounce doesn't care — pass model name through |
| **Per-tool config mismatch** | Different providers per tool, switching costs | Single endpoint, single config | 

## Bounce + Pi Integration

Pi connects to **any OpenAI-compatible endpoint**. Bounce exposes one at `localhost:3001/v1`.

```
Pi (agent layer, consumes API)
  ↓ baseUrl: http://localhost:3001/v1
Bounce Gateway (infra layer, routes + failover)
  ├── 🥇 火山 Coding Plan
  ├── 🥈 DeepSeek 包月
  ├── 🥉 本地 Qwen (L20 llama-server)
  ├── 4️⃣ 硅基流动免费
  └── 🛟 Demo
```

**Pi's models.json pointing to Bounce:**
```json
{
  "providers": {
    "bounce": {
      "baseUrl": "http://127.0.0.1:3001/v1",
      "api": "openai-completions",
      "apiKey": "bounce",
      "models": [{
        "id": "deepseek-v4-flash",
        "input": ["text", "image"]
      }]
    }
  }
}
```

**Key insight**: Pi doesn't know (or care) which backend Bounce picks. It just sends requests to `localhost:3001/v1` and gets responses. Bounce handles all failover transparently. This is the same pattern as TRAE, Crush, Hermes — all point to Bounce, all get failover for free.

This is the cleanest expression of Bounce's UPS philosophy: **one endpoint for all your tools, one failover chain to keep them working**.

## Bounce's UPS Philosophy vs Other Approaches

| Philosophy | Description | Tools |
|---|---|---|
| **UPS failover** | Single endpoint, many backends, auto-fallback | Bounce |
| **Agent-first** | Agent consumes LLM directly, handles logic | Pi, Aider, Claude Code |
| **Model router** | Switch between models manually or by request | OpenRouter, LiteLLM |
| **Local-first** | Run local model, no cloud dependency | Ollama, llama.cpp, LM Studio |

Bounce's tier structure aligns with this:
```
🥇 coding_plan (包月) → 🥈 payg (按量) → 🥉 free (免费) → 🖥️ local → 📄 demo
```
