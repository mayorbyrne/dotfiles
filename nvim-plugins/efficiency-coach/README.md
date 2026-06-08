Efficiency Coach (Neovim prototype)

Features (prototype):
- :EfficiencyCoachSuggest — shows available LSP code actions as "efficiency suggestions" in a popup
- :EfficiencyCoachPractice — opens a floating, editable copy of the current buffer so you can practice rewriting the code; press <leader>a in the practice buffer to apply edits back to the original buffer

Notes and next steps:
- Integrate heuristics (git diff, edit history) to surface suggestions even when LSP has none
- Add targeted exercises: e.g., replace loops with map/filter, simplify regex, extract functions
- Add configurable keymaps, scope (selection / range), and automatic triggers (on save)
