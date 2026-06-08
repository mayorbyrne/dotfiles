Installation

Using packer.nvim:

use {
  'mayorbyrne/efficiency-coach',
  config = function()
    require('efficiency_coach').setup({
      auto_suggest_on_save = true, -- show suggestions after saving files
      auto_suggest_delay = 500,    -- debounce delay in ms
    })
  end
}

Usage

- :EfficiencyCoachSuggest — show suggestions (LSP + heuristics)
- :EfficiencyCoachPractice — open a floating practice buffer; edit and press <leader>a to apply edits back to the original buffer

Configuration

- auto_suggest_on_save (bool): run suggest() on BufWritePost (default: false)
- auto_suggest_delay (number): debounce for autosuggest in ms

Heuristics (prototype)

- Detects long functions and suggests extraction
- Suggests fixing long lines (>120 chars)
- Counts TODO comments and surfaces a suggestion if many exist

Notes

This is a prototype. Consider adding stronger heuristics and tests before publishing to a plugin registry.
