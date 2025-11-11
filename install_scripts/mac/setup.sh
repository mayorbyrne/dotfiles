#!/bin/bash
# macOS Setup Script
# Run this script with: bash setup.sh

set -e

echo "===================================="
echo "macOS Setup Script - Starting Installation"
echo "===================================="
echo ""

# Clone dotfiles first
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles..."
    git clone https://www.github.com/mayorbyrne/dotfiles.git "$DOTFILES_DIR"
else
    echo "Dotfiles directory already exists"
fi

# Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo "Configuring Homebrew for Apple Silicon..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed"
fi

# Install packages via Homebrew
echo "Installing packages via Homebrew..."
echo "This may take several minutes. Please be patient..."
echo ""

PACKAGES=(
    "git"
    "neovim"
    "lazygit"
    "yazi"
    "fzf"
    "ripgrep"
    "starship"
)

for package in "${PACKAGES[@]}"; do
    if brew list "$package" &> /dev/null; then
        echo "$package already installed"
    else
        echo "Installing $package..."
        brew install "$package"
    fi
done

# Install cask applications
echo "Installing GUI applications..."
CASKS=("wezterm" "karabiner-elements")

for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &> /dev/null; then
        echo "$cask already installed"
    else
        echo "Installing $cask..."
        brew install --cask "$cask"
    fi
done

# Install nvm and Node.js
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    echo "nvm already installed"
fi

echo "Installing Node.js LTS..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

echo "Installing GitHub Copilot CLI..."
npm install -g @githubnext/github-copilot-cli

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
LAZYGIT_TARGET="$HOME/Library/Application Support/lazygit/config.yml"
LAZYGIT_SOURCE="$DOTFILES_DIR/lazygit/Library/Application Support/lazygit/config.yml"

mkdir -p "$HOME/Library/Application Support/lazygit"

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
FONT_DIR="$HOME/Library/Fonts"

if [ -f "$FONT_PATH" ]; then
    cp "$FONT_PATH" "$FONT_DIR/"
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
echo "1. Restart your terminal"
echo "2. Run 'bash install_scripts/setup_git.sh' to configure git user and credentials"
echo "3. Run 'nvim' to set up Neovim plugins"
echo "4. Visit https://ke-complex-modifications.pqrs.org/#windows_shortcuts_on_macos"
echo "   to configure Karabiner Elements for Windows-style shortcuts"
echo ""
