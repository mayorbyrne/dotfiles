#!/usr/bin/env bash
# Writes ~/.config/wezterm/agent_state.txt for WezTerm tab/status badges.
# Usage: agent-state.sh <claude|agent|codex> [event]

set -euo pipefail

agent="${1:-}"
case "$agent" in
    claude|agent|codex) ;;
    *) exit 0 ;;
esac

payload="$(cat || true)"
event="${2:-}"
if [ -z "$event" ]; then
    event="$(printf '%s' "$payload" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
fi
if [ -z "$event" ]; then
    event="$(printf '%s' "$payload" | sed -n 's/.*"event"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
fi

status=""
case "$event" in
    UserPromptSubmit|beforeSubmitPrompt|PreToolUse|preToolUse) status="working" ;;
    StopFailure|postToolUseFailure) status="error" ;;
    sessionEnd) status="remove" ;;
    SessionStart|sessionStart|Stop|stop|afterAgentResponse) status="idle" ;;
    *) exit 0 ;;
esac

cwd="$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
if [ -z "$cwd" ]; then
    cwd="$(pwd)"
fi
cwd="$(printf '%s' "$cwd" | tr '\\' '/' | sed 's:/*$::')"
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) cwd="$(printf '%s' "$cwd" | tr '[:upper:]' '[:lower:]')" ;;
esac

if [ -z "$cwd" ]; then
    exit 0
fi

state_dir="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm"
state_file="$state_dir/agent_state.txt"
mkdir -p "$state_dir"

now="$(date +%s)"
stale_after="$((now - 21600))"
key="$agent|$cwd"
tmp="$(mktemp "$state_dir/agent_state.XXXXXX")"

previous_status=""
if [ -f "$state_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        name="${line%%|*}"
        rest="${line#*|}"
        line_cwd="${rest%%|*}"
        rest2="${rest#*|}"
        updated="${rest2#*|}"
        line_key="$name|$line_cwd"
        if [ "$line_key" = "$key" ]; then
            previous_status="${rest2%%|*}"
            continue
        fi
        if [ -n "$updated" ] && [ "$updated" -lt "$stale_after" ] 2>/dev/null; then
            continue
        fi
        printf '%s\n' "$line"
    done < "$state_file" > "$tmp"
else
    : > "$tmp"
fi

if [ "$status" != "remove" ]; then
    printf '%s|%s|%s|%s\n' "$agent" "$cwd" "$status" "$now" >> "$tmp"
fi

mv "$tmp" "$state_file"

if [ "$previous_status" = "working" ] && [ "$status" = "idle" ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send --app-name=WezTerm "$agent finished" "Return to the $agent tab" >/dev/null 2>&1 || true
    fi
fi
exit 0
