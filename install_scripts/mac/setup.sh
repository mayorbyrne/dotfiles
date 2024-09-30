#!/bin/sh
# Description: Setup script for dotfiles

# Install nodejs
echo "Installing node version manager..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

echo "Install latest LTS version of node..."
nvm install --lts

# install homebrew
echo "Installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


echo "Installing programs..."
echo "Installing git..."
brew install git

echo "Installing zsh..."
brew install zsh

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
