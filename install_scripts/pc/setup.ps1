# Windows PC Setup Script
# Double-click setup.bat to run this script

$Host.UI.RawUI.WindowTitle = "PC Setup Script"

trap {
    Write-Host ""
    Write-Host "ERROR OCCURRED!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    Exit 1
}

$ErrorActionPreference = "Stop"

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "PC Setup Script - Starting Installation" -ForegroundColor Cyan
Write-Host ""

$dotfilesDir = "$env:USERPROFILE\.dotfiles"
if (!(Test-Path $dotfilesDir)) {
    Write-Host "Cloning dotfiles..." -ForegroundColor Green
    git clone https://www.github.com/mayorbyrne/dotfiles.git $dotfilesDir
} else {
    Write-Host "Dotfiles directory already exists" -ForegroundColor Gray
}

if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
} else {
    Write-Host "Chocolatey already installed" -ForegroundColor Gray
}

Write-Host "Installing packages via Chocolatey..." -ForegroundColor Green
Write-Host "This may take several minutes. Please be patient..." -ForegroundColor Yellow

$packages = @("git", "neovim", "lazygit", "yazi", "wezterm", "fzf", "ripgrep", "powershell-core")
foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor Gray
    choco install -y $package --limit-output
    Start-Sleep -Seconds 3
}

if (!(Get-Command nvm -ErrorAction SilentlyContinue)) {
    Write-Host "Installing nvm-windows..." -ForegroundColor Green
    $nvmInstaller = "$env:TEMP\nvm-setup.exe"
    Invoke-WebRequest -Uri "https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe" -OutFile $nvmInstaller
    Start-Process -FilePath $nvmInstaller -ArgumentList "/VERYSILENT" -Wait
    Remove-Item $nvmInstaller
    
    Write-Host "Refreshing environment for nvm..." -ForegroundColor Green
    $env:NVM_HOME = "$env:APPDATA\nvm"
    $env:NVM_SYMLINK = "$env:ProgramFiles\nodejs"
    $env:Path = "$env:NVM_HOME;$env:NVM_SYMLINK;$env:Path"
}

Write-Host "Installing Node.js LTS..." -ForegroundColor Green
nvm install lts
nvm use lts

Write-Host "Installing GitHub Copilot CLI..." -ForegroundColor Green
npm install -g @githubnext/github-copilot-cli

Write-Host "Installing PowerShell modules..." -ForegroundColor Green
Install-Module -Name posh-git -Scope CurrentUser -Force -SkipPublisherCheck
Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck

$nvimTarget = "$env:LOCALAPPDATA\nvim"
$nvimSource = "$dotfilesDir\nvim\.config\nvim"

if (Test-Path $nvimTarget) {
    Remove-Item -Path $nvimTarget -Recurse -Force
}

Write-Host "Creating nvim symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $nvimTarget -Target $nvimSource -Force | Out-Null

# PowerShell profile for both PowerShell 5 and PowerShell 6+
$psProfileSource = "$dotfilesDir\base\Microsoft.PowerShell_profile.ps1"

# PowerShell 5 (WindowsPowerShell)
$psProfileDir5 = "$env:USERPROFILE\Documents\WindowsPowerShell"
$psProfileTarget5 = "$psProfileDir5\Microsoft.PowerShell_profile.ps1"

if (!(Test-Path $psProfileDir5)) {
    New-Item -ItemType Directory -Path $psProfileDir5 -Force | Out-Null
}

if (Test-Path $psProfileTarget5) {
    Remove-Item -Path $psProfileTarget5 -Force
}

Write-Host "Creating PowerShell 5 profile symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $psProfileTarget5 -Target $psProfileSource -Force | Out-Null

# PowerShell 6+ (PowerShell Core)
$psProfileDir6 = "$env:USERPROFILE\Documents\PowerShell"
$psProfileTarget6 = "$psProfileDir6\Microsoft.PowerShell_profile.ps1"

if (!(Test-Path $psProfileDir6)) {
    New-Item -ItemType Directory -Path $psProfileDir6 -Force | Out-Null
}

if (Test-Path $psProfileTarget6) {
    Remove-Item -Path $psProfileTarget6 -Force
}

Write-Host "Creating PowerShell 6+ profile symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $psProfileTarget6 -Target $psProfileSource -Force | Out-Null

$weztermTarget = "$env:USERPROFILE\.wezterm.lua"
$weztermSource = "$dotfilesDir\wezterm\.wezterm.lua"

if (Test-Path $weztermTarget) {
    Remove-Item -Path $weztermTarget -Force
}

Write-Host "Creating wezterm config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $weztermTarget -Target $weztermSource -Force | Out-Null

$lazygitConfigDir = "$env:APPDATA\lazygit"
$lazygitTarget = "$lazygitConfigDir\config.yml"
$lazygitSource = "$dotfilesDir\lazygit\Library\Application Support\lazygit\config.yml"

if (!(Test-Path $lazygitConfigDir)) {
    New-Item -ItemType Directory -Path $lazygitConfigDir -Force | Out-Null
}

if (Test-Path $lazygitTarget) {
    Remove-Item -Path $lazygitTarget -Force
}

Write-Host "Creating lazygit config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $lazygitTarget -Target $lazygitSource -Force | Out-Null

$yaziConfigDir = "$env:APPDATA\yazi\config"
$yaziSource = "$dotfilesDir\yazi\.config\yazi"

if (Test-Path $yaziConfigDir) {
    Remove-Item -Path $yaziConfigDir -Recurse -Force
}

Write-Host "Creating yazi config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $yaziConfigDir -Target $yaziSource -Force | Out-Null

$starshipConfigDir = "$env:USERPROFILE\.config"
$starshipTarget = "$starshipConfigDir\starship.toml"
$starshipSource = "$dotfilesDir\starship\.config\starship.toml"

if (!(Test-Path $starshipConfigDir)) {
    New-Item -ItemType Directory -Path $starshipConfigDir -Force | Out-Null
}

if (Test-Path $starshipTarget) {
    Remove-Item -Path $starshipTarget -Force
}

Write-Host "Creating starship config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $starshipTarget -Target $starshipSource -Force | Out-Null

Write-Host "Installing FiraCode Nerd Font..." -ForegroundColor Green
$fontPath = "$dotfilesDir\fonts\FiraCode Nerd Font-Regular.ttf"
$FONTS = 0x14
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)
$objFolder.CopyHere($fontPath, 0x10)

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "Restart your terminal and run 'nvim'" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run 'install_scripts\setup_git.ps1' to configure git user and credentials" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
