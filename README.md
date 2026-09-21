# dotfiles

One branch for all machines. Shared configs live in `shared/`; OS-specific overlays live in `pc/`, `linux/`, and `mac/`.

## Layout

```
shared/   # wezterm, yazi, starship, lazygit, fonts, tmux, snippets, git-prompt, git setup, AI config
pc/       # Windows nvim + PowerShell profile + wezterm-launcher + Windows-only AI hooks
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

Installers also prompt for optional AI CLIs (Cursor `agent`, Codex, Claude). Choices are written to `~/.config/wezterm/ai_clis.txt`, and WezTerm opens a startup tab for each.

## AI config

`shared/ai/` holds the hand-authored Claude Code and Codex config; `pc/ai/` holds
the Windows-only pieces. The installers call `shared/install/setup_ai_config.ps1`
(Windows) or `shared/install/setup_ai_config.sh` (Linux/macOS), which symlinks:

| Repo path | Linked to |
|---|---|
| `shared/ai/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `shared/ai/claude/settings.json` | `~/.claude/settings.json` |
| `shared/ai/claude/keybindings.json` | `~/.claude/keybindings.json` |
| `shared/ai/claude/commands/i18n-extract.md` | `~/.claude/commands/i18n-extract.md` |
| `shared/ai/claude/skills/release-docs` | `~/.claude/skills/release-docs` |
| `pc/ai/claude/hooks/statusline.ps1` | `~/.claude/hooks/statusline.ps1` (Windows only) |
| `shared/ai/codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `shared/ai/codex/config.toml` | `~/.codex/config.toml` |
| `shared/ai/codex/rules/default.rules` | `~/.codex/rules/default.rules` |
| `shared/ai/codex/skills/artisan-mode` | `~/.codex/skills/artisan-mode` |

Links are made per file and per skill, not per directory, so the tool-generated
neighbours in the same folders (`~/.claude/skills/synced/`,
`~/.codex/skills/.system/`, plugin-provided symlinks) stay untouched.

Existing real files are moved to `<path>.bak-<timestamp>` before linking. Nothing
is deleted blind. Windows symlinks need Developer Mode on, or an elevated shell.

What never syncs: `~/.claude/.credentials.json`, `~/.codex/auth.json`, session
and history files, caches, and `settings.local.json`. Credentials are regenerated
by logging in on the new machine.

Plugins are not copied in. `settings.json` already declares
`extraKnownMarketplaces` and `enabledPlugins`, so Claude Code installs them from
the marketplace repo on first run.

Machine drift:

- `~/.claude/settings.local.json` is the git-ignored per-machine override, merged
  over the synced `settings.json`.
- The synced `statusLine` runs `statusline.ps1` and is guarded by a file test, so
  it is a no-op on Linux and macOS. Override it in `settings.local.json` there.
- `shared/ai/codex/config.toml` carries per-project `trust_level` entries and a
  local marketplace path under `D:\git\`. Harmless elsewhere (the paths simply
  do not match), but edit it if a machine uses a different root.
- Claude Code and Orca rewrite `settings.json` in place. Because it is a symlink,
  those edits land in this repo and show up as ordinary diffs.

Cursor is not set up yet. It was not installed on the machine this was built on,
so its real config paths are unconfirmed. See `TODO.md`.

After that, configure git:

- Windows: `shared/install/setup_git.ps1`
- Linux / macOS: `bash shared/install/setup_git.sh`

Existing machines that already cloned this repo need a re-run of their installer (or manual recreation of symlinks) after pulling this layout — old paths like `.dotfiles/nvim` no longer exist.
