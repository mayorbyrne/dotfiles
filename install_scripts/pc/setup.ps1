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

$packages = @("git", "neovim", "lazygit", "yazi", "wezterm", "fzf", "ripgrep")
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
}

$dotfilesDir = "$env:USERPROFILE\.dotfiles"
if (!(Test-Path $dotfilesDir)) {
    Write-Host "Cloning dotfiles..." -ForegroundColor Green
    git clone https://www.github.com/mayorbyrne/dotfiles.git $dotfilesDir
}

$nvimTarget = "$env:LOCALAPPDATA\nvim"
$nvimSource = "$dotfilesDir\nvim\.config\nvim"

if (Test-Path $nvimTarget) {
    Remove-Item -Path $nvimTarget -Recurse -Force
}

Write-Host "Creating nvim symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $nvimTarget -Target $nvimSource -Force | Out-Null

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "Restart your terminal and run 'nvim'" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
