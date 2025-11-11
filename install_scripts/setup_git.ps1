# Git Configuration Script for Windows
# Run this script with PowerShell

$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Git Configuration Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for user information
$gitUserName = Read-Host "Enter your full name (for git commits)"
$gitUserEmail = Read-Host "Enter your email address (for git commits)"

# Validate inputs
if ([string]::IsNullOrWhiteSpace($gitUserName) -or [string]::IsNullOrWhiteSpace($gitUserEmail)) {
    Write-Host "Error: Name and email cannot be empty" -ForegroundColor Red
    exit 1
}

# Configure git user info
Write-Host "Configuring git user information..." -ForegroundColor Green
git config --global user.name "$gitUserName"
git config --global user.email "$gitUserEmail"

Write-Host "Git user configured:" -ForegroundColor Green
Write-Host "  Name: $(git config --global user.name)"
Write-Host "  Email: $(git config --global user.email)"
Write-Host ""

# Create symlink for git-prompt.sh
Write-Host "Setting up git-prompt.sh..." -ForegroundColor Green
$dotfilesPath = Split-Path -Parent $PSScriptRoot
$gitPromptSource = Join-Path $dotfilesPath "base\git-prompt.sh"
$gitPromptTarget = Join-Path $env:USERPROFILE ".git-prompt.sh"

if (Test-Path $gitPromptTarget) {
    if ((Get-Item $gitPromptTarget).LinkType -eq "SymbolicLink") {
        Write-Host "  Removing existing symlink..." -ForegroundColor Yellow
        Remove-Item $gitPromptTarget -Force
    } else {
        Write-Host "  Backing up existing .git-prompt.sh to .git-prompt.sh.bak" -ForegroundColor Yellow
        Move-Item $gitPromptTarget "$gitPromptTarget.bak" -Force
    }
}

New-Item -ItemType SymbolicLink -Path $gitPromptTarget -Target $gitPromptSource -Force | Out-Null
Write-Host "  Created symlink: $gitPromptTarget -> $gitPromptSource" -ForegroundColor Green
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Git Configuration Complete!" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your git is now configured with:"
Write-Host "  Name: $gitUserName"
Write-Host "  Email: $gitUserEmail"
Write-Host ""
