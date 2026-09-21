#!/usr/bin/env bash
# Links the hand-authored Claude Code and Codex config from this repo into
# ~/.claude and ~/.codex. Tool-generated state (credentials, sessions, caches,
# synced skills, marketplace plugins) is left alone.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="$(cd "$script_dir/../.." && pwd)"
shared_ai="$dotfiles_dir/shared/ai"
stamp="$(date +%Y%m%d-%H%M%S)"

link_config() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        echo "  Skipping $target (missing $source)"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        rm -f "$target"
    elif [ -e "$target" ]; then
        # Never delete real config blind. Move it aside so it can be recovered.
        mv "$target" "$target.bak-$stamp"
        echo "  Backed up existing $target -> $target.bak-$stamp"
    fi

    ln -s "$source" "$target"

    # Git bash on Windows copies instead of linking, which would silently break
    # the sync and make a rerun back up its own copies.
    if [ ! -L "$target" ]; then
        echo "  ERROR: $target is not a symlink after ln -s." >&2
        echo "  This script is for Linux and macOS. On Windows run setup_ai_config.ps1." >&2
        exit 1
    fi

    echo "  Linked $target"
}

echo "Linking AI config (Claude Code, Codex)..."

claude_dir="$HOME/.claude"
codex_dir="$HOME/.codex"

link_config "$shared_ai/claude/CLAUDE.md" "$claude_dir/CLAUDE.md"
link_config "$shared_ai/claude/settings.json" "$claude_dir/settings.json"
link_config "$shared_ai/claude/keybindings.json" "$claude_dir/keybindings.json"
link_config "$shared_ai/claude/commands/i18n-extract.md" "$claude_dir/commands/i18n-extract.md"
link_config "$shared_ai/claude/skills/release-docs" "$claude_dir/skills/release-docs"
link_config "$shared_ai/codex/AGENTS.md" "$codex_dir/AGENTS.md"
link_config "$shared_ai/codex/config.toml" "$codex_dir/config.toml"
link_config "$shared_ai/codex/rules/default.rules" "$codex_dir/rules/default.rules"
link_config "$shared_ai/codex/skills/artisan-mode" "$codex_dir/skills/artisan-mode"

echo "AI config linked."
echo "The synced statusLine is Windows-only. On this OS, override statusLine in ~/.claude/settings.local.json."
