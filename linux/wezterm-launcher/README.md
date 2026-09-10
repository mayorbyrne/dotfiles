# wezterm-launcher (Linux)

A lightweight GTK GUI launcher for [WezTerm](https://wezfurlong.org/wezterm/) workspaces on Linux — the Linux port of `pc/wezterm-launcher/`.

## Features

- **First-run setup** — asks where your projects live and saves it to `~/.config/wezterm/projects_root.txt` so WezTerm workspace launches use the same root.
- **Recent tab** — lists workspaces from launcher history.
- **New Workspace tab** — browses folders under your projects root and launches a WezTerm workspace with a chosen dev server command.
- **Command preview** — shows the exact `wezterm start` command before you launch it.
- **Run-mode options**:
  - `webdev` — runs `webdev serve web:<port>` (default port `8080`)
  - `npm run dev` — runs `npm run dev -- --port=<port>` (default port `5173`), with an optional `dev-dummy` toggle

## Requirements

- Linux with Python 3 + PyGObject (GTK 3)
- [WezTerm](https://wezfurlong.org/wezterm/) installed and on `PATH`
- `~/.wezterm.lua` present (usually symlinked from this dotfiles repo)

On Omarchy/Arch these are typically already available (`python`, `python-gobject`, `gtk3`).

## Usage

```bash
linux/wezterm-launcher/launch.sh
```

Or open **WezTerm Launcher** from the app menu after install. On Omarchy, the installer also binds **Super+Shift+R**.

### First run

1. Pick the folder that contains your project directories (e.g. `~/Documents` or `~/git`).
2. That path is saved to `~/.config/wezterm-launcher/config.json`.
3. `~/.config/wezterm/projects_root.txt` is written so `.wezterm.lua` picks up the same root.

To change it later, delete `~/.config/wezterm-launcher/config.json` and run the launcher again.

### Recent tab

Reads launcher history. Select a workspace and click **Launch** (or press Enter) to reopen it.

### New Workspace tab

1. Select a folder from the list (populated from your projects root).
2. Choose a run mode (`webdev` or `npm run dev`).
3. Optionally toggle **dummy** mode (only visible for `npm run dev` when `package.json` has a `dev-dummy` script).
4. Adjust the port if needed.
5. Click **Launch**.

## Configuration

| Value | Location |
|-------|----------|
| Projects root | `~/.config/wezterm-launcher/config.json` (`projectsRoot`) |
| Launch history | `~/.config/wezterm-launcher/history.json` |
| WezTerm projects root | `~/.config/wezterm/projects_root.txt` |
| Script path | `launch.sh` → `launcher.py` |

This lives in the dotfiles repo at `linux/wezterm-launcher/`.

## Files

| File | Purpose |
|------|---------|
| `launcher.py` | Main script — setup prompt, GTK GUI, launch logic |
| `launch.sh` | Thin wrapper that runs `launcher.py` |
| `wezterm-launcher.desktop` | App menu entry (installed by setup scripts) |
