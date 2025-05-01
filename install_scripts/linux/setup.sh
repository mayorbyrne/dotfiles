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

echo "oh my zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

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

echo >> /home/$USER/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/$USER/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

echo "Installing stow..."
brew install stow

echo "Cloning dotfiles..."
git clone https://www.github.com/mayorbyrne/dotfiles.git ~/.dotfiles

echo "Stowing dotfiles..."
cd ~/.dotfiles
stow -v */

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

echo "Done!"
