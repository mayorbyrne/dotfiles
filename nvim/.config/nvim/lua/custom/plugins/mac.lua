local nvim_lsp = require("lspconfig")
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

nvim_lsp.dartls.setup({
  capabilities = capabilities,
  -- on_attach = on_attach
})

require("custom.kevin")
require("custom.plugins.mac.copilot")
require("custom.plugins.mac.indent-blankline")
require("custom.plugins.mac.null-ls")
require("custom.plugins.mac.prettier")
require("custom.plugins.mac.auto-save")
require("custom.plugins.mac.nvim-dashboard")
require("custom.plugins.mac.trouble")
require("custom.plugins.mac.harpoon")
require("custom.plugins.mac.tmux")
require("custom.plugins.mac.oil")
require("custom.plugins.mac.colorizer")
require("custom.plugins.mac.dart-checkForSdkUpdates")
require("custom.plugins.mac.fzf-lua")
require("custom.plugins.mac.nvim-autopairs")
require("custom.plugins.mac.rainbow-delimiters")
require("custom.plugins.mac.nvim-tree")
require("custom.plugins.mac.nvim-ts-autotag")
require("custom.plugins.mac.drop")
require("custom.plugins.mac.render-markdown")
require("custom.plugins.mac.workspace-diagnostics")
require("custom.plugins.mac.snippet-converter")

return {}
