$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$Esc = [char]27

# Read stdin JSON for context window data
$CtxPct = $null
try {
    $raw = $input | Out-String
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $json = $raw | ConvertFrom-Json
        $CtxPct = $json.context_window.used_percentage
    }
} catch {}

# Read caveman mode flag
$Mode = $null
$Flag = Join-Path $ClaudeDir ".caveman-active"
if (Test-Path $Flag) {
    try {
        $Item = Get-Item -LiteralPath $Flag -Force -ErrorAction Stop
        if (-not ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -and $Item.Length -le 64) {
            $Raw = Get-Content -LiteralPath $Flag -TotalCount 1 -ErrorAction Stop
            if ($null -ne $Raw) {
                $m = ([string]$Raw).Trim().ToLowerInvariant() -replace '[^a-z0-9-]', ''
                $Valid = @('off','lite','full','ultra','wenyan-lite','wenyan','wenyan-full','wenyan-ultra','commit','review','compress')
                if ($Valid -contains $m) { $Mode = $m }
            }
        }
    } catch {}
}

$Parts = @()

# Caveman badge
if ($null -ne $Mode -and $Mode -ne 'off') {
    if ([string]::IsNullOrEmpty($Mode) -or $Mode -eq 'full') {
        $Parts += "${Esc}[38;5;172m[CAVEMAN]${Esc}[0m"
    } else {
        $Suffix = $Mode.ToUpperInvariant()
        $Parts += "${Esc}[38;5;172m[CAVEMAN:$Suffix]${Esc}[0m"
    }
}

# Context % badge
if ($null -ne $CtxPct) {
    $pct = [int][Math]::Round($CtxPct)
    # Color: green < 50, yellow < 80, red >= 80
    $color = if ($pct -ge 80) { "${Esc}[38;5;196m" } elseif ($pct -ge 50) { "${Esc}[38;5;226m" } else { "${Esc}[38;5;82m" }
    $Parts += "${color}[CTX:${pct}%]${Esc}[0m"
}

if ($Parts.Count -gt 0) {
    [Console]::Write($Parts -join " ")
}
