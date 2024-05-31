-- MAC SETTINGS --
vim.keymap.set('n', '<leader>cdd', ':Telescope file_browser path=~/Documents hidden=true<CR>')
vim.keymap.set('n', '<leader>cdg', ':Telescope file_browser path=~/Documents hidden=true<CR>')
vim.keymap.set('n', '<leader>cdcfg', ':tabe ~/.config/nvim/init.lua<CR>')

return {
  editCfg = 'edit ~/.config/nvim/init.lua',
  editKevin = 'edit ~/.config/nvim/lua/custom/kevin.lua',
  editPlugins = 'edit ~/.config/nvim/lua/custom/plugins/mac.lua',
  openProjects = 'Telescope file_browser path=~/Documents hidden=true',
}
