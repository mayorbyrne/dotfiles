local M = {}

local classic_green_colors = {
  __vscode_background = "#1a1f1b",
  __vscode_local_background = "#212822",
  __vscode_visual_color = "#2b5a3c",
  __vscode_fold_background = "#1f3326",
  __vscode_nontext_foreground = "#3a463d",
  __vscode_statusline_background = "#2e8b57",
  __vscode_onaction_cursor_line_background = "#2f3a32",
  __vscode_other_word_highlight_background = "#3f4a42",
  __vscode_extra_decorate_color = "#5fd7a0",
  __vscode_inactive_indent_guide_background = "#38443b",
  __vscode_onactive_indent_guide_background = "#5f7565",
  __vscode_inactive_table_background = "#26302a",
  __vscode_onactive_table_background = "#1a1f1b",
  __vscode_local_completion_scrollview_background = "#3f4a42",
  __vscode_local_completion_selected_background = "#0e4a2a",
  __vscode_global_window_scrollview_background = "#3a453d",
}

function M.apply()
  local name = require("theme.active")
  if name == "classic" or name == "classic-green" then
    local vscode = require("visual_studio_code")
    vscode.setup({})
    if name == "classic-green" then
      vscode._colors = vim.tbl_extend("force", vscode.get_colors(), classic_green_colors)
    end
    vim.cmd.colorscheme("visual_studio_code")
    vim.cmd.highlight("DiagnosticUnderlineError guifg=#D64A4A gui=underline")
  else
    vim.cmd.colorscheme("elforest")
  end
end

return M
