local config_root = vim.fn.stdpath("config")

local edit = function(path)
  vim.cmd.edit(path)
end

vim.api.nvim_create_user_command("EditConfig", function()
  edit(config_root .. "\\init.lua")
end, { desc = "Edit init.lua" })

vim.api.nvim_create_user_command("EditKeymaps", function()
  edit(config_root .. "\\lua\\config\\keymaps.lua")
end, { desc = "Edit keymaps" })

vim.api.nvim_create_user_command("EditPlugins", function()
  edit(config_root .. "\\lua\\config\\plugins.lua")
end, { desc = "Edit plugin setup" })

vim.api.nvim_create_user_command("EditLsp", function()
  edit(config_root .. "\\lua\\config\\lsp.lua")
end, { desc = "Edit LSP config" })

vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, { desc = "Update vim.pack plugins" })
