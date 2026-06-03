# Copilot instructions for mayorbyrne/dotfiles

Purpose: Help future Copilot/Copilot CLI sessions understand this repository quickly so automation and code edits are accurate.

1) Build / test / lint commands
- This is a dotfiles repository; there is no unified build/test suite.
- Installation scripts: run the platform-specific installer in install_scripts/. Examples:
  - Windows (PowerShell): powershell -ExecutionPolicy Bypass -File .\install_scripts\pc\setup.ps1
  - Windows (batch): .\install_scripts\pc\setup.bat
  - macOS/Linux: bash ./install_scripts/mac/setup.sh  or bash ./install_scripts/linux/setup.sh
- Formatting tools used by parts of the repo:
  - stylua may be used for Neovim Lua files — run stylua over nvim lua files when editing them.

2) High-level architecture (big-picture)
- Purpose: personal configuration and dotfiles for shell, editors, terminals, and utilities.
- Top-level areas:
  - base/: Shell profiles and OS-entry scripts (e.g., Microsoft.PowerShell_profile.ps1, .zshrc, git-prompt.sh)
  - nvim/: Neovim configuration (primary). Use nvim/.config/nvim/ for editor configuration and plugin management.
  - install_scripts/: Platform setup scripts (pc/mac/linux) that symlink or copy config files and perform machine-specific steps.
  - snippets/: Editor snippet collections (VSCode/Vetur etc.) and package.json describing snippet sets.
  - fonts/: Local font files used by terminal/editor configs.
  - iterm2/, wezterm/, waybar/, starship/, tmux/: Per-tool configuration bundles.
- Plugin management: Plugin lockfiles (lazy-lock.json) may be present for Neovim; update them via the plugin manager rather than hand-editing.
- Git submodules: .gitmodules exists — watch for submodule-managed components when updating or syncing.

3) Key conventions and patterns (repo-specific)
- Editor config: nvim/ is the active Neovim configuration. Prefer editing nvim/.config/nvim/ files for changes.
- Custom plugin code and host overrides live under nvim/.config/nvim/lua/custom/. Keep plugin-specific tweaks there.
- Lockfiles: update lazy-lock.json and lazy-lock related files only via the plugin manager (don’t hand-edit unless necessary). Commit lockfile changes alongside plugin updates.
- Install scripts are the single-entry onboarding experience. Changes to file locations or new config files should be reflected in the appropriate install_scripts/* setup.
- OS-specific config lives under base/ and install_scripts/pc|mac|linux. Use the platform-specific installer when linking files.
- Snippets: packages and snippet sets are under snippets/ and snippets/snippets/; maintain structure to keep editors consuming them intact.

4) Where to look first when automating or making edits
- install_scripts/* for onboarding and file placement logic
- nvim/.config/nvim/ for editor changes
- base/ for shell and cross-platform profile changes
- .gitmodules and lazy-lock.json when diagnosing submodule or plugin version issues

5) AI / Assistant-related files checked
- No CLAUDE.md, AGENTS.md, .cursorrules, .windsurfrules, CONVENTIONS.md, or other assistant rules were found. If such files are added later, incorporate their content here.

Notes and do/don't
- Don’t attempt to run or assume tests — there are none. Assume changes are primarily configuration edits and follow install_scripts for correct placement.

If this file exists already, prefer appending or merging rather than replacing wholesale.
