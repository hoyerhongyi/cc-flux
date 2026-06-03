# ============================================================
# cc-flux - Data-Driven, Session-Isolated
# ============================================================
# Add new APIs by adding entries to $ClaudeEnvConfigs below.
# A function "claude<key>" (e.g. claudeds) is auto-generated.
# ============================================================

# ---- API Configuration Dictionary ----
$ClaudeEnvConfigs = @{

    # Official Claude Pro (default - all env vars cleared)
    "pro" = @{
        "ANTHROPIC_BASE_URL"              = $null
        "ANTHROPIC_AUTH_TOKEN"            = $null
        "ANTHROPIC_MODEL"                 = $null
        "ANTHROPIC_DEFAULT_OPUS_MODEL"    = $null
        "ANTHROPIC_DEFAULT_SONNET_MODEL"  = $null
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"   = $null
        "CLAUDE_CODE_SUBAGENT_MODEL"      = $null
        "CLAUDE_CODE_EFFORT_LEVEL"        = $null
    }

    # DeepSeek
    "ds" = @{
        "ANTHROPIC_BASE_URL"              = "https://api.deepseek.com/anthropic"
        "ANTHROPIC_AUTH_TOKEN"            = "<你的 DeepSeek API Key>"
        "ANTHROPIC_MODEL"                 = "deepseek-v4-pro[1m]"
        "ANTHROPIC_DEFAULT_OPUS_MODEL"    = "deepseek-v4-pro[1m]"
        "ANTHROPIC_DEFAULT_SONNET_MODEL"  = "deepseek-v4-pro[1m]"
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"   = "deepseek-v4-flash"
        "CLAUDE_CODE_SUBAGENT_MODEL"      = "deepseek-v4-flash"
        "CLAUDE_CODE_EFFORT_LEVEL"        = "max"
    }

    # Mimo / Xiaomi
    "mimo" = @{
        "ANTHROPIC_BASE_URL"              = "https://token-plan-cn.xiaomimimo.com/anthropic"
        "ANTHROPIC_AUTH_TOKEN"            = "<你的 Mimo tokenplan API Key>"
        "ANTHROPIC_MODEL"                 = "mimo-v2.5-pro[1m]"
        "ANTHROPIC_DEFAULT_OPUS_MODEL"    = "mimo-v2.5-pro[1m]"
        "ANTHROPIC_DEFAULT_SONNET_MODEL"  = "mimo-v2.5[1m]"
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"   = "mimo-v2.5-pro[1m]"
        "CLAUDE_CODE_SUBAGENT_MODEL"      = "mimo-v2.5-pro[1m]"
        "CLAUDE_CODE_EFFORT_LEVEL"        = "max"
    }
}
    
# ---- Collect all known env var names (for cleanup) ----
$ClaudeEnvVarNames = @()
foreach ($cfg in $ClaudeEnvConfigs.Values) {
    $ClaudeEnvVarNames += $cfg.Keys
}
$ClaudeEnvVarNames = $ClaudeEnvVarNames | Select-Object -Unique

# ---- Real Claude executable ----
$ClaudeRealExe = "$env:LOCALAPPDATA\bin\claude.exe"
if (-not (Test-Path $ClaudeRealExe)) {
    $ClaudeRealExe = (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue).Source
}

# ---- Helper: wipe ALL Claude-related env vars from this session ----
function global:Clear-ClaudeEnv {
    foreach ($varName in $ClaudeEnvVarNames) {
        if (Test-Path "env:$varName") {
            Remove-Item "env:$varName" -ErrorAction SilentlyContinue
        }
    }
}

# ---- Helper: inject a config's env vars ----
function global:Set-ClaudeEnv {
    param([hashtable]$Config)
    foreach ($key in $Config.Keys) {
        if ($null -ne $Config[$key]) {
            Set-Item "env:$key" -Value $Config[$key]
        }
    }
}

# ---- Dynamic function generation ----
# Creates: claudeds, claudemimo, claudepro, ...
foreach ($shortName in $ClaudeEnvConfigs.Keys) {
    $funcName = "claude$shortName"
    $displayName = $shortName.ToUpper()

    $sb = [scriptblock]::Create(@"
        Clear-ClaudeEnv
        Write-Host ">>> Claude [$displayName] - injecting env vars..." -ForegroundColor Cyan
        Set-ClaudeEnv `$ClaudeEnvConfigs['$shortName']
        & `$ClaudeRealExe @args
"@)
    Set-Item -Path "function:\global:$funcName" -Value $sb
}

# ---- Override native 'claude' - clean first, then run ----
function global:claude {
    Clear-ClaudeEnv
    Write-Host ">>> Claude [PRO] - running with official subscription" -ForegroundColor Green
    & $ClaudeRealExe @args
}

Write-Host "cc-flux loaded. Available: $(($ClaudeEnvConfigs.Keys | ForEach-Object { "claude$_" }) -join ', ')" -ForegroundColor Magenta
