local telescope_builtin = require("telescope.builtin")

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(client, bufnr)
  local map = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
  end

  if client.name == "html" or client.name == "cssls" or client.name == "ts_ls" then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  map("gd", function()
    telescope_builtin.lsp_definitions({ reuse_win = true })
  end, "[G]oto [D]efinition")
  map("gr", telescope_builtin.lsp_references, "[G]oto [R]eferences")
  map("gI", telescope_builtin.lsp_implementations, "[G]oto [I]mplementation")
  map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  map("K", vim.lsp.buf.hover, "Hover documentation")
  map("<leader>D", telescope_builtin.lsp_type_definitions, "Type [D]efinition")
  map("<leader>ds", telescope_builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
  map("<leader>ws", telescope_builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
  map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
    local group = vim.api.nvim_create_augroup("lsp-highlight-" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = bufnr,
      group = group,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = bufnr,
      group = group,
      callback = vim.lsp.buf.clear_references,
    })
    vim.api.nvim_create_autocmd("LspDetach", {
      buffer = bufnr,
      group = group,
      callback = function()
        vim.lsp.buf.clear_references()
      end,
    })
  end

  if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
    map("<leader>th", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
    end, "[T]oggle Inlay [H]ints")
  end
end

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "cssls",
    "eslint",
    "html",
    "jsonls",
    "lua_ls",
    "tailwindcss",
    "ts_ls",
  },
  automatic_installation = true,
})

local servers = {
  lua_ls = {
    settings = {
      Lua = {
        completion = {
          callSnippet = "Replace",
        },
        diagnostics = {
          globals = { "vim" },
        },
      },
    },
  },
  ts_ls = {},
  eslint = {},
  html = {},
  cssls = {},
  jsonls = {},
  tailwindcss = {},
  dartls = {
    settings = {
      dart = {
        lineLength = 120,
      },
    },
  },
}

for server_name, server_config in pairs(servers) do
  server_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
  server_config.on_attach = on_attach
  vim.lsp.config(server_name, server_config)
  vim.lsp.enable(server_name)
end
