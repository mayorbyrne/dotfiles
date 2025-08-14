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
            -- print("client.name: " .. client.name)
            return client.name ~= "ts_ls" and client.name ~= "eslint" and client.name ~= "volar"
          end,
        })
      end

      local range_formatting = function()
        local start_row, _ = unpack(vim.api.nvim_buf_get_mark(0, "<"))
        local end_row, _ = unpack(vim.api.nvim_buf_get_mark(0, ">"))
        print(start_row)
        print(end_row)
        vim.lsp.buf.format({
          range = {
            ["start"] = { start_row, 0 },
            ["end"] = { end_row, 0 },
          },
          async = true,
        })
      end

      vim.keymap.set("", "<leader>cf", formatCode, { desc = "Format code" })
      vim.keymap.set("v", "<leader>cf", range_formatting, { desc = "Range Formatting" })
    end,
  },
}
