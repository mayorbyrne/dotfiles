# dotfiles

One branch for all machines. Shared configs live in `shared/`; OS-specific overlays live in `pc/`, `linux/`, and `mac/`.

## Layout

```
shared/   # wezterm, yazi, starship, lazygit, fonts, tmux, snippets, git-prompt, git setup
pc/       # Windows nvim + PowerShell profile + wezterm-launcher
linux/    # Linux nvim + zsh + waybar + wezterm-launcher
mac/      # macOS nvim + zsh + iTerm2
```

Machine-specific edits go in the matching overlay. Do not put OS-only files in `shared/`.

## Install

Clone into `~/.dotfiles`:

```bash
git clone https://github.com/mayorbyrne/dotfiles.git ~/.dotfiles
```

Then run the installer for your OS:

| OS | Installer |
|---|---|
| Windows | `pc/install/setup.ps1` (or double-click `pc/install/setup.bat`) |
| Linux (Ubuntu/apt) | `bash linux/install/setup.sh` |
| Linux (Arch/Omarchy) | `bash linux/install/omarchy.sh` |
| macOS | `bash mac/install/setup.sh` |

After that, configure git:

- Windows: `shared/install/setup_git.ps1`
- Linux / macOS: `bash shared/install/setup_git.sh`

Existing machines that already cloned this repo need a re-run of their installer (or manual recreation of symlinks) after pulling this layout — old paths like `.dotfiles/nvim` no longer exist.
