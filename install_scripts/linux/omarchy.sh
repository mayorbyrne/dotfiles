#!/bin/bash
# Omarchy (Arch Linux) Setup Script
# Run this script with: bash omarchy.sh

set -e

echo "===================================="
echo "Omarchy Setup Script - Starting Installation"
echo "===================================="
echo ""

# Update package database
echo "Updating package database..."
sudo pacman -Sy

# Install essential packages
echo "Installing essential packages..."
ESSENTIAL_PACKAGES=("base-devel" "git" "curl" "wget" "unzip" "zsh")

for package in "${ESSENTIAL_PACKAGES[@]}"; do
    if pacman -Q "$package" &> /dev/null; then
        echo "$package already installed"
    else
        echo "Installing $package..."
        sudo pacman -S --noconfirm "$package"
    fi
done

# Clone dotfiles first
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles..."
    git clone https://www.github.com/mayorbyrne/dotfiles.git "$DOTFILES_DIR"
else
    echo "Dotfiles directory already exists"
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    sudo chsh -s "$(which zsh)" "$USER"
else
    echo "zsh already set as default shell"
fi

# Install yay (AUR helper)
if ! command -v yay &> /dev/null; then
    echo "Installing yay (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd -
else
    echo "yay already installed"
fi

# Install packages via pacman and AUR
echo "Installing packages via pacman and yay..."
echo "This may take several minutes. Please be patient..."
echo ""

PACKAGES=(
    "neovim"
    "lazygit"
    "yazi"
    "fzf"
    "ripgrep"
    "starship"
)

for package in "${PACKAGES[@]}"; do
    if pacman -Q "$package" &> /dev/null; then
        echo "$package already installed"
    else
        echo "Installing $package..."
        yay -S --noconfirm "$package"
    fi
done

# Install wezterm
if ! command -v wezterm &> /dev/null; then
    echo "Installing wezterm..."
    yay -S --noconfirm wezterm
else
    echo "wezterm already installed"
fi

# Install fnm (Fast Node Manager)
if ! command -v fnm &> /dev/null; then
    echo "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash
    
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
else
    echo "fnm already installed"
fi

echo "Installing Node.js LTS..."
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm use lts-latest

# Setup tools directory for global packages
TOOLS_DIR="$HOME/tools"
mkdir -p "$TOOLS_DIR"

echo "Installing GitHub Copilot CLI to $TOOLS_DIR..."
npm install --prefix "$TOOLS_DIR" @githubnext/github-copilot-cli

# Add tools to PATH in zshrc if not already present
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "export PATH=\"\$HOME/tools/node_modules/.bin:\$PATH\"" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# Tools directory" >> "$HOME/.zshrc"
        echo "export PATH=\"\$HOME/tools/node_modules/.bin:\$PATH\"" >> "$HOME/.zshrc"
    fi
fi

# Create symlinks for configurations
echo "Creating configuration symlinks..."

# Neovim
NVIM_TARGET="$HOME/.config/nvim"
NVIM_SOURCE="$DOTFILES_DIR/nvim/.config/nvim"

if [ -L "$NVIM_TARGET" ] || [ -d "$NVIM_TARGET" ]; then
    rm -rf "$NVIM_TARGET"
fi

mkdir -p "$HOME/.config"
echo "Creating nvim symlink..."
ln -sf "$NVIM_SOURCE" "$NVIM_TARGET"

# Wezterm
WEZTERM_TARGET="$HOME/.wezterm.lua"
WEZTERM_SOURCE="$DOTFILES_DIR/wezterm/.wezterm.lua"

if [ -L "$WEZTERM_TARGET" ] || [ -f "$WEZTERM_TARGET" ]; then
    rm -f "$WEZTERM_TARGET"
fi

echo "Creating wezterm config symlink..."
ln -sf "$WEZTERM_SOURCE" "$WEZTERM_TARGET"

# Lazygit
LAZYGIT_TARGET="$HOME/.config/lazygit/config.yml"
LAZYGIT_SOURCE="$DOTFILES_DIR/lazygit/Library/Application Support/lazygit/config.yml"

mkdir -p "$HOME/.config/lazygit"

if [ -L "$LAZYGIT_TARGET" ] || [ -f "$LAZYGIT_TARGET" ]; then
    rm -f "$LAZYGIT_TARGET"
fi

echo "Creating lazygit config symlink..."
ln -sf "$LAZYGIT_SOURCE" "$LAZYGIT_TARGET"

# Yazi
YAZI_TARGET="$HOME/.config/yazi"
YAZI_SOURCE="$DOTFILES_DIR/yazi/.config/yazi"

if [ -L "$YAZI_TARGET" ] || [ -d "$YAZI_TARGET" ]; then
    rm -rf "$YAZI_TARGET"
fi

echo "Creating yazi config symlink..."
ln -sf "$YAZI_SOURCE" "$YAZI_TARGET"

# Starship
STARSHIP_TARGET="$HOME/.config/starship.toml"
STARSHIP_SOURCE="$DOTFILES_DIR/starship/.config/starship.toml"

if [ -L "$STARSHIP_TARGET" ] || [ -f "$STARSHIP_TARGET" ]; then
    rm -f "$STARSHIP_TARGET"
fi

echo "Creating starship config symlink..."
ln -sf "$STARSHIP_SOURCE" "$STARSHIP_TARGET"

# Zsh configuration
ZSH_TARGET="$HOME/.zshrc"
ZSH_SOURCE="$DOTFILES_DIR/base/.zshrc"

if [ -f "$ZSH_SOURCE" ]; then
    if [ -L "$ZSH_TARGET" ] || [ -f "$ZSH_TARGET" ]; then
        rm -f "$ZSH_TARGET"
    fi
    echo "Creating zsh config symlink..."
    ln -sf "$ZSH_SOURCE" "$ZSH_TARGET"
fi

# Git prompt
GIT_PROMPT_TARGET="$HOME/.git-prompt.sh"
GIT_PROMPT_SOURCE="$DOTFILES_DIR/base/git-prompt.sh"

if [ -f "$GIT_PROMPT_SOURCE" ]; then
    if [ -L "$GIT_PROMPT_TARGET" ] || [ -f "$GIT_PROMPT_TARGET" ]; then
        rm -f "$GIT_PROMPT_TARGET"
    fi
    echo "Creating git-prompt.sh symlink..."
    ln -sf "$GIT_PROMPT_SOURCE" "$GIT_PROMPT_TARGET"
fi

# Install FiraCode Nerd Font
echo "Installing FiraCode Nerd Font..."
FONT_PATH="$DOTFILES_DIR/fonts/FiraCode Nerd Font-Regular.ttf"
FONT_DIR="$HOME/.local/share/fonts"

if [ -f "$FONT_PATH" ]; then
    mkdir -p "$FONT_DIR"
    cp "$FONT_PATH" "$FONT_DIR/"
    fc-cache -fv
    echo "Font installed successfully!"
else
    echo "Font file not found, skipping..."
fi

echo ""
echo "===================================="
echo "Setup Complete!"
echo "===================================="
echo ""
echo "Next steps:"
echo "1. Log out and log back in (or restart) for zsh to be your default shell"
echo "2. Run 'bash install_scripts/setup_git.sh' to configure git user and credentials"
echo "3. Open wezterm and run 'nvim' to set up Neovim plugins"
echo ""
