-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local nvim_lsp = require 'lspconfig'
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

nvim_lsp.dartls.setup {
  capabilities = capabilities,
  -- on_attach = on_attach
}

local kevin = require 'custom.kevin'

return {
  { 'github/copilot.vim' },
  {
    'nvim-telescope/telescope-file-browser.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {
      indent = {
        char = '┊',
      },
      whitespace = {
        remove_blankline_trail = false,
      },
      exclude = {
        filetypes = {
          'lspinfo',
          'packer',
          'checkhealth',
          'help',
          'man',
          'dashboard',
          '',
        },
      },
    },
  },
  {
    'jose-elias-alvarez/null-ls.nvim',
  },
  {
    'MunifTanjim/prettier.nvim',
    config = function()
      require('prettier').setup {
        bin = 'prettier', -- or `'prettierd'` (v0.23.3+)
        filetypes = {
          'css',
          'graphql',
          'html',
          'javascript',
          'javascriptreact',
          'json',
          'less',
          'markdown',
          'scss',
          'typescript',
          'typescriptreact',
          'yaml',
        },
      }
    end,
  },
  {
    'Pocco81/auto-save.nvim',
    config = function()
      require('auto-save').setup {
        condition = function(buf)
          if vim.bo[buf].filetype == 'harpoon' then
            return false
          else
            return true -- met condition(s), can save
          end
        end,
      }
    end,
  },
  {
    'Mofiqul/vscode.nvim',
    config = function()
      local c = require('vscode.colors').get_colors()
      require('vscode').setup {
        -- Alternatively set style in setup
        -- style = 'light'

        -- Enable transparent background
        transparent = true,

        -- Enable italic comment
        italic_comments = true,

        -- Underline `@markup.link.*` variants
        underline_links = true,

        -- Disable nvim-tree background color
        disable_nvimtree_bg = true,

        -- Override colors (see ./lua/vscode/colors.lua)
        color_overrides = {
          vscLineNumber = '#555555',
        },

        -- Override highlight groups (see ./lua/vscode/theme.lua)
        group_overrides = {
          -- this supports the same val table as vim.api.nvim_set_hl
          -- use colors from this colorscheme by requiring vscode.colors!
          -- Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
          LineNr = { fg = '#8f610a', bg = c.vscNone, bold = false },
          CursorLineNr = { fg = '#F2CB05', bg = c.vscNone, bold = true },
        },
      }
      require('vscode').load()
    end,
  },
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('dashboard').setup {
        theme = 'doom',
        config = {
          header = vim.split(
            [[
                                                                    
     *****                                                          
  ******                                         *                  
 **   *  *    **                  **            ***                 
*    *  *   **** *                **             *                  
    *  *     ****                  **    ***                        
   ** **    * **           ***      **    ***  ***     ***  ****    
   ** **   *              * ***     **     ***  ***     **** **** * 
   ** *****              *   ***    **      **   **      **   ****  
   ** ** ***            **    ***   **      **   **      **    **   
   ** **   ***          ********    **      **   **      **    **   
   *  **    ***         *******     **      **   **      **    **   
      *       ***       **          **      *    **      **    **   
  ****         ***      ****    *    *******     **      **    **   
 *  *****        ***  *  *******      *****      *** *   ***   ***  
*    ***           ***    *****                   ***     ***   *** 
*                                                                   






]],
            '\n'
          ),
          center = require 'custom.plugins.dashboard_center',
          footer = function()
            local stats = require('lazy').stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return { '', '', '', '', '', 'Startup Time: ' .. ms .. ' ms', 'Plugins: ' .. stats.loaded .. ' loaded / ' .. stats.count .. ' installed' }
          end,
        },
      }
    end,
  },
  {
    'tpope/vim-fugitive',
  },
  {
    'nvim-tree/nvim-web-devicons',
  },
  {
    "folke/trouble.nvim",
    config = function()
      require('trouble').setup {
        icons = {
          indent = {
            middle = " ",
            last = " ",
            top = " ",
            ws = "│  ",
          },
        },
        modes = {
          diagnostics = {
            focus = true,
            groups = {
              { "filename", format = "{file_icon} {basename:Title} {count}" },
            },
          },
        }
      }
  end
},
  {
    'echasnovski/mini.map',
    version = false,
    config = function()
      require('mini.map').setup {}
    end,
  },
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup {}

      vim.keymap.set('n', '<leader>ha', function()
        harpoon:list():add()
      end, { desc = 'Add current file to harpoon' })
      vim.keymap.set('n', '<leader>hq', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = 'Toggle harpoon list' })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set('n', '<leader>hp', function()
        harpoon:list():prev()
      end, { desc = 'Go to previous harpoon buffer' })
      vim.keymap.set('n', '<leader>hn', function()
        harpoon:list():next()
      end, { desc = 'Go to next harpoon buffer' })
    end,
  },
  {
    'airblade/vim-rooter',
    config = function()
      vim.g.rooter_patterns = { '.git', '.gitignore', '.gitmodules', 'pubspec.yaml', 'package.json', 'CHANGELOG.md' }
    end,
  },
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },
  {
    'preservim/vimux',
    config = function() end,
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    config = function()
      require('oil').setup()
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end
  },
  {
    'NvChad/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  }
}
