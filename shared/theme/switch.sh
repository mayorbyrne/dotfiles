#!/usr/bin/env bash
# Usage: switch.sh elforest|classic
set -euo pipefail

theme="${1:-}"
case "$theme" in
  elforest) flavor="elforest" ;;
  classic) flavor="catppuccin-mocha" ;;
  *) echo "Usage: $0 elforest|classic" >&2; exit 1 ;;
esac

dotfiles="$HOME/.dotfiles/shared"
lazygit="$dotfiles/lazygit/Library/Application Support/lazygit/config.yml"

printf '%s\n' "$theme" > "$dotfiles/theme/theme.txt"
printf '[flavor]\ndark = "%s"\nlight = "%s"\n' "$flavor" "$flavor" > "$dotfiles/yazi/.config/yazi/theme.toml"

# Classic had no lazygit theme, so the block is commented out rather than swapped.
if [ "$theme" = "classic" ]; then
  sed -i.bak '/# theme:start/,/# theme:end/{/# theme:/!s/^\([^#]\)/#~\1/;}' "$lazygit"
else
  sed -i.bak '/# theme:start/,/# theme:end/s/^#~//' "$lazygit"
fi
rm -f "$lazygit.bak"

echo "Theme set to $theme. Reload wezterm (save .wezterm.lua or restart), then reopen nvim, yazi, lazygit."
