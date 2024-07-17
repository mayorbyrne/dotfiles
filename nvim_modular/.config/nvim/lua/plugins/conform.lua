return {
  {
    "stevearc/conform.nvim",
    config = function()
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
          ["lua"] = { "stylua" },
          ["scss"] = { "prettier" },
          ["typescriptreact"] = { "prettier" },
          ["yaml"] = { "prettier" },
          ["dart"] = { "dart" },
          ["vue"] = { "prettier "},
        },
        formatters = {
          stylua = {
            args = { "--config-path", "~/.config/nvim/stylua.toml" },
          },
          dart = {
            command = "dart",
            args = { "format", "--line-length", "300" },
          },
        },
      })

      local formatCode = function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end

      vim.keymap.set("n", "<leader>cf", formatCode, { desc = "Format code" })
    end,
  },
}
