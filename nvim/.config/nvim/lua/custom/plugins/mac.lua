-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local nvim_lsp = require("lspconfig")
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

nvim_lsp.dartls.setup({
  capabilities = capabilities,
  -- on_attach = on_attach
})

local kevin = require("custom.kevin")

return {
  {
    'nvim-pack/nvim-spectre',
    config = function()
      vim.keymap.set("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', {
        desc = "Toggle Spectre",
      })
      vim.keymap.set("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
        desc = "Search current word",
      })
      vim.keymap.set("v", "<leader>sw", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
        desc = "Search current word",
      })
      vim.keymap.set("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
        desc = "Search on current file",
      })
    end,
  },
  { 'github/copilot.vim' },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    opts = {
      debug = true, -- Enable debugging
      -- See Configuration section for rest
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
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
    'nvimtools/none-ls.nvim',
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.prettierd.with({
            settings = {
              singleAttributePerLine = true,
            },
          }),
        },
      })

      local formatCode = function()
        -- require("conform").format({ async = true, lsp_format = "fallback" })
        -- vim.lsp.buf.format({ async = true })
        vim.lsp.buf.format({ timeout_ms = 2000 }) -- 2 seconds
      end

      vim.keymap.set("", "<leader>cf", formatCode, { desc = "Format code" })
    end,
  },
  {
    'MunifTanjim/prettier.nvim',
    config = function()
      require("prettier").setup({
        bin = "prettierd", -- or `'prettierd'` (v0.23.3+)
        filetypes = {
          "css",
          "graphql",
          "html",
          "javascript",
          "javascriptreact",
          "json",
          "less",
          "markdown",
          "scss",
          "typescript",
          "typescriptreact",
          "yaml",
        },
      })
    end,
  },
  {
    'Pocco81/auto-save.nvim',
    config = function()
      require("auto-save").setup({
        condition = function(buf)
          if vim.bo[buf].filetype == "harpoon" then
            return false
          else
            return true -- met condition(s), can save
          end
        end,
      })
    end,
  },
  {
    'Mofiqul/vscode.nvim',
    config = function()
      local c = require("vscode.colors").get_colors()
      require("vscode").setup({
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
          vscLineNumber = "#555555",
          vscLightBlue = "#8ccef2",
        },

        -- Override highlight groups (see ./lua/vscode/theme.lua)
        group_overrides = {
          -- this supports the same val table as vim.api.nvim_set_hl
          -- use colors from this colorscheme by requiring vscode.colors!
          -- Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
          LineNr = { fg = "#7a7a7a", bg = c.vscNone, bold = false },
          CursorLineNr = { fg = "#bebebe", bg = c.vscNone, bold = true },
        },
      })

      require("vscode").load()

      local hl = vim.api.nvim_set_hl
      hl(0, "@string", { fg = "#c7866d" })
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
            local stats = require("lazy").stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return {
              "",
              "",
              "",
              "",
              "",
              "Startup Time: " .. ms .. " ms",
              "Plugins: " .. stats.loaded .. " loaded / " .. stats.count .. " installed",
            }
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
      require("trouble").setup({
        modes = {
          diagnostics = {
            focus = true,
          },
        },
      })
    end
  },
  {
    'echasnovski/mini.map',
    version = false,
    config = function()
      require("mini.map").setup({})
    end,
  },
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup({})

      vim.keymap.set("n", "<leader>ha", function()
        harpoon:list():add()
      end, { desc = "Add current file to harpoon" })
      vim.keymap.set("n", "<leader>hq", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Toggle harpoon list" })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set("n", "<leader>hp", function()
        harpoon:list():prev()
      end, { desc = "Go to previous harpoon buffer" })
      vim.keymap.set("n", "<leader>hn", function()
        harpoon:list():next()
      end, { desc = "Go to next harpoon buffer" })
    end,
  },
  {
    'airblade/vim-rooter',
    config = function()
      vim.g.rooter_patterns = { ".git", ".gitignore", ".gitmodules", "pubspec.yaml", "package.json", "CHANGELOG.md" }
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
      { '<c-h>',  '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>',  '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>',  '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>',  '<cmd><C-U>TmuxNavigateRight<cr>' },
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
      require("oil").setup()
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end
  },
  {
    'NvChad/nvim-colorizer.lua',
    config = function()
      require("colorizer").setup()
    end,
  },
  -- {
  --   "stevearc/conform.nvim",
  --   config = function()
  --     require("conform").setup({
  --
  --       formatters_by_ft = {
  --         ["markdown"] = { "prettierd" },
  --         ["markdown.mdx"] = { "prettierd" },
  --         ["typescript"] = { "prettierd" },
  --         ["css"] = { "prettierd" },
  --         ["graphql"] = { "prettierd" },
  --         ["html"] = { "prettierd" },
  --         ["javascript"] = { "prettierd" },
  --         ["javascriptreact"] = { "prettierd" },
  --         ["json"] = { "prettierd" },
  --         ["less"] = { "prettierd" },
  --         ["lua"] = { "stylua" },
  --         ["scss"] = { "prettierd" },
  --         ["typescriptreact"] = { "prettierd" },
  --         ["yaml"] = { "prettierd" },
  --         ["dart"] = { "dart" },
  --         ["vue"] = { "prettierd" },
  --       },
  --       formatters = {
  --         stylua = {
  --           args = { "--config-path", "~/.config/nvim/stylua.toml" },
  --         },
  --         dart = {
  --           command = "dart",
  --           args = { "format", "--line-length", "300" },
  --         },
  --       },
  --     })
  --
  --     local formatCode = function()
  --       -- require("conform").format({ async = true, lsp_format = "fallback" })
  --       -- vim.lsp.buf.format({ async = true })
  --     end
  --
  --     vim.keymap.set("", "<leader>cf", formatCode, { desc = "Format code" })
  --   end,
  -- },
  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   priority = 1000,
  --   config = function()
  --     require("catppuccin").setup({
  --       custom_highlights = function()
  --         return {
  --           Comment = { fg = "#7DAB79" },
  --         }
  --       end,
  --       color_overrides = {
  --         mocha = {
  --           base = "#000000",
  --           mantle = "#000000",
  --           crust = "#000000",
  --         },
  --       },
  --     })
  --     vim.cmd.colorscheme("catppuccin")
  --   end,
  -- },
  {
    "mayorbyrne/dart-checkForSdkUpdates.nvim",
    ft = "dart",
    config = function()
      require("dart-checkForSdkUpdates").setup()
    end,
  },
  {
    "ibhagwan/fzf-lua",
    config = function()
      require("fzf-lua").setup({
        keymap = {
          fzf = {
            ['CTRL-Q'] = 'select-all+accept',
          }
        },
        winopts = {
          fullscreen = true,
          preview = {
            horizontal = "right:20%",
          }
        }
      })
      vim.keymap.set("n", "<c-P>", "<cmd>lua require('fzf-lua').files()<CR>", { silent = true })
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
    -- use opts = {} for passing setup options
    -- this is equivalent to setup({}) function
  },
  {
    'HiPhish/rainbow-delimiters.nvim',
    config = function()
      vim.api.nvim_set_hl(0, 'RainbowDelimiterYellow', { fg = "#FFFF00", ctermfg = "White" })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterRed', {fg = '#ff00ff', ctermfg= 'White' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterBlue', { fg = "#0000FF", ctermfg = "White" })

      -- This module contains a number of default definitions
      local rainbow_delimiters = require("rainbow-delimiters")

      -- This sets up the colorized brackets ala vscode
      vim.g.rainbow_delimiters = {
        highlight = {
          "RainbowDelimiterYellow",
          "RainbowDelimiterRed",
          "RainbowDelimiterBlue",
          -- "RainbowDelimiterOrange",
          -- "RainbowDelimiterGreen",
          -- "RainbowDelimiterViolet",
          -- "RainbowDelimiterCyan",
        },
      }
    end,
  }
}
