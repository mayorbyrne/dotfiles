return {
  {
    'stevearc/conform.nvim',
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
    end,
  }
}
