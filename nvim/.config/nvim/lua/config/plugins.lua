local have_nerd_font = vim.g.have_nerd_font == true

vim.cmd.colorscheme("visual_studio_code")
vim.cmd.highlight("DiagnosticUnderlineError guifg=#D64A4A gui=underline")

require("Comment").setup()

require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
})

local which_key = require("which-key")
which_key.setup({})
which_key.add({
  { "<leader>b", group = "[B]uffer" },
  { "<leader>c", group = "[C]ode" },
  { "<leader>d", group = "[D]ocument" },
  { "<leader>f", group = "[F]ind" },
  { "<leader>g", group = "[G]it" },
  { "<leader>q", group = "[Q]uickfix" },
  { "<leader>s", group = "[S]earch" },
  { "<leader>t", group = "[T]oggle" },
  { "<leader>w", group = "[W]orkspace" },
  { "<leader>x", group = "Diagnostics" },
})

require("todo-comments").setup({
  signs = false,
})

require("oil").setup({
  default_file_explorer = true,
  view_options = {
    show_hidden = true,
  },
})

require("trouble").setup({
  modes = {
    diagnostics = {
      focus = true,
    },
  },
  win = {
    position = "right",
    size = 40,
  },
})

local telescope_actions = require("telescope.actions")
require("telescope").setup({
  defaults = {
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
    layout_config = {
      prompt_position = "top",
      preview_width = 0.55,
    },
    mappings = {
      i = {
        ["<Esc>"] = telescope_actions.close,
      },
    },
  },
  pickers = {
    find_files = {
      hidden = true,
    },
    buffers = {
      sort_mru = true,
      ignore_current_buffer = true,
    },
  },
})

require("null-ls").setup({
  sources = {
    require("null-ls").builtins.formatting.stylua,
    require("null-ls").builtins.formatting.prettierd.with({
      filetypes = {
        "css",
        "graphql",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "less",
        "markdown",
        "scss",
        "typescript",
        "typescriptreact",
        "vue",
        "yaml",
      },
    }),
  },
})

require("mini.ai").setup({ n_lines = 500 })
require("mini.icons").setup()
require("mini.surround").setup()

local statusline = require("mini.statusline")
statusline.setup({ use_icons = have_nerd_font })
statusline.section_location = function()
  return "%2l:%-2v"
end

require("nvim-autopairs").setup({})

require("nvim-treesitter").setup({
  ensure_installed = {
    "bash",
    "c",
    "css",
    "dart",
    "diff",
    "gitcommit",
    "html",
    "javascript",
    "json",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "query",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "vue",
    "yaml",
  },
  auto_install = true,
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
})

local luasnip = require("luasnip")
luasnip.config.setup({})
require("luasnip.loaders.from_vscode").lazy_load()

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = "menu,menuone,noinsert",
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete({}),
    ["<C-l>"] = cmp.mapping(function()
      if luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      end
    end, { "i", "s" }),
    ["<C-h>"] = cmp.mapping(function()
      if luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "path" },
    { name = "buffer" },
  }),
  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = function(entry, item)
      local kind_icons = {
        Text = "󰉿",
        Method = "m",
        Function = "󰊕",
        Constructor = "",
        Field = "",
        Variable = "󰆧",
        Class = "󰌗",
        Interface = "",
        Module = "",
        Property = "",
        Unit = "",
        Value = "󰎠",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "",
        Color = "󰏘",
        File = "󰈙",
        Reference = "",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰇽",
        Struct = "",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "󰊄",
      }
      item.kind = kind_icons[item.kind] or item.kind
      item.menu = ({
        nvim_lsp = "[LSP]",
        luasnip = "[Snip]",
        path = "[Path]",
        buffer = "[Buf]",
      })[entry.source.name]
      return item
    end,
  },
})

cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

require("fidget").setup({})

require("render-markdown").setup({})

require("neotest").setup({
  adapters = {
    require("neotest-vitest")({
      command = "vitest",
      args = { "--run" },
      env = {
        NODE_ENV = "test",
      },
    }),
  },
})
