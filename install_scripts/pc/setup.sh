
#!/bin/sh
# Description: Setup script for dotfiles

# Install nodejs
echo "Installing node version manager..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

echo "Install latest LTS version of node..."
nvm install --lts

echo "Installing chocolatey..."
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

echo "Installing git..."
choco install git

echo "Installing neovim..."
choco install neovim

echo "Installing lazygit..."
choco install lazygit

echo "Installing yazi..."
choco install yazi

echo "Installing wezterm..."
choco install wezterm

echo "Installing fzf..."
choco install fzf

echo "Installing ripgrep..."
choco install ripgrep

echo "Cloning dotfiles..."
git clone https://www.github.com/mayorbyrne/dotfiles.git ~/.dotfiles

