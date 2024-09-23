return {
  {
    "nvimtools/none-ls.nvim",
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
}
