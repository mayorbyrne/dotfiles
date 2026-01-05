#!/bin/bash
# Git Configuration Script
# Run this script with: bash setup_git.sh

set -e

echo "===================================="
echo "Git Configuration Setup"
echo "===================================="
echo ""

# Prompt for user information
read -p "Enter your full name (for git commits): " GIT_USER_NAME
read -p "Enter your email address (for git commits): " GIT_USER_EMAIL

# Validate inputs
if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    echo "Error: Name and email cannot be empty"
    exit 1
fi

# Configure git user info
echo "Configuring git user information..."
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

echo "Git user configured:"
echo "  Name: $(git config --global user.name)"
echo "  Email: $(git config --global user.email)"
echo ""

# Install Git Credential Manager based on OS
OS_TYPE="$(uname -s)"

case "$OS_TYPE" in
    Linux*)
        echo "Installing Git Credential Manager for Linux..."
        if ! command -v git-credential-manager &> /dev/null; then
            GCM_VERSION="2.0.935"
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            
            # Try package manager-specific installation
            if command -v pacman &> /dev/null; then
                # Arch Linux
                echo "Detected Arch Linux, using AUR..."
                if command -v yay &> /dev/null; then
                    yay -S --noconfirm git-credential-manager
                elif command -v paru &> /dev/null; then
                    paru -S --noconfirm git-credential-manager
                else
                    echo "Installing from tarball (AUR helpers not found)..."
                    wget "https://github.com/GitCredentialManager/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.tar.gz"
                    tar -xzf "gcm-linux_amd64.${GCM_VERSION}.tar.gz"
                    sudo install -m 755 git-credential-manager /usr/local/bin/
                fi
            elif command -v dpkg &> /dev/null; then
                # Debian/Ubuntu
                wget "https://github.com/GitCredentialManager/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.deb"
                sudo dpkg -i "gcm-linux_amd64.${GCM_VERSION}.deb"
            elif command -v rpm &> /dev/null; then
                # Fedora/RHEL
                wget "https://github.com/GitCredentialManager/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.rpm"
                sudo rpm -i "gcm-linux_amd64.${GCM_VERSION}.rpm"
            else
                # Generic tarball installation
                echo "Installing from tarball..."
                wget "https://github.com/GitCredentialManager/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.tar.gz"
                tar -xzf "gcm-linux_amd64.${GCM_VERSION}.tar.gz"
                sudo install -m 755 git-credential-manager /usr/local/bin/
            fi
            
            cd -
            rm -rf "$TEMP_DIR"
            echo "Git Credential Manager installed successfully!"
        else
            echo "Git Credential Manager already installed"
        fi
        
        if command -v git-credential-manager &> /dev/null; then
            git-credential-manager configure
            git config --global credential.credentialStore cache
            # Disable GUI to avoid SkiaSharp dependency issues
            git config --global credential.guiPrompt false
            echo "Git Credential Manager configured to use cache store (GUI disabled)"
        else
            echo "Warning: Git Credential Manager installation may have issues. Skipping configuration."
        fi
        ;;
        
    Darwin*)
        echo "Installing Git Credential Manager for macOS..."
        if ! command -v git-credential-manager &> /dev/null; then
            if command -v brew &> /dev/null; then
                brew install --cask git-credential-manager
                echo "Git Credential Manager installed successfully!"
            else
                echo "Warning: Homebrew not found. Please install Homebrew first or install GCM manually."
                exit 1
            fi
        else
            echo "Git Credential Manager already installed"
        fi
        
        git-credential-manager configure
        git config --global credential.credentialStore keychain
        echo "Git Credential Manager configured to use macOS keychain"
        ;;
        
    MINGW*|MSYS*|CYGWIN*)
        echo "Git Credential Manager is typically bundled with Git for Windows"
        echo "If not available, download from:"
        echo "https://github.com/GitCredentialManager/git-credential-manager/releases"
        
        if command -v git-credential-manager &> /dev/null; then
            git-credential-manager configure
            echo "Git Credential Manager configured"
        fi
        ;;
        
    *)
        echo "Unsupported operating system: $OS_TYPE"
        echo "Please install Git Credential Manager manually from:"
        echo "https://github.com/GitCredentialManager/git-credential-manager/releases"
        ;;
esac

echo ""
echo "===================================="
echo "Git Configuration Complete!"
echo "===================================="
echo ""
echo "Your git is now configured with:"
echo "  Name: $GIT_USER_NAME"
echo "  Email: $GIT_USER_EMAIL"
echo "  Credential Manager: Installed and configured"
echo ""
