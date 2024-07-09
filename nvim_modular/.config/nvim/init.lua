-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local opts = {}

require("options")

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
})

-- return {
--   {
--     'MunifTanjim/prettier.nvim',
--     config = function()
--       require('prettier').setup {
--         bin = 'prettier', -- or `'prettierd'` (v0.23.3+)
--         filetypes = {
--           'css',
--           'graphql',
--           'html',
--           'javascript',
--           'javascriptreact',
--           'json',
--           'less',
--           'markdown',
--           'scss',
--           'typescript',
--           'typescriptreact',
--           'yaml',
--         },
--       }
--     end,
--   },
--   {
--     'nvimdev/dashboard-nvim',
--     event = 'VimEnter',
--     config = function()
--       require('dashboard').setup {
--         theme = 'doom',
--         config = {
--           header = vim.split(
--             [[
--
--      *****                                                          
--   ******                                         *                  
--  **   *  *    **                  **            ***                 
-- *    *  *   **** *                **             *                  
--     *  *     ****                  **    ***                        
--    ** **    * **           ***      **    ***  ***     ***  ****    
--    ** **   *              * ***     **     ***  ***     **** **** * 
--    ** *****              *   ***    **      **   **      **   ****  
--    ** ** ***            **    ***   **      **   **      **    **   
--    ** **   ***          ********    **      **   **      **    **   
--    *  **    ***         *******     **      **   **      **    **   
--       *       ***       **          **      *    **      **    **   
--   ****         ***      ****    *    *******     **      **    **   
--  *  *****        ***  *  *******      *****      *** *   ***   ***  
-- *    ***           ***    *****                   ***     ***   *** 
-- *                                                                   
--
--
--
--
--
--
-- ]],
--             '\n'
--           ),
--           center = require 'custom.plugins.dashboard_center',
--           footer = function()
--             local stats = require('lazy').stats()
--             local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
--             return { '', '', '', '', '', 'Startup Time: ' .. ms .. ' ms', 'Plugins: ' .. stats.loaded .. ' loaded / ' .. stats.count .. ' installed' }
--           end,
--         },
--       }
--     end,
--   },
--   {
--     'tpope/vim-fugitive',
--   },
--   {
--     'nvim-tree/nvim-web-devicons',
--   },
--   {
--     "folke/trouble.nvim",
--     config = function()
--       require('trouble').setup {
--         modes = {
--           diagnostics = {
--             focus = true,
--           },
--         }
--       }
--   end
-- },
--   {
--     'echasnovski/mini.map',
--     version = false,
--     config = function()
--       require('mini.map').setup {}
--     end,
--   },
--   {
--     'ThePrimeagen/harpoon',
--     branch = 'harpoon2',
--     dependencies = { 'nvim-lua/plenary.nvim' },
--     config = function()
--       local harpoon = require 'harpoon'
--       harpoon:setup {}
--
--       vim.keymap.set('n', '<leader>ha', function()
--         harpoon:list():add()
--       end, { desc = 'Add current file to harpoon' })
--       vim.keymap.set('n', '<leader>hq', function()
--         harpoon.ui:toggle_quick_menu(harpoon:list())
--       end, { desc = 'Toggle harpoon list' })
--
--       -- Toggle previous & next buffers stored within Harpoon list
--       vim.keymap.set('n', '<leader>hp', function()
--         harpoon:list():prev()
--       end, { desc = 'Go to previous harpoon buffer' })
--       vim.keymap.set('n', '<leader>hn', function()
--         harpoon:list():next()
--       end, { desc = 'Go to next harpoon buffer' })
--     end,
--   },
--   {
--     'airblade/vim-rooter',
--     config = function()
--       vim.g.rooter_patterns = { '.git', '.gitignore', '.gitmodules', 'pubspec.yaml', 'package.json', 'CHANGELOG.md' }
--     end,
--   },
--   {
--     'christoomey/vim-tmux-navigator',
--     cmd = {
--       'TmuxNavigateLeft',
--       'TmuxNavigateDown',
--       'TmuxNavigateUp',
--       'TmuxNavigateRight',
--       'TmuxNavigatePrevious',
--     },
--     keys = {
--       { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
--       { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
--       { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
--       { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
--       { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
--     },
--   },
--   {
--     'preservim/vimux',
--     config = function() end,
--   },
--   {
--     'stevearc/oil.nvim',
--     opts = {},
--     config = function()
--       require('oil').setup()
--       vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
--     end
--   },
--   {
--     'NvChad/nvim-colorizer.lua',
--     config = function()
--       require('colorizer').setup()
--     end,
--   }
-- }
