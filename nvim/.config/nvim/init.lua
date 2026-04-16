vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.copilot_no_tab_map = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

if vim.loader then
  vim.loader.enable()
end

require("config.options")
require("config.pack")
require("config.plugins")
require("config.lsp")
require("config.keymaps")
require("config.autocmds")
require("config.commands")
