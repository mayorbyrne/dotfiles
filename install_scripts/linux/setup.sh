#!/bin/sh
# Description: Setup script for dotfiles
echo "Install curl..."
sudo apt install curl

echo "Install unzip..."
sudo apt install unzip

echo "Installing ZSH..."
sudo apt install zsh

echo "Add zsh to etc/shells"
command -v zsh | sudo tee -a /etc/shells

echo "Making zsh default shell..."
sudo chsh -s $(which zsh) $USER

echo "Installing wezterm..."
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update
sudo apt install wezterm

echo "Installing stow..."
brew install stow

echo "Cloning dotfiles..."
git clone https://www.github.com/mayorbyrne/dotfiles.git ~/.dotfiles

echo "Stowing dotfiles..."
cd ~/.dotfiles
stow --adopt -v base
stow --adopt -v lazygit
stow --adopt -v nvim
stow --adopt -v scripts
stow --adopt -v tmux
stow --adopt -v wezterm
stow --adopt -v yazi
git restore .
source ~/.zshrc

echo "SWITCH TO wezterm now and continue"
return 1

echo "Install curl..."
sudo apt install curl

echo "Install unzip..."
sudo apt install unzip

echo "Installing ZSH..."
sudo apt install zsh

echo "Installing git..."
sudo apt install git-all

echo "oh my zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "fire up terminal once more and continue"
return 1

# Install nodejs
echo "Installing fnm..."
curl -fsSL https://fnm.vercel.app/install | bash

echo "Install latest LTS version of node..."
fnm install --lts

# install homebrew
echo "Installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo >> /home/$USER/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/$USER/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

echo "Installing programs..."

echo "Installing tmux..."
brew install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Installing neovim..."
brew install neovim

echo "Installing lazygit..."
brew install lazygit

echo "Installing lazyvim..."
brew install lazyvim

echo "Installing yazi..."
brew install yazi

echo "Installing wezterm..."
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update
sudo apt install wezterm

echo "Installing fzf..."
brew install fzf

echo "Installing ripgrep..."
brew install ripgrep

echo "build-essentials..."
sudo apt install build-essential

echo "firacode"
sudo apt install fonts-firacode

cd ~
wget https://github.com/GitCredentialManager/git-credential-manager/releases/download/v2.0.935/gcm-linux_amd64.2.0.935.deb
sudo dpkg -i gcm-linux_amd64.2.0.935.deb
git-credential-manager configure
git config --global credential.credentialStore cache
git config --global user.name "Kevin Moritz"
git config --global user.email ""

echo "Done!"
