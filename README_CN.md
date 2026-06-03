# cc-flux

数据驱动、会话隔离的 [Claude Code](https://claude.ai/code) 多 API 切换器。  
一条命令在官方 Pro 订阅和任意第三方/兼容 API（DeepSeek、Mimo 等）之间自由切换 — **不改配置文件，不污染系统**。

## 原理

`$ClaudeEnvConfigs` 是唯一的配置来源，一个 HashTable 搞定一切。每个条目把短别名（如 `"ds"`、`"mimo"`）映射到一组环境变量。官方订阅条目的 key 是 `"sub"`，所有值都是 `$null`，意味着"使用官方 Claude Pro 订阅，不做任何覆盖"。它会自动生成为 `claudesub`，而原生 `claude` 命令被覆写为直接劫持到 `claudesub`，两者执行的都是这套全量清理的逻辑。

加载脚本时，`foreach` 遍历这个 HashTable，为每个 key 动态生成对应的 `claude<key>` 函数。每个函数执行完全相同的三步流水线：

1. **Clear-ClaudeEnv** — 大清洗：移除当前会话中所有 Claude 相关环境变量，确保上一条命令的残留不会泄露到下一次调用。
2. **Set-ClaudeEnv** — 注入目标 API 的配置（Base URL、Auth Token、模型映射等）。
3. **claude.exe** — 启动真正的 Claude Code 程序，它此时看到的只有目标 API 的环境变量。

最终效果：敲 `claudeds` 获得 DeepSeek 驱动的 Claude Code 会话，敲 `claudemimo` 切换到小米 API，敲 `claude`（或 `claudesub`）走官方 Pro。不同终端窗口可以同时跑不同 API，完全隔离。

### 三个设计支柱

1. **`$env:` 会话隔离** — 所有变量仅存在于当前 PowerShell 终端进程的内存中。关闭窗口即彻底消失。不写注册表，不碰系统环境变量，不落盘。

2. **数据驱动，拒绝硬编码** — `$ClaudeEnvConfigs` 是唯一需要编辑的地方。所有 `claude<key>` 函数均由它自动生成。接入新 API 后端只需在 HashTable 里加一个条目——无需写函数定义，无需复制粘贴，零样板代码。

3. **全量清理，杜绝残留** — 原生 `claude` 命令被覆写为劫持到 `claudesub`，每次调用都从完整的环境清理开始。同一终端窗口内反复切换后端，绝不会有旧变量残留，不存在意外混用配置的可能。

## 快速开始

### 1. 前置准备

请确保你的系统已创建 PowerShell Profile。如果没有，请先在终端执行以下命令创建：

```powershell
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
```

### 2. 安装

在 `$PROFILE` 中添加一行（路径替换为你实际存放 `cc-flux.ps1` 的位置）：

```powershell
# 这里的路径请替换为你实际存放 cc-flux.ps1 的绝对路径
. "D:\Scripts\cc-flux.ps1"
```

或者直接在 PowerShell 中执行这一条命令（注意替换路径）：

```powershell
Add-Content -Path $PROFILE -Value '. "D:\Scripts\cc-flux.ps1"'
```

### 3. 打开新终端

```
cc-flux loaded. Available: claude, claudeds, claudemimo
```

### 4. 使用

```powershell
claude         # 官方 Pro 订阅
claudeds       # DeepSeek API
claudemimo     # Mimo / 小米 API
```

不同终端窗口可以同时跑不同 API，互不干扰。

## 如何新增 API

编辑 `cc-flux.ps1`，在 `$ClaudeEnvConfigs` 字典里加一项：

```powershell
$ClaudeEnvConfigs = @{
    # ... 已有配置 ...

    # 例子：新增智谱 GLM
    "glm" = @{
        "ANTHROPIC_BASE_URL"              = "https://open.bigmodel.cn/api/paas/v4/anthropic"
        "ANTHROPIC_AUTH_TOKEN"            = "你的API-Key"
        "ANTHROPIC_MODEL"                 = "glm-4-plus"
        "ANTHROPIC_DEFAULT_OPUS_MODEL"    = "glm-4-plus"
        "ANTHROPIC_DEFAULT_SONNET_MODEL"  = "glm-4-flash"
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"   = "glm-4-flash"
        "CLAUDE_CODE_SUBAGENT_MODEL"      = "glm-4-flash"
        "CLAUDE_CODE_EFFORT_LEVEL"        = "max"
    }
}
```

就这些。重新加载 `. $PROFILE`，`claudeglm` 即刻可用。

## 环境变量说明

- **`ANTHROPIC_BASE_URL`** — API 端点地址（第三方必填，官方不设）
- **`ANTHROPIC_AUTH_TOKEN`** — API 密钥 / Token
- **`ANTHROPIC_MODEL`** — 默认模型（所有档位）
- **`ANTHROPIC_DEFAULT_OPUS_MODEL`** — Opus 档位使用的模型
- **`ANTHROPIC_DEFAULT_SONNET_MODEL`** — Sonnet 档位使用的模型
- **`ANTHROPIC_DEFAULT_HAIKU_MODEL`** — Haiku 档位使用的模型
- **`CLAUDE_CODE_SUBAGENT_MODEL`** — 子 Agent 使用的模型
- **`CLAUDE_CODE_EFFORT_LEVEL`** — 执行力度（如 `max`）

设为 `$null` 表示不注入该变量，由 Claude Code 使用内置默认值。

## 文件结构

```
cc-flux/
  .claude/
    └── settings.json    ← Claude Code 项目配置
  ├── cc-flux.ps1        ← 核心脚本（在 $PROFILE 中 dot-source 加载）
  ├── README.md          ← 英文说明
  └── README_CN.md       ← 本文件（中文说明）
```

## 许可证

MIT — 随意使用。欢迎提 PR 添加有趣的 API 后端。
