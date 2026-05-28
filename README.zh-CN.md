# LLM Switch Gateway

> **像 AI 工具的 UPS 不间断电源 — 一个端点，永不宕机。**

[🇬🇧 English](README.md) | [🇨🇳 中文](README.zh-CN.md) | [🇫🇷 Français](README.fr.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

**LLM Switch Gateway** 是一个轻量级故障转移代理，为你的所有 AI 工具提供一个 **统一的 OpenAI 兼容端点**。只需配置一次——当某个提供商配额耗尽、遇到速率限制或服务宕机时，它会自动切换。

```mermaid
flowchart LR
    Tool[你的 AI 工具<br/>Continue / Cline / Aider / 等]
    GW[LLM Switch Gateway<br/>localhost:3001]
    T1[包月计划 🥇]
    T2[按量付费 🥈]
    T3[免费额度 🥉]
    T4[本地 GPU 4️⃣]
    T5[本地小模型 5️⃣]
    T6[内置 Demo 🛟]

    Tool -->|http://localhost:3001/v1| GW
    GW --> T1 -->|失效| T2 -->|失效| T3 -->|失效| T4 -->|失效| T5 -->|失效| T6
```

---

## ✨ 特性

- **🔌 统一端点** — 所有 AI 工具指向 `http://localhost:3001/v1`，一次配置全家通用
- **🔄 自动容灾** — 6 层优先级，从云服务到本地 CPU，第一个 200 响应胜出
- **🆓 开箱即用** — 内置演示模式，不需要 API Key。克隆即可运行
- **🧠 真正的本地模型** — 安装 Qwen2.5-0.5B（~350MB），断网也能用 AI
- **📦 提供商模板** — 一条命令添加 DeepSeek、硅基流动、OpenAI 等
- **🛡️ 智能错误分类** — 准确识别 401/402/403/429，知道配额耗尽和速率限制的区别
- **🔀 流式传输支持** — 完整 SSE 流式转发，附带 `X-Provider-Id` 头部
- **⚖️ 单提供商超时** — 不会因为某个慢提供商阻塞整条链路

---

## 🚀 快速开始

```bash
# 1. 安装依赖
pip install flask requests

# 2. 启动 Gateway
llm-switch-gateway
```

```text
=======================================================
  LLM Switch Gateway — http://localhost:3001
=======================================================

  ⚠️  未配置任何提供商。
     安装本地模型: llm-switch install-local
     添加云提供商:  llm-switch provider add <模板名> --key <密钥>

    [local_demo     ] 内置演示 (兜底) → 始终可用

  📡 POST /v1/chat/completions   ← OpenAI 格式
  📡 GET  /v1/models              ← 聚合模型列表
  📡 GET  /health                  ← 健康检查
```

**已经跑起来了。** 不需要 API Key，不需要配置。

```bash
# 试试看
curl http://localhost:3001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"demo-model","messages":[{"role":"user","content":"你好！"}]}'
```

演示响应会教你如何添加真正的提供商和安装本地模型。

---

## 🔑 获取免费 API Key

最快上手方式——国内用户推荐，无需翻墙。

### ▶️ 推荐：硅基流动

[硅基流动 (SiliconFlow)](https://cloud.siliconflow.cn?ref=llmswitch_xbs) 是国内领先的 LLM 聚合平台，提供：

- **首充 34 元送 14 元**，相当于 48 元余额
- **免费模型**：Qwen2-7B、GLM-4-9B 等，适合兜底
- **按量付费模型**：DeepSeek V3、Qwen2.5-72B、Qwen3-235B 等顶尖开源模型
- **国内服务器**低延迟推理，不需要 VPN

```bash
# 1. 注册：https://cloud.siliconflow.cn?ref=llmswitch_xbs
# 2. 在控制台创建 API Key：https://cloud.siliconflow.cn/account/ak
# 3. 添加到 LLM Switch：
llm-switch provider add siliconflow-payg --key sk-你的密钥
llm-switch provider add siliconflow-free --key sk-你的密钥
```

> 💡 **免费模型适合日常开发辅助，按量付费模型在需要更强能力时自动顶上。** 如果免费额度不够，建议配置 DeepSeek 按量付费作为第二层保障。

### ▶️ 备选：DeepSeek

[DeepSeek](https://platform.deepseek.com/) 提供：
- **包月 Coding Plan** — ¥50/月，无限 tokens（限 deepseek-chat）
- **按量付费** — deepseek-v4-flash 低至 ¥0.5/M tokens
- 适合作为 Tier 1 主力提供商

```bash
llm-switch provider add deepseek-cp --key sk-你的密钥
llm-switch provider add deepseek-payg --key sk-你的密钥
```

---

## 🧠 安装本地模型

不需要任何 API Key，在本地运行真正的 AI 模型：

```bash
# 交互式安装 — 下载前会询问确认
llm-switch install-local
```

或者跳过确认：

```bash
llm-switch install-local --yes
```

安装过程：

1. `pip install llama-cpp-python`（CPU 版本，预编译 wheel）
2. 下载 **Qwen2.5-0.5B-Instruct-Q4_K_M.gguf**（~350MB）
3. 注册为 Tier 5（`local_tiny`）
4. 重启 Gateway — 现在用的是 **真 AI 模型**，不再是演示模式

模型完全在 CPU 上运行，每次响应约 2-3 秒，完全离线可用。

> 💡 **已有 Ollama？** 安装器会自动检测 `localhost:11434` 的 Ollama 服务并配置。

---

## ☁️ 云提供商模板

```bash
# 查看可用模板
llm-switch provider templates
```

```text
=======================================================
  Provider 模板库
=======================================================

  ⭐ 包月 Coding Plan (Tier 1):
    deepseek-cp               → https://api.deepseek.com/v1
    huoshan-cp                → https://ark.cn-beijing.volces.com/api/v3

  💰 按量付费 (Tier 2):
    deepseek-payg             → https://api.deepseek.com/v1
    siliconflow-payg ★        → https://api.siliconflow.cn/v1（国内推荐）
    openai-payg               → https://api.openai.com/v1
    openrouter-payg           → https://openrouter.ai/api/v1

  🆓 免费额度 (Tier 3):
    siliconflow-free ★        → https://api.siliconflow.cn/v1（国内推荐）
    openrouter-free           → https://openrouter.ai/api/v1

  🖥️ 本地大模型 (Tier 4):
    qwen27b-direct            → http://192.168.1.100:8080/v1 (llama.cpp)
    qwen35b-uncensored        → http://192.168.1.100:8080/v1 (CPU)
```

添加提供商：

```bash
# 添加包月计划 (Tier 1 — 最优先尝试)
llm-switch provider add deepseek-cp --key sk-你的密钥

# 添加硅基流动按量付费 (Tier 2)
llm-switch provider add siliconflow-payg --key sk-你的密钥

# 添加免费模型兜底 (Tier 3)
llm-switch provider add siliconflow-free --key sk-你的密钥

# 添加本地模型 (Tier 4) — 连接 llama.cpp/Ollama
llm-switch provider add qwen27b-direct
```

添加完成后重启 Gateway：

```bash
llm-switch gateway restart
# 或
llm-switch gateway start
```

---

## 🔗 集成你的工具

所有支持 OpenAI 兼容 API 的工具都指向 **同一个端点**：

| 工具 | 配置方式 |
|------|---------|
| [Continue](https://docs.continue.dev/) | `apiBase: "http://localhost:3001/v1"` |
| [Cline](https://github.com/cline/cline) | OpenAI 兼容提供商 → `http://localhost:3001/v1` |
| [Aider](https://aider.chat/) | `export OPENAI_API_BASE=http://localhost:3001/v1` |
| [Hermes Agent](https://hermes-agent.nousresearch.com/) | 添加 provider，`base_url: http://localhost:3001/v1` |
| [OpenAI Python SDK](https://pypi.org/project/openai/) | `client = OpenAI(base_url="http://localhost:3001/v1")` |
| [curl](https://curl.se/) | `curl http://localhost:3001/v1/chat/completions ...` |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) | 通过 LiteLLM 桥接 → Gateway |

---

## 🏗 架构

### 6 层故障转移链

```
┌──────────────────────────────────────────────────────────┐
│              LLM Switch Gateway                          │
│  localhost:3001/v1                                       │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐                                            │
│  │  请求    │  → DeepSeek 包月 (Tier 1) ─── 200? ──→ ✅ │
│  │          │    ↓ 失败 (401/402/超时)                    │
│  │          │  → DeepSeek 按量 (Tier 2) ─── 200? ──→ ✅ │
│  │          │    ↓ 失败                                   │
│  │          │  → 硅基流动免费 (Tier 3) ─ 200? ──→ ✅    │
│  │          │    ↓ 失败                                   │
│  │          │  → 本地 GPU (Tier 4) ─────── 200? ──→ ✅  │
│  │          │    ↓ 失败                                   │
│  │          │  → 本地小模型 (Tier 5) ──── 200? ──→ ✅   │
│  │          │    ↓ 未安装                                  │
│  │          │  → 内置演示 (Tier 6) ─── 始终 ───→ ✅     │
│  └──────────┘                                            │
│                                                          │
│  策略：第一个 200 胜出。                                   │
│  不做健康检查——每次请求就是一次真实探测。                  │
└──────────────────────────────────────────────────────────┘
```

关键设计决策：

- **不做后台健康检查** — 每次请求就是一次健康检查。每次失败多花 ~200ms，但避免了状态过期和误报。
- **不支持 Anthropic 格式** — 90% 的工具都支持 OpenAI 格式。Claude Code 通过 LiteLLM 桥接。
- **逐提供商错误分类** — 硅基流动 403 是"配额耗尽"。DeepSeek 402 是"余额不足"。每个提供商独立处理。
- **流式透传** — SSE 流透明转发，附带 `X-Provider-Id` 头部标明是哪个提供商处理的请求。

### 提供商模板

模板定义了每个提供商的 API 端点、支持模型、超时和错误识别模式：

```json
{
  "id": "siliconflow-payg",
  "name": "硅基流动 按量付费",
  "tier": "payg",
  "api_base": "https://api.siliconflow.cn/v1",
  "models": ["deepseek-ai/DeepSeek-V3", "Qwen/Qwen2.5-72B-Instruct"],
  "timeout": 15,
  "registration_url": "https://cloud.siliconflow.cn?ref=llmswitch_xbs",
  "error_map": {
    "auth_failed":     {"status": [401], "body_contains": ["invalid_api_key"]},
    "quota_exhausted": {"status": [402], "body_contains": ["insufficient_balance"]},
    "rate_limited":    {"status": [429], "body_contains": ["rate_limit"]}
  }
}
```

---

## 📦 CLI 命令参考

```text
用法：
  llm-switch list                    列出所有提供商
  llm-switch use <id>                切换当前提供商
  llm-switch status                  显示当前状态
  llm-switch env                     显示环境变量
  llm-switch doctor                  检查所有工具配置
  llm-switch panel                   打开 Web 管理面板
  llm-switch install-local           安装本地小模型 (CPU)
  llm-switch gateway <start|stop|status>  故障转移网关
  llm-switch provider <add|list|templates>  提供商管理
```

---

## 🔧 配置

默认配置文件 `~/.llm-switch/config.json`：

```json
{
  "providers": [
    {
      "id": "siliconflow-payg",
      "name": "硅基流动 按量付费",
      "type": "cloud",
      "tier": "payg",
      "gateway": true,
      "template_id": "siliconflow-payg",
      "api_key_env": "SILICONFLOW_KEY",
      "api_base": "https://api.siliconflow.cn/v1",
      "models": ["deepseek-ai/DeepSeek-V3", "Qwen/Qwen2.5-72B-Instruct"],
      "timeout": 15
    }
  ],
  "gateway": {
    "port": 3001,
    "no_demo": false
  }
}
```

API Key 的解析顺序：

1. 配置中的 `api_key` 字段（如果是有效的 key）
2. `env:<变量名>` 引用（例如 `"api_key": "env:SILICONFLOW_KEY"`）
3. `api_key_env` 字段（例如 `"api_key_env": "SILICONFLOW_KEY"`）
4. 按约定：`{大写ID}_KEY`（例如 `SILICONFLOW_KEY`）

---

## 📋 环境要求

- **Python 3.10+**，需安装 `flask` 和 `requests`
- **~350MB 磁盘空间**（如果安装本地模型）
- **不需要 GPU** — 内置模型在 CPU 上运行

---

## 🔄 与同类工具的对比

| 特性 | One API / LiteLLM | **LLM Switch Gateway** |
|------|-------------------|----------------------|
| 设计理念 | "选一个通道" | "绝不能宕机" |
| 故障转移 | 手动切换通道 | **自动链式故障转移** |
| 本地模型 | 不支持 | **内置 Qwen2.5-0.5B** |
| 演示模式 | 需要 API Key | **开箱即用** |
| 配置复杂度 | 多套配置 | **统一端点** |
| 错误分类 | 通用 HTTP | **逐提供商模式** |
| 代码量 | 大型（多服务） | **~700 行 Python** |

---

## 📜 开源协议

MIT — 随便你怎么用。

---

## 🙏 致谢

- [Qwen/Qwen2.5-0.5B](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF) — 小巧但强大的模型
- [llama-cpp-python](https://github.com/abetlen/llama-cpp-python) — 本地推理引擎
- 让 AI 触手可及的整个 LLM 社区