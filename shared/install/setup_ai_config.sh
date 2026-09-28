#!/usr/bin/env bash
# Links the hand-authored Claude Code, Codex, and Cursor config from this repo
# into ~/.claude, ~/.codex, and ~/.cursor. Tool-generated state (credentials,
# sessions, caches, synced skills, marketplace plugins) is left alone.
# Work-specific settings live outside the repo in ~/.config/dotfiles/ and are
# merged into ~/.claude/settings.json and ~/.codex/config.toml.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dotfiles_dir="$(cd "$script_dir/../.." && pwd)"
shared_ai="$dotfiles_dir/shared/ai"
stamp="$(date +%Y%m%d-%H%M%S)"

# Never delete real config blind. Move it aside so it can be recovered.
clear_target() {
    local target="$1"

    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
        rm -f "$target"
    elif [ -e "$target" ]; then
        mv "$target" "$target.bak-$stamp"
        echo "  Backed up existing $target -> $target.bak-$stamp"
    fi
}

link_config() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        echo "  Skipping $target (missing $source)"
        return
    fi

    clear_target "$target"
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

prompt_claude_overlay() {
    if [ -e "$claude_overlay" ] || [ ! -t 0 ]; then
        return
    fi

    local answer name url plugins
    read -r -p "Add a work plugin marketplace to Claude Code? (y/N): " answer
    case "$answer" in
        [yY]*) ;;
        *) return ;;
    esac

    read -r -p "  Marketplace name: " name
    read -r -p "  Marketplace git URL: " url
    read -r -p "  Plugins to enable (comma-separated, without @$name): " plugins
    if [ -z "$name" ] || [ -z "$url" ]; then
        echo "  Name and URL are required. Skipping overlay."
        return
    fi

    mkdir -p "$overlay_dir"
    jq -n --arg name "$name" --arg url "$url" --arg plugins "$plugins" '{
        extraKnownMarketplaces: {($name): {source: {source: "git", url: $url}}},
        enabledPlugins: ($plugins | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(. != ""))
            | map({key: "\(.)@\($name)", value: true}) | from_entries)
    }' > "$claude_overlay"
    echo "  Wrote $claude_overlay"
}

write_claude_settings() {
    local base="$shared_ai/claude/settings.json"
    local target="$claude_dir/settings.json"
    local merged="$target.tmp-$stamp"

    if [ -f "$claude_overlay" ]; then
        jq -s '.[0] * .[1]' "$base" "$claude_overlay" > "$merged"
    else
        jq . "$base" > "$merged"
    fi

    if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$merged" "$target"; then
        rm -f "$merged"
        echo "  $target is up to date"
        return
    fi

    clear_target "$target"
    mv "$merged" "$target"
    echo "  Wrote $target"
}

# Codex rewrites config.toml itself (trust entries, UI state), so it is seeded
# once and then left alone.
seed_codex_config() {
    local base="$shared_ai/codex/config.toml"
    local target="$codex_dir/config.toml"

    if [ -f "$target" ] && [ ! -L "$target" ]; then
        echo "  Kept existing $target"
        return
    fi

    clear_target "$target"
    # The overlay goes last, so it must hold only [tables], no top-level keys.
    if [ -f "$codex_overlay" ]; then
        { cat "$base"; echo; cat "$codex_overlay"; } > "$target"
    else
        cp "$base" "$target"
    fi
    echo "  Seeded $target"
}

if ! command -v jq > /dev/null 2>&1; then
    echo "ERROR: jq is required. Install it and rerun." >&2
    exit 1
fi

echo "Linking AI config (Claude Code, Codex, Cursor)..."

claude_dir="$HOME/.claude"
codex_dir="$HOME/.codex"
cursor_dir="$HOME/.cursor"
overlay_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
claude_overlay="$overlay_dir/claude.work.json"
codex_overlay="$overlay_dir/codex.work.toml"

prompt_claude_overlay
write_claude_settings
seed_codex_config

link_config "$shared_ai/AGENTS.md" "$claude_dir/CLAUDE.md"
link_config "$shared_ai/claude/keybindings.json" "$claude_dir/keybindings.json"
link_config "$shared_ai/claude/commands/i18n-extract.md" "$claude_dir/commands/i18n-extract.md"
link_config "$shared_ai/claude/skills/release-docs" "$claude_dir/skills/release-docs"
link_config "$shared_ai/AGENTS.md" "$codex_dir/AGENTS.md"
link_config "$shared_ai/codex/rules/default.rules" "$codex_dir/rules/default.rules"
link_config "$shared_ai/codex/skills/artisan-mode" "$codex_dir/skills/artisan-mode"
link_config "$shared_ai/AGENTS.md" "$cursor_dir/AGENTS.md"
link_config "$shared_ai/AGENTS.md" "$cursor_dir/rules/AGENTS.mdc"

echo "AI config linked."
echo "Rerun this script after changing shared/ai/claude/settings.json or $claude_overlay."
echo "The synced statusLine is Windows-only. On this OS, override statusLine in $claude_overlay."
