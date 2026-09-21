# Links the hand-authored Claude Code and Codex config from this repo into
# ~/.claude and ~/.codex. Tool-generated state (credentials, sessions, caches,
# synced skills, marketplace plugins) is left alone.

$ErrorActionPreference = "Stop"

$dotfilesDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$sharedAi = Join-Path $dotfilesDir "shared\ai"
$pcAi = Join-Path $dotfilesDir "pc\ai"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function New-ConfigLink([string]$source, [string]$target) {
    if (!(Test-Path $source)) {
        Write-Host "  Skipping $target (missing $source)" -ForegroundColor Yellow
        return
    }

    $parent = Split-Path $target -Parent
    if (!(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq "SymbolicLink") {
            Remove-Item -LiteralPath $target -Force -Recurse
        } else {
            # Never delete real config blind. Move it aside so it can be recovered.
            $backup = "$target.bak-$stamp"
            Move-Item -LiteralPath $target -Destination $backup -Force
            Write-Host "  Backed up existing $target -> $backup" -ForegroundColor Yellow
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
    } catch {
        Write-Host "  Symlink failed for $target" -ForegroundColor Red
        Write-Host "  Turn on Windows Developer Mode, or run this script elevated." -ForegroundColor Red
        throw
    }
    Write-Host "  Linked $target" -ForegroundColor Gray
}

Write-Host "Linking AI config (Claude Code, Codex)..." -ForegroundColor Green

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$codexDir = Join-Path $env:USERPROFILE ".codex"

$links = [ordered]@{
    (Join-Path $sharedAi "claude\CLAUDE.md")             = (Join-Path $claudeDir "CLAUDE.md")
    (Join-Path $sharedAi "claude\settings.json")         = (Join-Path $claudeDir "settings.json")
    (Join-Path $sharedAi "claude\keybindings.json")      = (Join-Path $claudeDir "keybindings.json")
    (Join-Path $sharedAi "claude\commands\i18n-extract.md") = (Join-Path $claudeDir "commands\i18n-extract.md")
    (Join-Path $sharedAi "claude\skills\release-docs")   = (Join-Path $claudeDir "skills\release-docs")
    (Join-Path $pcAi "claude\hooks\statusline.ps1")      = (Join-Path $claudeDir "hooks\statusline.ps1")
    (Join-Path $sharedAi "codex\AGENTS.md")              = (Join-Path $codexDir "AGENTS.md")
    (Join-Path $sharedAi "codex\config.toml")            = (Join-Path $codexDir "config.toml")
    (Join-Path $sharedAi "codex\rules\default.rules")    = (Join-Path $codexDir "rules\default.rules")
    (Join-Path $sharedAi "codex\skills\artisan-mode")    = (Join-Path $codexDir "skills\artisan-mode")
}

foreach ($source in $links.Keys) {
    New-ConfigLink $source $links[$source]
}

Write-Host "AI config linked." -ForegroundColor Green
Write-Host "Machine-specific overrides go in ~/.claude/settings.local.json (never synced)." -ForegroundColor Yellow
