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
        vim.lsp.buf.format({
          filter = function(client)
            print("client.name: " .. client.name)
            return client.name ~= "ts_ls" and client.name ~= "eslint" and client.name ~= "volar"
          end,
        })
      end

      vim.keymap.set("", "<leader>cf", formatCode, { desc = "Format code" })
    end,
  },
}
