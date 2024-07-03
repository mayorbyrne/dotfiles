-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- LSP servers and clients are able to communicate to each other what features they support.
--  By default, Neovim doesn't support everything that is in the LSP specification.
--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

local lspconfig = require("lspconfig")
lspconfig.dartls.setup({
  capabilities = capabilities,
  -- on_attach = on_attach
  settings = {
    dart = {
      lineLength = 300,
    },
  },
})

-- If you are using mason.nvim, you can get the ts_plugin_path like this
local mason_registry = require("mason-registry")
local vue_language_server_path = mason_registry.get_package("vue-language-server"):get_install_path()
  .. "/node_modules/@vue/language-server"

lspconfig.tsserver.setup({
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = vue_language_server_path,
        languages = { "vue" },
      },
    },
  },
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
})

-- No need to set `hybridMode` to `true` as it's the default value
lspconfig.volar.setup({})

require("conform").setup({
  formatters_by_ft = {
    ["markdown"] = { "prettier" },
    ["markdown.mdx"] = { "prettier" },
    ["typescript"] = { "prettier" },
    ["css"] = { "prettier" },
    ["graphql"] = { "prettier" },
    ["html"] = { "prettier" },
    ["javascript"] = { "prettier" },
    ["javascriptreact"] = { "prettier" },
    ["json"] = { "prettier" },
    ["less"] = { "prettier" },
    ["scss"] = { "prettier" },
    ["typescriptreact"] = { "prettier" },
    ["yaml"] = { "prettier" },
  },
  formatters = {
    stylua = {
      indent_type = "Spaces",
      indent_width = 2,
    },
  },
})
