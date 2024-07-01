-- since this is just an example spec, don't actually load anything here and return an empty spec
if true then
  return {
    {
      "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
    },
    {
      "nvim-neo-tree/neo-tree.nvim",
      opts = {
        window = {
          position = "right",
        },
      },
    },
    {
      "rcarriga/nvim-notify",
      opts = {
        timeout = 2000,
        top_down = false,
      },
    },
    {
      "nvim-lspconfig",
      opts = {
        inlay_hints = { enabled = false },
      },
    },
    {
      "stevearc/conform.nvim",
      formatters = {
        stylua = {
          indent_type = "Spaces",
          indent_width = 2,
        },
      },
    },
    {

      "Pocco81/auto-save.nvim",
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
      "Mofiqul/vscode.nvim",
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
          },

          -- Override highlight groups (see ./lua/vscode/theme.lua)
          group_overrides = {
            -- this supports the same val table as vim.api.nvim_set_hl
            -- use colors from this colorscheme by requiring vscode.colors!
            -- Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
            LineNr = { fg = "#8f610a", bg = c.vscNone, bold = false },
            CursorLineNr = { fg = "#F2CB05", bg = c.vscNone, bold = true },
          },
        })
        require("vscode").load()
      end,
    },
    {
      "tpope/vim-fugitive",
    },
    {
      "nvim-tree/nvim-web-devicons",
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
      end,
    },
    {
      "echasnovski/mini.map",
      version = false,
      config = function()
        require("mini.map").setup({})
      end,
    },
    {
      "ThePrimeagen/harpoon",
      branch = "harpoon2",
      dependencies = { "nvim-lua/plenary.nvim" },
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
      "airblade/vim-rooter",
      config = function()
        vim.g.rooter_patterns = { ".git", ".gitignore", ".gitmodules", "pubspec.yaml", "package.json", "CHANGELOG.md" }
      end,
    },
    {
      "christoomey/vim-tmux-navigator",
      cmd = {
        "TmuxNavigateLeft",
        "TmuxNavigateDown",
        "TmuxNavigateUp",
        "TmuxNavigateRight",
        "TmuxNavigatePrevious",
      },
      keys = {
        { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
        { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
        { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
        { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
        { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
      },
    },
    {
      "preservim/vimux",
      config = function() end,
    },
    {
      "stevearc/oil.nvim",
      opts = {},
      config = function()
        require("oil").setup()
        vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
      end,
    },
  }
end

-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },

  -- change trouble config
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = { use_diagnostic_signs = true },
  },

  -- disable trouble
  { "folke/trouble.nvim", enabled = false },

  -- override nvim-cmp and add cmp-emoji
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },

  -- change some telescope options and a keymap to browse plugin files
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {},
      },
    },
  },

  -- add tsserver and setup with typescript.nvim instead of lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      init = function()
        require("lazyvim.util").lsp.on_attach(function(_, buffer)
          -- stylua: ignore
          vim.keymap.set( "n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
          vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
        end)
      end,
    },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- tsserver will be automatically installed with mason and loaded with lspconfig
        tsserver = {},
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
  },

  -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
  -- treesitter, mason and typescript.nvim. So instead of the above, you can use:
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
  -- would overwrite `ensure_installed` with the new value.
  -- If you'd rather extend the default config, use the code below instead:
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
      })
    end,
  },

  -- the opts function can also be used to change the default opts:
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, "😄")
    end,
  },

  -- or you can return new options to override all the defaults
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        --[[add your custom lualine config here]]
      }
    end,
  },

  -- use mini.starter instead of alpha
  { import = "lazyvim.plugins.extras.ui.mini-starter" },

  -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
  { import = "lazyvim.plugins.extras.lang.json" },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
      },
    },
  },
}
