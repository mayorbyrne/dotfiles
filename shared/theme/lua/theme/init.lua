local M = {}

function M.apply()
  local name = require("theme.active")
  if name == "classic" then
    vim.cmd.colorscheme("visual_studio_code")
    vim.cmd.highlight("DiagnosticUnderlineError guifg=#D64A4A gui=underline")
  else
    vim.cmd.colorscheme("elforest")
  end
end

return M
