# AI dotfiles sync - plan

Goal: sync Claude Code, Codex, and Cursor config across machines.
Status: Claude Code and Codex are done and linked on this machine. Cursor is not started.

## Decision

Git repo at `~/.dotfiles` plus symlinks into the real config locations.

The original plan called for a flat `claude/ codex/ cursor/` tree at the repo root
with its own `install.ps1` and `install.sh`. The repo had already moved to
`shared/` plus `pc/`, `linux/`, `mac/` overlays with one installer per OS, so the
AI config went into `shared/ai/` and `pc/ai/` instead, driven by
`shared/install/setup_ai_config.{ps1,sh}` which the existing OS installers call.
Same outcome, one installer per OS instead of two competing ones.

Alternative considered: `chezmoi` (better if the machine mix is Windows + macOS,
gives per-machine templating and secret-manager integration).
Rejected for now: plain git is simpler and enough.
Rejected outright: OneDrive/Dropbox sync. Conflicts on concurrent edit,
no history, and it puts credentials in a cloud folder.

## What shipped

```
shared/ai/
  claude/
    CLAUDE.md
    settings.json
    keybindings.json
    commands/i18n-extract.md
    skills/release-docs/
  codex/
    AGENTS.md
    config.toml
    rules/default.rules
    skills/artisan-mode/
pc/ai/
  claude/hooks/statusline.ps1
shared/install/
  setup_ai_config.ps1
  setup_ai_config.sh
```

See the AI config table in `README.md` for the full source-to-target link list.

Links are per file and per skill, never per directory, because the real config
folders mix hand-authored files with tool-generated ones
(`~/.claude/skills/synced/`, `~/.codex/skills/.system/`) and with plugin-provided
symlinks. Linking a whole directory would have swallowed all of it.

Both installers back up an existing real file to `<path>.bak-<timestamp>` before
linking, and delete only an existing symlink. No delete-before-link anywhere.

## What to sync vs ignore

Rule: hand-authored config syncs. Anything the tool generates, caches,
or authenticates with does not.

### Claude (`~/.claude`)

Sync: `CLAUDE.md`, `settings.json`, `keybindings.json`, plus the individual
hand-authored entries in `commands/`, `hooks/`, and `skills/`.

Not synced: `.credentials.json`, `settings.local.json`, `settings.json.bak`,
`history.jsonl`, `projects/`, `sessions/`, `session-env/`, `todos/`,
`shell-snapshots/`, `file-history/`, `paste-cache/`, `cache/`, `backups/`,
`downloads/`, `chrome/`, `ide/`, `daemon/`, `daemon.lock`,
`daemon.status.json`, `jobs/`, `plans/`, `memory/`, `telemetry/`,
`stats-cache.json`, `policy-limits.json*`, `remote-settings.json`,
`.last-cleanup`, `.last-update-result.json`, `.caveman-active*`,
`skills/synced/`, and the plugin symlinks in `commands/` and `skills/`.

`plugins/` is managed by the marketplace repo, not by dotfiles. See below.

### Codex (`~/.codex`)

Sync: `AGENTS.md`, `config.toml`, `rules/default.rules`, `skills/artisan-mode/`.

Not synced: `auth.json`, `history.jsonl`, `session_index.jsonl`, `sessions/`,
all `*.sqlite` plus their `-shm`/`-wal` siblings (goals, logs, memories,
queue, state, thread_history), `cache/`, `models_cache.json`, `packages/`,
`tmp/`, `.tmp/`, `.sandbox/`, `.sandbox-bin/`, `sandbox.*.log`,
`thread-writer-locks/`, `installation_id`, `cap_sid`, `version.json`,
`.personality_migration`, `.sandbox_migration`, `skills/.system/`.

`.gitignore` at the repo root carries guard patterns for the credential and
state filenames, so a stray copy cannot be committed by accident.

### Cursor

Still not inspected. `~/.cursor` was empty on this machine and
`%APPDATA%\Cursor\User` did not exist, so Cursor is not installed here.
Confirm the real paths on a machine that has it before writing the symlink list.

Expected locations:
- `%APPDATA%\Cursor\User\settings.json` and `keybindings.json` (Windows)
- `~/Library/Application Support/Cursor/User/...` (macOS)
- `~/.cursor/rules/` for project-agnostic rules
- `~/.cursor/mcp.json` for MCP servers

Ignore: `workspaceStorage/`, `globalStorage/` (except hand-edited files),
`History/`, `logs/`, anything holding a token.

Extensions: do not sync the extension folders. Export a list instead
(`cursor --list-extensions > shared/ai/cursor/extensions.txt`) and reinstall from it.

## Machine drift

Handled in the shipped config:

- Hardcoded `C:\Users\Q1524` paths in `settings.json` were replaced with
  `$USERPROFILE` and `$HOME`. Those hook commands run through a shell, so the
  expansion works on Windows (git bash) and on Linux/macOS alike.
- The `statusLine` command is wrapped in a file test, so it is a no-op where
  `statusline.ps1` is absent. Non-Windows machines override `statusLine` in
  `settings.local.json`.
- `settings.local.json` stays git-ignored and merges over the synced
  `settings.json`.

Still open:

- `shared/ai/codex/config.toml` holds per-project `trust_level` entries and a
  local marketplace path under `D:\git\`. Harmless on a machine with a different
  layout, but it is dead weight there. Codex has no documented local-override
  file, so this is unsolved rather than handled.
- Claude Code and Orca rewrite `settings.json` in place, and it is now a symlink,
  so those rewrites land in the repo as diffs. Expect churn.

## Plugins

The Quaver marketplace repo (`D:\git\Quaver-Claude-Plugin-Marketplace`)
already solves plugin sync, and the synced `settings.json` declares both
`extraKnownMarketplaces` and `enabledPlugins`, so a new machine picks them up
without a manual `claude plugin marketplace add`. Do not copy plugin content
into dotfiles, it would drift from the marketplace.

## Secrets

Never in the repo, even a private one. `auth.json` and `.credentials.json`
stay machine-local and get regenerated by logging in.
If templating is needed later, chezmoi can pull from a vault at apply time.

## Next steps

1. Confirm the Cursor config paths on a machine with Cursor installed, then add
   `shared/ai/cursor/` and extend both `setup_ai_config` scripts.
2. Test on a second machine from a clean clone. Not yet done: everything so far
   has only run on this Windows box.
3. Decide what to do about the machine-specific `[projects.*]` and
   `[marketplaces.*]` blocks in the synced `config.toml`.
