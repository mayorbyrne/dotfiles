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

require("custom.plugins.mac.copilot")
require("custom.plugins.mac.indent-blankline")
require("custom.plugins.mac.null-ls")
require("custom.plugins.mac.prettier")
require("custom.plugins.mac.auto-save")
require("custom.plugins.mac.nvim-dashboard")
require("custom.plugins.mac.trouble")
require("custom.plugins.mac.harpoon")
require("custom.plugins.mac.tmux")

return {
  -- {
  --   'nvim-tree/nvim-web-devicons',
  -- },
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
      vim.api.nvim_set_hl(0, 'RainbowDelimiterYellow', { fg = "#FCD400", ctermfg = "White" })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterRed', {fg = "#DA70D6", ctermfg= 'White' })
      vim.api.nvim_set_hl(0, 'RainbowDelimiterBlue', { fg = "#179DFB", ctermfg = "White" })

      -- This module contains a number of default definitions
      local rainbow_delimiters = require("rainbow-delimiters")

      -- This sets up the colorized brackets ala vscode
      vim.g.rainbow_delimiters = {
        blacklist = { "html" },
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
  },
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        diagnostics = {
          enable = true,
          show_on_dirs = true,
        },
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 30,
          side = "right",
        },
        renderer = {
          group_empty = true,
          highlight_diagnostics = "all",
        },
        filters = {
          dotfiles = false,
        },
        update_focused_file = {
          -- enables the feature
          enable = true,
          -- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory
          -- only relevant when `update_focused_file.enable` is true
          update_cwd = true,
          -- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory
          -- only relevant when `update_focused_file.update_cwd` is true and `update_focused_file.enable` is true
          ignore_list = {}
        },
      })
    end
  },
  {
    "windwp/nvim-ts-autotag",
    opts = {
      -- Defaults
      enable_close = true,        -- Auto close tags
      enable_rename = true,       -- Auto rename pairs of tags
      enable_close_on_slash = false -- Auto close on trailing </
    },
    -- Also override individual filetype configs, these take priority.
    -- Empty by default, useful if one of the "opts" global settings
    -- doesn't work well in a specific filetype
    -- per_filetype = {
    --   ["html"] = {
    --     enable_close = false
    --   }
    -- }
  },
  {
    "folke/drop.nvim",
    opts = {
      screensaver = 1000 * 60 * 1,
      -- ...
    }
  },
}

  -- {
  --   'nvim-telescope/telescope-file-browser.nvim',
  --   dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
  -- },
  -- {
  --   'Mofiqul/vscode.nvim',
  --   config = function()
  --     local c = require("vscode.colors").get_colors()
  --     require("vscode").setup({
  --       -- Alternatively set style in setup
  --       -- style = 'light'
  --
  --       -- Enable transparent background
  --       transparent = true,
  --
  --       -- Enable italic comment
  --       italic_comments = true,
  --
  --       -- Underline `@markup.link.*` variants
  --       underline_links = true,
  --
  --       -- Disable nvim-tree background color
  --       disable_nvimtree_bg = true,
  --
  --       -- Override colors (see ./lua/vscode/colors.lua)
  --       color_overrides = {
  --         vscLineNumber = "#555555",
  --         vscLightBlue = "#8ccef2",
  --       },
  --
  --       -- Override highlight groups (see ./lua/vscode/theme.lua)
  --       group_overrides = {
  --         -- this supports the same val table as vim.api.nvim_set_hl
  --         -- use colors from this colorscheme by requiring vscode.colors!
  --         -- Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
  --         LineNr = { fg = "#7a7a7a", bg = c.vscNone, bold = false },
  --         CursorLineNr = { fg = "#bebebe", bg = c.vscNone, bold = true },
  --       },
  --     })
  --
  --     require("vscode").load()
  --
  --     local hl = vim.api.nvim_set_hl
  --     hl(0, "@string", { fg = "#c7866d" })
  --   end,
  -- },
