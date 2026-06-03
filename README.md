# cc-flux

A data-driven, session-isolated multi-API switcher for [Claude Code](https://claude.ai/code).  
Switch between the official Claude Pro subscription and any third-party/compatible API (DeepSeek, Mimo, etc.) with a single command — **no config files touched, no system pollution**.

## How It Works

`$ClaudeEnvConfigs` is a single HashTable that serves as the single source of truth. Each entry maps a short alias (like `"ds"` or `"mimo"`) to a set of environment variables. The official subscription entry uses a space `" "` as its key, with all values set to `$null` — meaning "use the official Claude Pro subscription with no overrides." The native `claude` command itself is overridden to run with this clean-slate behavior.

From this one HashTable, all `claude<key>` functions are auto-generated at load time. Each generated function follows the same three-step pipeline when you invoke it:

1. **Clear-ClaudeEnv** — wipe every Claude-related environment variable from the current session, so no residual state leaks across switches.
2. **Set-ClaudeEnv** — inject the target API's variables (base URL, auth token, model overrides, etc.) into the session.
3. **claude.exe** — launch the real Claude Code binary, which now sees only the intended configuration.

The result: typing `claudeds` gives you a Claude Code session backed by DeepSeek. Typing `claudemimo` switches to Mimo. typing `claude` uses your official Pro subscription. Different terminal windows can run different APIs simultaneously with zero interference.

### Three design pillars

1. **Session isolation via `$env:`** — all variables live strictly in the current PowerShell session's memory. Close the terminal window and they vanish. Nothing touches the Windows registry, system environment variables, or any config file on disk.

2. **Data-driven, no hardcoding** — `$ClaudeEnvConfigs` is the only place you need to edit. Every `claude<key>` function is generated from it automatically. Adding support for a new API backend means adding one entry to the HashTable — no function definitions, no copy-paste, no boilerplate.

3. **Clean-slate enforcement** — the native `claude` command is overridden so that every invocation begins with a full environment cleanup. This guarantees that switching between backends — even in the same terminal window — never leaves stale variables behind. There is no way to accidentally mix configurations.

## Quick Start

### 1. Prerequisites

Make sure your system has a PowerShell Profile. If not, create one first:

```powershell
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
```

### 2. Install

Add this line to your `$PROFILE` (replace the path with where you actually put `cc-flux.ps1`):

```powershell
# Replace with the actual absolute path to cc-flux.ps1
. "D:\Scripts\cc-flux.ps1"
```

Or run this one-liner in PowerShell (adjust the path):

```powershell
Add-Content -Path $PROFILE -Value '. "D:\Scripts\cc-flux.ps1"'
```

### 3. Open a new terminal

```
cc-flux loaded. Available: claude, claudeds, claudemimo
```

### 4. Use it

```powershell
claude         # Official Pro subscription
claudeds       # DeepSeek API
claudemimo     # Mimo / Xiaomi API
```

Different terminal windows can run different APIs simultaneously — they don't interfere.

## Add a New API

Edit `cc-flux.ps1` and add one entry to `$ClaudeEnvConfigs`:

```powershell
$ClaudeEnvConfigs = @{
    # ... existing entries ...

    # Add your new API here — just a few lines!
    "glm" = @{
        "ANTHROPIC_BASE_URL"              = "https://open.bigmodel.cn/api/paas/v4/anthropic"
        "ANTHROPIC_AUTH_TOKEN"            = "your-api-key-here"
        "ANTHROPIC_MODEL"                 = "glm-4-plus"
        "ANTHROPIC_DEFAULT_OPUS_MODEL"    = "glm-4-plus"
        "ANTHROPIC_DEFAULT_SONNET_MODEL"  = "glm-4-flash"
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"   = "glm-4-flash"
        "CLAUDE_CODE_SUBAGENT_MODEL"      = "glm-4-flash"
        "CLAUDE_CODE_EFFORT_LEVEL"        = "max"
    }
}
```

That's it. Reload (`$PROFILE`) and `claudeglm` is ready.

## Environment Variables Reference

- **`ANTHROPIC_BASE_URL`** — API endpoint (set for third-party, unset for official)
- **`ANTHROPIC_AUTH_TOKEN`** — API key / token
- **`ANTHROPIC_MODEL`** — Default model for all tiers
- **`ANTHROPIC_DEFAULT_OPUS_MODEL`** — Model override for Opus tier
- **`ANTHROPIC_DEFAULT_SONNET_MODEL`** — Model override for Sonnet tier
- **`ANTHROPIC_DEFAULT_HAIKU_MODEL`** — Model override for Haiku tier
- **`CLAUDE_CODE_SUBAGENT_MODEL`** — Model used by subagents
- **`CLAUDE_CODE_EFFORT_LEVEL`** — Effort level (e.g. `max`)

Set any value to `$null` to leave it at Claude Code's built-in default.

## File Structure

```
cc-flux/
  .claude/
    └── settings.json    ← Claude Code project config
  ├── cc-flux.ps1        ← The script (dot-source from $PROFILE)
  ├── README.md          ← This file (English)
  └── README_CN.md       ← Chinese version
```

## License

MIT — do whatever you want. PRs welcome if you add interesting API backends.
