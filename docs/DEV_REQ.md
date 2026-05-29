# Bounce Gateway — P0 开发需求

## 背景

Bounce 是一个轻量 OpenAI 兼容的 failover 网关。当前问题：
- 配置分散（环境变量 + config.json + 硬编码）
- Provider 模板有但没人用
- 改配置没保护（写一半断电就挂了）
- 改前没备份

**学 CC Switch 四项**（其他不碰）：
1. SSOT 配置管理
2. Provider 预设
3. 原子写入+回滚
6. 备份机制

**保留核心不变**：透明代理、自动 failover、零配置变更。

---

## 任务 1：SSOT 配置管理

**当前**：API key 散落在 `env:` 引用、`api_key_env` 字段、环境变量里，`resolve_api_key()` 有 4 种查找方式太绕。

**目标**：所有配置存 `~/.bounce/config.json`，无环境变量依赖。

### 要求

1. **config.json 是唯一真相源**。删掉 `resolve_api_key()` 里的 env 回退链（第 95-110 行附近），只留：
   - `provider.api_key` 直接取值
   - 没有值就报错：`"provider {id} has no api_key"`
2. **不再读环境变量**。用户加 Provider 时 key 直接写入 config.json。
3. **config.json 加 `_schema_version` 字段**，从 `1.0.0` 开始，以后改 schema 靠版本号迁移。
4. **删除 `templates.json` 的引用路径** — 把它合并到 gateway 启动时的内部逻辑里，不依赖外部文件。或者说保留 templates.json 但作为"参考"，config.json 里的 provider 是自包含的。

**验收**：
- `bounce-gateway` 启动时不读任何环境变量
- 所有 provider 配置在 config.json 里完整可读
- 删掉 `resolve_api_key()` 中的 `env:` 前缀逻辑

---

## 任务 2：Provider 预设

**当前**：templates.json 存了一套模板（deepseek-cp、huoshan-cp、siliconflow-payg 等），但没人通过模板添加。用户手动在 config.json 里写 provider 配置。

**目标**：`bounce provider add <template> --key <key>` 一键添加，模板自带所有字段。

### 要求

1. **`bounce provider templates`** — 列出所有可用模板，按 tier 分组显示
2. **`bounce provider add <template-id> --key <key>`** — 从模板创建 provider 写入 config.json
   - 模板字段全量复制到新 provider（api_base、models、timeout、error_map 等）
   - 写入 key
   - 如果同名 provider 已存在 → 报错提示 `"provider {id} already exists, use 'bounce provider update' instead"`
3. **`bounce provider list`** — 列出当前已配置的 providers
4. **`bounce provider remove <id>`** — 删除 provider
5. **模板数据硬编码在脚本里**（或保留 templates.json 但作为参考副本），不依赖外部文件启动。

**验收**：
```bash
bounce provider templates                    # 显示模板列表
bounce provider add deepseek-cp --key sk-xxx # 添加成功
bounce provider add deepseek-cp --key sk-yyy # 报错：已存在
bounce provider list                         # 显示刚加的
bounce provider remove deepseek-cp           # 删除
```

---

## 任务 3：原子写入+回滚

**当前**：所有 config.json 写操作都是直接 `json.dump()`，写一半程序崩溃 → 文件损坏。

**目标**：所有 config 写操作走原子写入 + 失败自动回滚。

### 要求

1. **写一个新函数 `atomic_write(path, data)`**：
   - 先写 `.tmp` 文件（同目录）
   - `os.fsync()` 确保落盘
   - `os.rename()` 覆盖原文件（原子操作）
   - 写 tmp 失败 → 不删原文件，报错
2. **所有 config.json 写入点都换成 `atomic_write()`**
3. **Provider 切换时**：
   - 读旧配置存内存
   - 写新配置（atomic_write）
   - 如果写失败 → 用旧配置重写恢复
4. **不要 Tauri 那种复杂的回滚机制**。简单够用就行：写前备份一份到 `~/.bounce/backups/`（见任务 6），写入失败就打印错误。

**验收**：
- 脚本里搜索 `json.dump` 和 `open(config_path, 'w')` 都换成 `atomic_write()`
- `bounce provider add` 时模拟写入中断 → config.json 不损坏

---

## 任务 4：备份机制（其实是第 6 项）

**当前**：改配置前没有任何备份。

**目标**：每次修改 config.json 前自动备份。

### 要求

1. **每次写入 config.json 前**，自动复制当前文件到 `~/.bounce/backups/`
2. **备份文件名格式**：`config.{YYYYMMDD_HHmmss}.json`
3. **保留最近 10 份备份**，超出的自动清理（删最旧的）
4. **`bounce backup list`** — 列出所有备份文件
5. **`bounce backup restore <文件名>`** — 恢复指定备份

**验收**：
```bash
ls ~/.bounce/backups/    # 有备份文件
bounce backup list       # 显示列表
bounce backup restore config.20260530_120000.json  # 恢复
```

---

## 优先级与边界

### P0（本次必须完成）
- 上述四个任务全部

### 不做的（减法）
- ❌ 桌面应用 / Tauri
- ❌ MCP 管理
- ❌ Skills/Prompts
- ❌ 托盘菜单
- ❌ 使用量跟踪
- ❌ 国际化
- ❌ Web 面板
- ❌ 改 gateway 核心 failover 逻辑
- ❌ 改 API 代理转发逻辑

### 约束
- 只改 `src/bounce`（CLI 入口）和 `src/bounce-gateway`（gateway）
- 不改 Python 依赖（只用 flask + requests + json 标准库）
- 不改 gateway 的 `/v1/chat/completions` 核心路由
- 所有新功能加在 CLI 侧，gateway 只改 config 加载部分

---

## Phase 2：多工具适配

**问题**：当前 Bounce 只服务 Continue 一个工具（且只是只读检测）。Claude Code、Codex CLI、TRAE、Pi 没有统一接入。

**目标**：一个 `bounce use` 命令自动配置所有已安装的 AI 工具指向 `localhost:3001/v1`。

### 工具适配评估

| 工具 | 协议 | 适配方式 | 工作量 |
|---|---|---|---|
| **Codex CLI** | OpenAI Chat | env 变量注入 | 小 |
| **VS Code Continue** | OpenAI Chat | 自动写 `~/.continue/config.json` | 小 |
| **TRAE** | OpenAI Chat（推测） | 检测+写入 `~/.trae/` | 中（需先确认路径） |
| **Claude Code** | Anthropic Messages | 新增 `/v1/messages` 翻译端点 | 中 |
| **Pi** | OpenAI Chat | 天然兼容，零改动 | 0 |

### 任务 5：Codex CLI 支持

**当前**：`bounce doctor` 不检测 Codex，`bounce use` 不输出 Codex env。

**目标**：`bounce use` 输出完整的 Codex 环境变量命令。

**要求**：
1. config.json 的 `tools` 节加 `codex` 条目：
   ```json
   "codex": {
     "type": "env_var",
     "env_map": {
       "CODEX_API_BASE": "api_base",
       "CODEX_API_KEY": "api_key",
       "CODEX_MODEL": "models.default"
     }
   }
   ```
2. `bounce doctor` 检测 Codex CLI 是否安装（`which codex`）
3. `bounce use <id>` 输出 Windows 和 WSL 的 Codex env 命令
4. `bounce env` 显示 Codex 相关变量

**验收**：
```bash
bounce use deepseek-v4-flash
# 输出应包含:
#   ⚡ Codex CLI:
#      set CODEX_API_BASE=http://localhost:3001/v1
#      set CODEX_API_KEY=sk-xxx
```

### 任务 6：VS Code Continue 自动写配置

**当前**：`update_continue_config()` 只读不写。

**目标**：`bounce use` 时自动更新 Continue 配置指向 Bounce Gateway。

**要求**：
1. `bounce use <id>` 时自动写 `C:\Users\jingc\.continue\config.json`：
   - 修改 models 列表，加入 Bounce Gateway 条目
   - apiBase: `http://localhost:3001/v1`
   - model: 由当前 provider 的 `model_map` 决定
2. 保留用户已有的非 Bounce 模型
3. 如果 Continue 配置不存在 → 报错提示路径

**验收**：
```bash
bounce use deepseek-cp
# Continue 配置自动更新，打开 VS Code → Continue → 自动走 Bounce
```

### 任务 7：TRAE 适配

**当前**：不支持。

**目标**：`bounce doctor` 检测 TRAE 配置，`bounce use` 自动配置。

**要求**：
1. 先 `bounce doctor` 扫描可能的 TRAE 配置路径：
   - `C:\Users\jingc\.trae\` 下找 config.json
   - `~/.trae/`（WSL 侧）
   - 其他常见位置
2. 确认路径后，写入方式参考 Continue（OpenAI Chat 格式）
3. 路径不确定时提示用户手动指定

**验收**：
```bash
bounce doctor
# 输出: ✅ TRAE: C:\Users\jingc\.trae\config.json (已检测)
# 或    ❌ TRAE: 未找到，请提供配置路径
```

### 任务 8：Claude Code Anthropic 端点翻译

**当前**：Claude Code 绕过 Bounce，直接连 DeepSeek Anthropic 端点。

**目标**：Bounce Gateway 加 `/v1/messages` 端点，翻译 Anthropic ↔ OpenAI 格式。

**要求**：
1. **新增端点 `POST /v1/messages`**：
   - 接收 Anthropic Messages API 格式
   - 翻译成 OpenAI Chat Completions 格式
   - 走现有的 FailoverEngine（享受 failover 链）
   - 把响应翻译回 Anthropic 格式
2. **关键翻译映射**：

   | Anthropic | OpenAI |
   |---|---|
   | `model` | `model`（保持原样） |
   | `messages` | `messages`（基本一致） |
   | `max_tokens` | `max_tokens` |
   | `system`（顶层字段） | `messages[0]` role=system |
   | `stream: true` | `stream: true` |
   | `anthropic_version` | 忽略 |
   | 响应 `content[0].text` | 响应 `choices[0].message.content` |
3. **model_map 自动路由**：Claude Code 请求 `claude-sonnet-4-20250514` → model_map 转 `deepseek-v4-flash`
4. **响应格式**：返回 Anthropic Messages API 格式，包含 `content`、`stop_reason`、`usage` 等字段
5. **Stream 支持**：SSE 流式返回 Anthropic 格式的事件
6. **修改 `bounce use`**：输出 Claude Code 的 env 命令指向 `http://localhost:3001`：
   ```bash
   set ANTHROPIC_BASE_URL=http://localhost:3001
   set ANTHROPIC_AUTH_TOKEN=sk-bounce
   ```

**不做的**：
- 不实现 Anthropic 的 tool_use / function calling（太复杂，DeepSeek 也不支持）
- 不处理图片/多模态输入
- 不处理 `anthropic-beta` header

**验收**：
```bash
# 1. Bounce 启动
bounce gateway start

# 2. Claude Code 配置
set ANTHROPIC_BASE_URL=http://localhost:3001
set ANTHROPIC_AUTH_TOKEN=sk-bounce
claude

# 3. Claude Code 的请求走 Bounce failover 链
#    Tier1 deepseek-cp → Tier2 deepseek-payg → Tier3 本地模型
```
