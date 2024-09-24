return {
  {
    "ibhagwan/fzf-lua",
    config = function()
      require("fzf-lua").setup({
        keymap = {
          fzf = {
            ["CTRL-Q"] = "select-all+accept",
          },
        },
        winopts = {
          fullscreen = true,
          preview = {
            horizontal = "right:20%",
          },
        },
      })
      vim.keymap.set("n", "<c-P>", "<cmd>lua require('fzf-lua').files()<CR>", { silent = true })
    end,
  },
}
