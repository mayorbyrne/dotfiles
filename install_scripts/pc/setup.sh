## PREREQUISITES
# install nvm for windows
# https://github.com/coreybutler/nvm-windows/releases

# install chocolatey
# https://chocolatey.org/install

echo "Installing git..."
choco install git

# restart the terminal at this point

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

# symlink the dotfiles
# run CMD in administrator mode
mklink /D c:\Users\[username]\AppData\Local\nvim C:\Users\[username]\.dotfiles\nvim\.config\nvim
