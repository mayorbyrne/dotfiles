# Links the hand-authored Claude Code, Codex, and Cursor config from this repo
# into ~/.claude, ~/.codex, and ~/.cursor. Tool-generated state (credentials,
# sessions, caches, synced skills, marketplace plugins) is left alone.
# Work-specific settings live outside the repo in ~/.config/dotfiles/ and are
# merged into ~/.claude/settings.json and ~/.codex/config.toml.

$ErrorActionPreference = "Stop"

$dotfilesDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$sharedAi = Join-Path $dotfilesDir "shared\ai"
$pcAi = Join-Path $dotfilesDir "pc\ai"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Never delete real config blind. Move it aside so it can be recovered.
function Clear-ConfigTarget([string]$target) {
    $parent = Split-Path $target -Parent
    if (!(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    if (!$existing) {
        return
    }
    if ($existing.LinkType -eq "SymbolicLink") {
        # Delete() drops only the link. Remove-Item -Recurse on a directory link can empty its target.
        $existing.Delete()
    } else {
        $backup = "$target.bak-$stamp"
        Move-Item -LiteralPath $target -Destination $backup -Force
        Write-Host "  Backed up existing $target -> $backup" -ForegroundColor Yellow
    }
}

function New-ConfigLink([string]$source, [string]$target) {
    if (!(Test-Path $source)) {
        Write-Host "  Skipping $target (missing $source)" -ForegroundColor Yellow
        return
    }

    Clear-ConfigTarget $target

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
    } catch {
        Write-Host "  Symlink failed for $target" -ForegroundColor Red
        Write-Host "  Turn on Windows Developer Mode, or run this script elevated." -ForegroundColor Red
        throw
    }
    Write-Host "  Linked $target" -ForegroundColor Gray
}

# Written without a BOM, which Windows PowerShell's utf8 encoding would add.
function Write-Utf8File([string]$path, [string]$content) {
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))
}

function Merge-JsonObject($base, $overlay) {
    foreach ($prop in $overlay.PSObject.Properties) {
        $existing = $base.PSObject.Properties[$prop.Name]
        if ($existing -and $existing.Value -is [pscustomobject] -and $prop.Value -is [pscustomobject]) {
            Merge-JsonObject $existing.Value $prop.Value
        } else {
            $base | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
        }
    }
}

function Request-ClaudeOverlay {
    if (Test-Path $claudeOverlay) {
        return
    }

    $answer = Read-Host "Add a work plugin marketplace to Claude Code? (y/N)"
    if ($answer -notmatch '^[yY]') {
        return
    }

    $name = Read-Host "  Marketplace name"
    $url = Read-Host "  Marketplace git URL"
    $plugins = Read-Host "  Plugins to enable (comma-separated, without @$name)"
    if (!$name -or !$url) {
        Write-Host "  Name and URL are required. Skipping overlay." -ForegroundColor Yellow
        return
    }

    $enabled = [ordered]@{}
    foreach ($plugin in ($plugins -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $enabled["$plugin@$name"] = $true
    }
    $overlay = [ordered]@{
        extraKnownMarketplaces = @{ $name = @{ source = @{ source = "git"; url = $url } } }
        enabledPlugins = $enabled
    }

    New-Item -ItemType Directory -Path $overlayDir -Force | Out-Null
    Write-Utf8File $claudeOverlay ($overlay | ConvertTo-Json -Depth 10)
    Write-Host "  Wrote $claudeOverlay" -ForegroundColor Gray
}

function Request-WorkScope {
    if (Test-Path $workEnv) {
        return
    }

    $scope = Read-Host "Work npm scope to replace @work in AGENTS.md (e.g. @acme, blank to skip)"
    if (!$scope) {
        return
    }

    New-Item -ItemType Directory -Path $overlayDir -Force | Out-Null
    Write-Utf8File $workEnv "WORK_NPM_SCOPE=$scope`n"
    Write-Host "  Wrote $workEnv" -ForegroundColor Gray
}

function Read-WorkScope {
    if (!(Test-Path $workEnv)) {
        return ""
    }
    $line = Get-Content -LiteralPath $workEnv | Where-Object { $_ -match '^WORK_NPM_SCOPE=' } | Select-Object -Last 1
    if (!$line) {
        return ""
    }
    return $line.Substring("WORK_NPM_SCOPE=".Length)
}

# Writes generated content into place, skipping the backup when nothing changed.
function Install-GeneratedFile([string]$target, [string]$content) {
    $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -ne "SymbolicLink" -and (Get-Content -LiteralPath $target -Raw) -eq $content) {
        Write-Host "  $target is up to date" -ForegroundColor Gray
        return
    }

    Clear-ConfigTarget $target
    Write-Utf8File $target $content
    Write-Host "  Wrote $target" -ForegroundColor Gray
}

# Without a work scope the file stays a live symlink.
function Install-Agents([string]$target) {
    $source = Join-Path $sharedAi "AGENTS.md"
    if (!$workScope) {
        New-ConfigLink $source $target
        return
    }

    $content = (Get-Content -LiteralPath $source -Raw).Replace("@work/", "$workScope/")
    Install-GeneratedFile $target $content
}

function Write-ClaudeSettings {
    $base = Join-Path $sharedAi "claude\settings.json"
    $target = Join-Path $claudeDir "settings.json"

    $settings = Get-Content -LiteralPath $base -Raw | ConvertFrom-Json
    if (Test-Path $claudeOverlay) {
        Merge-JsonObject $settings (Get-Content -LiteralPath $claudeOverlay -Raw | ConvertFrom-Json)
    }
    Install-GeneratedFile $target ($settings | ConvertTo-Json -Depth 100)
}

# Codex rewrites config.toml itself (trust entries, UI state), so it is seeded
# once and then left alone.
function Initialize-CodexConfig {
    $base = Join-Path $sharedAi "codex\config.toml"
    $target = Join-Path $codexDir "config.toml"

    $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -ne "SymbolicLink") {
        Write-Host "  Kept existing $target" -ForegroundColor Gray
        return
    }

    Clear-ConfigTarget $target
    $content = Get-Content -LiteralPath $base -Raw
    # The overlay goes last, so it must hold only [tables], no top-level keys.
    if (Test-Path $codexOverlay) {
        $content = $content + "`n" + (Get-Content -LiteralPath $codexOverlay -Raw)
    }
    Write-Utf8File $target $content
    Write-Host "  Seeded $target" -ForegroundColor Gray
}

Write-Host "Linking AI config (Claude Code, Codex, Cursor)..." -ForegroundColor Green

$claudeDir = Join-Path $env:USERPROFILE ".claude"
$codexDir = Join-Path $env:USERPROFILE ".codex"
$cursorDir = Join-Path $env:USERPROFILE ".cursor"
$overlayDir = Join-Path $env:USERPROFILE ".config\dotfiles"
$claudeOverlay = Join-Path $overlayDir "claude.work.json"
$codexOverlay = Join-Path $overlayDir "codex.work.toml"
$workEnv = Join-Path $overlayDir "work.env"

Request-ClaudeOverlay
Request-WorkScope
$workScope = Read-WorkScope

Write-ClaudeSettings
Initialize-CodexConfig

foreach ($target in @(
    (Join-Path $claudeDir "CLAUDE.md"),
    (Join-Path $codexDir "AGENTS.md"),
    (Join-Path $cursorDir "AGENTS.md"),
    (Join-Path $cursorDir "rules\AGENTS.mdc")
)) {
    Install-Agents $target
}

$links = [ordered]@{
    (Join-Path $claudeDir "keybindings.json")            = (Join-Path $sharedAi "claude\keybindings.json")
    (Join-Path $claudeDir "commands\i18n-extract.md")    = (Join-Path $sharedAi "claude\commands\i18n-extract.md")
    (Join-Path $claudeDir "skills\release-docs")         = (Join-Path $sharedAi "claude\skills\release-docs")
    (Join-Path $claudeDir "hooks\statusline.ps1")        = (Join-Path $pcAi "claude\hooks\statusline.ps1")
    (Join-Path $codexDir "rules\default.rules")          = (Join-Path $sharedAi "codex\rules\default.rules")
    (Join-Path $codexDir "skills\artisan-mode")          = (Join-Path $sharedAi "codex\skills\artisan-mode")
}

foreach ($target in $links.Keys) {
    New-ConfigLink $links[$target] $target
}

Write-Host "AI config linked." -ForegroundColor Green
Write-Host "Rerun this script after changing shared\ai\claude\settings.json, $claudeOverlay, or (with a work scope) shared\ai\AGENTS.md." -ForegroundColor Yellow
