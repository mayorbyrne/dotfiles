#!/bin/sh
# Description: Setup script for dotfiles

echo "Installing ZSH..."
sudo apt install zsh

echo "Making zsh default shell..."
chsh -s $(which zsh)

echo "Install curl..."
sudo apt install curl

echo "Install unzip..."
sudo apt install unzip

# Install nodejs
echo "Installing fnm..."
curl -fsSL https://fnm.vercel.app/install | bash

echo "Install latest LTS version of node..."
fnm install --lts

echo "Installing git..."
sudo apt install git-all

# install homebrew
echo "Installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Installing programs..."

echo "Installing tmux..."
brew install tmux

echo "Installing neovim..."
brew install neovim

echo "Installing lazygit..."
brew install lazygit

echo "Installing lazyvim..."
brew install lazyvim

echo "Installing yazi..."
brew install yazi

echo "Installing wezterm..."
brew install wezterm

echo "Installing fzf..."
brew install fzf

echo "Installing ripgrep..."
brew install ripgrep

echo "Installing stow..."
brew install stow

echo "Cloning dotfiles..."
git clone https://www.github.com/mayorbyrne/dotfiles.git ~/.dotfiles

echo "Stowing dotfiles..."
cd ~/.dotfiles
stow -v */

echo "Done!"
