# Bounce Gateway — 产品 & 开发文档

> 写给 Claude Code 的产品需求 + 开发指南。  
> 作者：X博士（产品定义）  
> 开发者：Claude Code（实现）

---

## 一、产品定位（一句话）

**Bounce 是 AI 工具的 UPS——一个端点多后端、自动 failover、零配置变更的统一模型路由网关。**

用户的所有 AI 工具（TRAE、VS Code Continue、Claude Code、Pi、Crush、Hermes）只需配置一个端点 `http://localhost:3001/v1`，Bounce 在背后管理多 provider 的 failover 路由。

---

## 二、用户痛点（为什么需要 Bounce）

### 痛点 1：LLM 短线（安全感）
- 包月 Coding Plan 用完了 → 工具直接报错，工作流中断
- API 临时故障（DeepSeek 经常超时） → 用户不知道是 key 问题还是网络问题
- 一个 provider 挂了 → 所有工具一起挂

**Bounce 解决**：自动 failover。包月用完→自动切按量→免费→本地模型。用户无感。

### 痛点 2：Provider 碎片化（省事）
- 每个工具要单独配 API base、key、model
- 换 provider 要改 6 个配置文件
- 新来的模型不知道怎么配

**Bounce 解决**：一个 endpoint 搞定所有工具。换 provider 只需改 Bounce 的 config.json。

### 痛点 3：本地模型配置难（费时）
- llama.cpp、Ollama、GGUF 各种版本，选哪个？
- 配错了 debug 半天
- 本地模型和云模型切换麻烦

**Bounce 解决**：`bounce install-local` 一键装好 Qwen2.5-0.5B（350MB CPU 可跑），自动注册为兜底层。

---

## 三、用户爽点（为什么用户会留下来）

### Tier 3：每周尝鲜版 LLM（黏性核心）

用户不需要自己找新模型。我（X博士）每周自动推送最新 LLM 模型更新到 Tier 3。

**为什么这是爽点：**
- **发现成本为零**：不用刷 Twitter/X、不用追 HuggingFace Daily Papers
- **试错成本为零**：Bounce 兜底，新模型不好用自动降级，用户零风险
- **"别人还在搜教程，我已经用上了"** 的优越感
- 类似 `brew update && brew upgrade` 的体验——一条通知，所有 LLM 尝鲜完成

**对标产品心理：**
- ChatGPT 的 "What's new" 通知（被动） → Bounce 的每周推送（主动）
- 模型聚合站但需要自己一个个试 → Bounce 自动帮你试，不好用就降级

### 隐含爽点：UPS 式安全感
"配置一次，永远不用担心下线"——这是用户愿意付费的底层的安心感。

---

## 四、商业价值

### 价值主张

| 角色 | 价值 |
|------|------|
| **开发者/工程师** | 不再被 LLM provider 碎片化困扰，一个 endpoint 搞定所有工具 |
| **AI 产品用户** | 工作流永不中断，包月用完了还有备用线路 |
| **本地部署用户** | 本地模型一键安装，离线也能用 |

### 收入模式（远期思路）

1. **Tier 3 尝鲜版 = 免费增值**：每周推送免费，吸引用户留存
2. **Premium Tier 管理**：企业用户需要定制 provider 链、监控、日志
3. **Pi/Bounce 捆绑**：Pi 是引流入口（agent 干活），Bounce 是留存基础设施（稳定后端）——"Pi 给你干活，Bounce 保证你永远能干上活"

### 为什么 Claude Code 来做开发？

X博士是产品定义者 + 战略架构师，Claude Code 是执行者。**术业有专攻**：
- X博士负责：用户需求、产品定位、架构决策
- Claude Code 负责：写代码、修 bug、重构、测试

---

## 五、当前状态（2026-05-29 诊断）

### 源码位置（WSL）

| 文件 | 用途 | 行数 |
|------|------|------|
| `~/.local/bin/bounce` | CLI 工具 | 564 行 |
| `~/.local/bin/bounce-gateway` | Gateway 服务（Flask） | 1025 行 |
| `~/.local/bin/bounce-panel` | Web 管理面板（Flask） | 451 行 |
| `~/.local/bin/bounce-gateway-start.sh` | 启动脚本 | 4 行 |
| `~/.bounce/config.json` | 主配置 | 183 行 |
| `~/.bounce/templates.json` | Provider 模板 | 132 行 |

### 当前架构（四层 failover，全部失效）

```
Hermes 主模型 → localhost:3001 (Bounce Gateway)
  ├── 🥇 Tier 1 deepseek-cp   → key='sk-bb7...0808'  ❌ 过期/无效（13字符，正确key 35+字符）
  ├── 🥈 Tier 2 deepseek-payg  → key NOT SET         ❌ 未配置
  ├── 🥉 Tier 3 硅基流动       → 未配置               ❌ 不存在
  ├── 4️⃣ Tier 4 qwen27b .81   → SSH 大文件阻断       ❌ 连不上
  └── 🛟 Tier 5 qwen35b CPU    → SOFT_MAX segfault    ❌ 已知 llama.cpp bug
                      ↓
             全部失败 → Demo 模式（静态回显）
```

### 已知 Bug

1. **gateway.pid 不写入**：`bounce gateway status` 永远显示"未运行"，因为 daemon fork 后子进程 PID 变了。实际 health endpoint 正常。
2. **Proxy 污染**：Clash 设置了 `HTTP_PROXY`/`HTTPS_PROXY`，Python requests 会自动走代理导致连不上云 API。已通过 `session.trust_env = False` 修复。
3. **Hermes fallback 循环**：Hermes config.yaml 的 fallback 指向 bounce-gateway，但 bounce-gateway 所有层都跪了 → 循环失败。当前 Hermes 通过自己的深层 fallback 直连 DeepSeek 才正常工作。
4. **35B SOFT_MAX bug**：Qwen3.6-35B-A3B MoE 在 L20 (sm_89) 上推理 segfault。旧版 llama.cpp 也有同样问题。需要等上游修复或用 CPU 模式（ngl=0）。
5. **火山方舟模板 API 地址错误**：模板中 `huoshan-cp` 的 `api_base` 写的是 `/api/v3`，但 Coding Plan 类型的 key（`ark-` 前缀）需要 `/api/plan/v3`。模板已更新但可能未同步。

---

## 六、新架构设计（需实现）

### 6.1 四层结构

```
用户选择区（setup 时一次配置）：
  Tier 1: 火山 Coding Plan / DeepSeek 包月   ← 用户选一个
  Tier 2: DeepSeek 按量 / 硅基流动按量       ← 用户选一个

自动更新区（X博士每周推送）：
  Tier 3: 每周尝鲜版 LLM                      ← 自动更新，用户零操作

全自动兜底（无需用户操作）：
  Tier 4: 本地小模型                          ← bounce install-local 默认执行
                                                  Qwen2.5-0.5B (~350MB, CPU可跑)
                                                  第一次启动时自动安装，不再询问用户

最后防线：
  🛟 通知用户："所有线路都挂了"
     不返回 Demo 模式——通知用户检查网络/Key
```

### 6.2 关键改动

#### 改动 1：install-local 默认执行

当前：首次启动弹交互提示 "Download & install local model? [Y/n]"
改为：**静默安装**。用户启动 Gateway 时，如果没有本地模型，自动下载安装。

- 下载进度条显示（不隐藏），但不需要用户确认
- 安装完成后提示用户
- 如果安装失败（网络问题等），跳过并提示用户手动执行 `bounce install-local`

#### 改动 2：Demo 模式改为通知模式

当前：所有 tier 失败后返回静态 Demo 回复（Hello from Bounce Gateway...）
改为：返回 503 错误，并在日志中通知用户。Gateway 可以发送通知（通过 WebSocket 或轮询）。

- `--no-demo` 选项保持，但要改名（例如 `--strict`）
- 默认行为改为不返回 demo 回复

#### 改动 3：Tier 3 自动更新机制

X 博士通过 cron 每周更新 `~/.bounce/tier3-weekly.json`，格式如下：

```json
{
  "week": "2026-W22",
  "publish_date": "2026-05-29",
  "models": [
    {
      "id": "deepseek-v4.1-flash",
      "name": "DeepSeek V4.1 Flash",
      "provider": "deepseek-cp",
      "why": "新版 MoE 架构，推理速度提升 30%",
      "url": "https://api.deepseek.com/v1",
      "added": true,
      "deprecated": ["deepseek-v3-flash"]
    }
  ]
}
```

Gateway 启动时自动加载此文件，将 Tier 3 的模型列表合并到 provider chain 中。

**不需要重启 Gateway 就能生效**——Gateway 每次请求都重新加载 config。

#### 改动 4：Pi 适配

Pi 的配置只有一行要改：

```json
// ~/.pi/agent/models.json
"baseUrl": "http://127.0.0.1:3001/v1"
```

Bounce 侧需要确保 Gateway 兼容 Pi 的请求格式：
- OpenAI 标准 `/v1/chat/completions` ✅ 已有
- 流式 SSE 支持 ✅ 已有
- 模型名 `deepseek-v4-flash` 等在 model_map 中覆盖 ✅ 已有

**不需要改 Bounce 代码**，但要在文档中写明 Pi 适配步骤。

### 6.3 配置示例（新结构）

```json
{
  "_version": "2.0.0",
  "_description": "Bounce Gateway — UPS-style AI provider router",
  "gateway": {
    "port": 3001,
    "enabled": true,
    "strict_mode": true,
    "notify_on_all_fail": true
  },
  "tiers": [
    {
      "id": "user_tier1",
      "name": "包月 Coding Plan",
      "type": "cloud",
      "api_base": "https://api.deepseek.com/v1",
      "api_key_env": "DEEPSEEK_CP_KEY",
      "models": ["deepseek-v4-flash", "deepseek-v4-pro"],
      "model_map": { ... },
      "timeout": 15
    },
    {
      "id": "user_tier2",
      "name": "按量付费",
      "type": "cloud",
      "api_base": "https://api.deepseek.com/v1",
      "api_key_env": "DEEPSEEK_PAYG_KEY",
      "models": ["deepseek-v4-flash", "deepseek-v4-pro"],
      "model_map": { ... },
      "timeout": 15
    },
    {
      "id": "weekly_fresh",
      "name": "每周尝鲜",
      "type": "cloud",
      "dynamic": true,
      "source": "~/.bounce/tier3-weekly.json",
      "timeout": 20
    },
    {
      "id": "local_fallback",
      "name": "本地小模型兜底",
      "type": "local",
      "api_base": "",
      "models": ["local-tiny"],
      "model_path": "~/.bounce/models/qwen2.5-0.5b-instruct-q4_k_m.gguf",
      "timeout": 60
    }
  ],
  "notify": {
    "on_all_fail": true,
    "method": "log"
  }
}
```

---

## 七、开发优先级

### P0（必须，否则产品不可用）

1. **修复 Key 问题**：让 Tier 1 deepseek-cp 使用正确有效的 key
2. **install-local 默认化**：改为静默安装，不询问用户
3. **Demo 模式改为通知模式**：所有 tier 失败时返回 503 并通知用户

### P1（核心体验）

4. **Tier 3 动态加载**：支持从 `tier3-weekly.json` 动态加载模型
5. **`bounce doctor` 增强**：能检测每个 tier 的实际可达性（测试请求）
6. **Pi 适配文档**：在 README 和 CLI help 中加入 Pi 集成说明

### P2（锦上添花）

7. **Gateway 状态通知**：当 failover 发生时（从 Tier 1 降到 Tier 2），通过某种方式通知用户
8. **Web 面板增强**：显示当前 failover 链状态、每层延迟、历史 failover 事件

---

## 八、代码规范

### 8.1 代码风格
- 保持 Python 3.10+ 兼容
- Flask + requests（现有技术栈，不改）
- 配置用 JSON（保持与现有 config.json 一致）
- 日志用 logging 模块（已配置）

### 8.2 测试要求
- 改完一个功能后，用 `curl` 测试 Gateway：
  ```bash
  curl -s --noproxy '*' -X POST http://localhost:3001/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"hi"}],"max_tokens":10}'
  ```
- 测试流式：加 `"stream": true`
- 测试 /v1/models 端点
- 测试 failover：临时改 key 为错误值，确认下一层接管

### 8.3 文件结构（保持现有）

```
~/.local/bin/
├── bounce              # CLI（不要大幅改动）
├── bounce-gateway      # Gateway（主要改动在此）
└── bounce-panel        # Web 面板（次要改动）

~/.bounce/
├── config.json         # 主配置
├── templates.json      # Provider 模板
├── models/             # 本地 GGUF 模型
└── tier3-weekly.json   # 【新增】每周尝鲜模型列表
```

---

## 九、启动 & 测试流程

```bash
# 1. 停止旧 Gateway
fuser -k 3001/tcp 2>/dev/null

# 2. 修改代码后，启动新 Gateway（直接前台运行看日志）
python3 ~/.local/bin/bounce-gateway --port 3001 --debug

# 3. 另一个终端测试
curl -s --noproxy '*' -X POST http://localhost:3001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"hi"}],"max_tokens":10}'

# 4. 确认响应头中的 X-Provider-Id
curl -sI --noproxy '*' http://localhost:3001/health

# 5. 验证模型列表
curl -s --noproxy '*' http://localhost:3001/v1/models | python3 -m json.tool
```

---

## 十、关键限制 & 注意事项

1. **不要改 CLI（bounce）的代码结构**——CLI 的逻辑比较简单，改动容易引入 bug。主要改 Gateway。
2. **不要动 Web Panel（bounce-panel）除非必要**——它是 Phase 2 的遗留，用户当前不通过它操作。
3. **Gateway 的 `_try_http()` 中的 `session.trust_env = False` 是修过的 proxy bug——不要删掉。**
4. **不要修改 templates.json 中的 provider 定义**——它们是产品文档的一部分，X 博士会维护。
5. **config.json 中的 `"gateway.enabled": false` 是遗留字段——不要依赖它。Gateway 启动时自动从 config.json 加载 provider。**
6. **所有改动要保留 `--no-demo` 选项**，但默认行为改为非 demo。

---

*文档版本：v1.0，2026-05-29*
*由 X 博士编写，供 Claude Code 开发参考*
