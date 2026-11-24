# Azure DevOps setup: az devops defaults, credentials, and config.sh for ~/scripts.
# Rerunning is safe. Current values are offered as defaults.

$ErrorActionPreference = "Stop"

function Read-WithDefault([string]$prompt, [string]$default) {
    $label = $prompt
    if ($default) {
        $label = "$prompt [$default]"
    }
    $answer = "$(Read-Host $label)".Trim()
    if ($answer) {
        return $answer
    }
    return $default
}

# Windows PowerShell turns native stderr into a terminating error under Stop.
function Invoke-AzQuiet {
    $ErrorActionPreference = "Continue"
    az @args 2>$null
}

function Get-AzDevopsDefault([string[]]$lines, [string]$name) {
    $line = $lines | Where-Object { $_ -match "^$name\s*=" } | Select-Object -First 1
    if (!$line) {
        return ""
    }
    return ($line -split '=', 2)[1].Trim()
}

function Set-ShellAssignment([string]$content, [string]$name, [string]$line) {
    $pattern = "(?m)^$name=[^\r\n]*"
    if ($content -match $pattern) {
        return [regex]::Replace($content, $pattern, $line.Replace('$', '$$'))
    }
    return $content.TrimEnd() + "`n`n$line`n"
}

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Azure DevOps Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$hasAz = [bool](Get-Command az -ErrorAction SilentlyContinue)
if ($hasAz) {
    $azDefaults = @(Invoke-AzQuiet devops configure --list)
    $organization = Read-WithDefault "Organization URL or name" (Get-AzDevopsDefault $azDefaults "organization")
    $project = Read-WithDefault "Default project" (Get-AzDevopsDefault $azDefaults "project")

    if ($organization -and $organization -notmatch '^https?://') {
        $organization = "https://dev.azure.com/$organization"
    }
    $organization = "$organization".TrimEnd('/')

    $defaults = @()
    if ($organization) { $defaults += "organization=$organization" }
    if ($project) { $defaults += "project=$project" }
    if ($defaults) {
        az devops configure --defaults @defaults
        if ($LASTEXITCODE -ne 0) {
            throw "az devops configure failed. Is the azure-devops extension installed?"
        }
        Write-Host "  Set az devops defaults: $($defaults -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "  No organization or project given. Skipping az devops defaults." -ForegroundColor Yellow
    }
} else {
    Write-Host "az not found. Skipping az devops defaults." -ForegroundColor Yellow
}
Write-Host ""

$scriptsDir = Join-Path $env:USERPROFILE "scripts"
$configPath = Join-Path $scriptsDir "windows\config.sh"
$examplePath = Join-Path $scriptsDir "windows\config.example.sh"
$hasConfig = Test-Path $configPath
$templatePath = if ($hasConfig) { $configPath } else { $examplePath }

if (Test-Path $templatePath) {
    $content = Get-Content -LiteralPath $templatePath -Raw

    $currentRepoBase = ""
    if ($content -match '(?m)^REPO_BASE="?([^"\r\n]*)"?') {
        $currentRepoBase = $Matches[1]
    }
    # The example file's reviewers are placeholders, not defaults worth offering.
    $currentReviewers = @()
    if ($hasConfig -and $content -match '(?m)^REVIEWERS=\(([^)]*)\)') {
        $currentReviewers = @([regex]::Matches($Matches[1], '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value })
    }

    $repoBase = (Read-WithDefault "Directory holding your cloned repos" $currentRepoBase) -replace '\\', '/'
    $repoBase = $repoBase.TrimEnd('/')
    $reviewerInput = Read-WithDefault "Required PR reviewers (comma-separated emails)" ($currentReviewers -join ', ')
    $reviewers = @($reviewerInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })

    if ($repoBase -and !(Test-Path $repoBase)) {
        Write-Host "  Warning: $repoBase does not exist yet" -ForegroundColor Yellow
    }

    $reviewersLine = "REVIEWERS=(" + (($reviewers | ForEach-Object { "`"$_`"" }) -join ' ') + ")"
    $content = Set-ShellAssignment $content "REPO_BASE" "REPO_BASE=`"$repoBase`""
    $content = Set-ShellAssignment $content "REVIEWERS" $reviewersLine
    $content = $content -replace '(?m)^# Copy this file to config\.sh[^\r\n]*\r?\n\r?\n?', ''

    # No BOM: bash sources this file, and Windows PowerShell's utf8 encoding adds one.
    [System.IO.File]::WriteAllText($configPath, $content, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  Wrote $configPath" -ForegroundColor Green
} else {
    Write-Host "$scriptsDir not found. Skipping config.sh (run pc\install\setup.ps1 to clone it)." -ForegroundColor Yellow
}
Write-Host ""

$patName = "AZURE_DEVOPS_EXT_PAT"
$hasPat = [bool][Environment]::GetEnvironmentVariable($patName, "User")
$patPrompt = if ($hasPat) { "Personal access token (blank to keep the stored one)" } else { "Personal access token (blank to skip)" }
$pat = ""
# A masked prompt reads the console, so it hangs when input is piped.
if (![Console]::IsInputRedirected) {
    $pat = (New-Object System.Net.NetworkCredential("", (Read-Host $patPrompt -AsSecureString))).Password
}
if ($pat) {
    [Environment]::SetEnvironmentVariable($patName, $pat, "User")
    $env:AZURE_DEVOPS_EXT_PAT = $pat
    $hasPat = $true
    Write-Host "  Stored $patName as a user environment variable. New terminals pick it up." -ForegroundColor Green
}

if ($hasAz -and !$hasPat) {
    Invoke-AzQuiet account show --output none
    if ($LASTEXITCODE -ne 0 -and (Read-Host "No token and not signed in. Run 'az login' now? (Y/n)") -notmatch '^[nN]') {
        az login --allow-no-subscriptions --output none
    }
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Azure DevOps Setup Complete!" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
