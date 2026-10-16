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
    "jq"
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
CASKS=("wezterm" "karabiner-elements" "hammerspoon")

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

# Skips a missing source, replaces whatever sits at the target.
link_config() {
    local source="$1" target="$2"
    [ -e "$source" ] || return 0
    mkdir -p "$(dirname "$target")"
    rm -rf "$target"
    echo "Linking $target"
    ln -s "$source" "$target"
}

link_config "$DOTFILES_DIR/mac/nvim/.config/nvim" "$HOME/.config/nvim"
link_config "$DOTFILES_DIR/shared/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
link_config "$DOTFILES_DIR/shared/lazygit/Library/Application Support/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
link_config "$DOTFILES_DIR/shared/yazi/.config/yazi" "$HOME/.config/yazi"
link_config "$DOTFILES_DIR/shared/starship/.config/starship.toml" "$HOME/.config/starship.toml"
link_config "$DOTFILES_DIR/mac/zsh/.zshrc" "$HOME/.zshrc"
link_config "$DOTFILES_DIR/shared/git-prompt.sh" "$HOME/.git-prompt.sh"
link_config "$DOTFILES_DIR/shared/scripts/.config/scripts/mux.sh" "$HOME/.config/scripts/mux.sh"
# Binds alt+shift+r (wezterm-launcher) and alt+shift+p (script-selector).
link_config "$DOTFILES_DIR/mac/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

# Install FiraCode Nerd Font
echo "Installing FiraCode Nerd Font..."
FONT_PATH="$DOTFILES_DIR/shared/fonts/FiraCode Nerd Font-Regular.ttf"
FONT_DIR="$HOME/Library/Fonts"

if [ -f "$FONT_PATH" ]; then
    cp "$FONT_PATH" "$FONT_DIR/"
    echo "Font installed successfully!"
else
    echo "Font file not found, skipping..."
fi

# Optional AI CLIs (Cursor / Codex / Claude) + WezTerm startup tabs
if [ -f "$DOTFILES_DIR/shared/install/setup_ai_clis.sh" ]; then
    bash "$DOTFILES_DIR/shared/install/setup_ai_clis.sh"
fi

if [ -f "$DOTFILES_DIR/shared/install/setup_ai_config.sh" ]; then
    bash "$DOTFILES_DIR/shared/install/setup_ai_config.sh"
fi

echo ""
echo "===================================="
echo "Setup Complete!"
echo "===================================="
echo ""
echo "Next steps:"
echo "1. Restart your terminal"
echo "2. Run 'bash shared/install/setup_git.sh' to configure git user and credentials"
echo "3. Run 'nvim' to set up Neovim plugins"
echo "4. Visit https://ke-complex-modifications.pqrs.org/#windows_shortcuts_on_macos"
echo "   to configure Karabiner Elements for Windows-style shortcuts"
echo ""
