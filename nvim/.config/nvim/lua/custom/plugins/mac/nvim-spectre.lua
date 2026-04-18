return {
  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("spectre").setup({
        replace_engine = {
          ["sed"] = {
            cmd = "sed",
            args = nil,
          },
        },
      })

      -- Keymaps
      vim.keymap.set("n", "<leader>frr", function()
        require("spectre").toggle()
      end, { desc = "[F]ind and [R]eplace in [R]epository (toggle)" })

      vim.keymap.set("n", "<leader>frw", function()
        require("spectre").open_visual({ select_word = true })
      end, { desc = "[F]ind and [R]eplace current [W]ord" })

      vim.keymap.set("v", "<leader>frv", function()
        require("spectre").open_visual()
      end, { desc = "[F]ind and [R]eplace [V]isual selection" })

      vim.keymap.set("n", "<leader>frf", function()
        require("spectre").open_file_search({ select_word = true })
      end, { desc = "[F]ind and [R]eplace in current [F]ile" })
    end,
  },
}
