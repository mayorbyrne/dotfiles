#!/usr/bin/env bash
# Usage: switch.sh elforest|classic|classic-green
set -euo pipefail

theme="${1:-}"
case "$theme" in
  elforest) flavor="elforest" ;;
  classic) flavor="catppuccin-mocha" ;;
  classic-green) flavor="classic-green" ;;
  *) echo "Usage: $0 elforest|classic|classic-green" >&2; exit 1 ;;
esac

dotfiles="$HOME/.dotfiles/shared"
lazygit="$dotfiles/lazygit/Library/Application Support/lazygit/config.yml"

printf '%s\n' "$theme" > "$dotfiles/theme/theme.txt"
printf '[flavor]\ndark = "%s"\nlight = "%s"\n' "$flavor" "$flavor" > "$dotfiles/yazi/.config/yazi/theme.toml"

# Classic themes have no lazygit theme, so the block is commented out rather than swapped.
if [ "$theme" != "elforest" ]; then
  sed -i.bak '/# theme:start/,/# theme:end/{/# theme:/!s/^\([^#]\)/#~\1/;}' "$lazygit"
else
  sed -i.bak '/# theme:start/,/# theme:end/s/^#~//' "$lazygit"
fi
rm -f "$lazygit.bak"

echo "Theme set to $theme. Reload wezterm (save .wezterm.lua or restart), then reopen nvim, yazi, lazygit."
