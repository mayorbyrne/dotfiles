return {
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        diagnostics = {
          enable = true,
          show_on_dirs = true,
        },
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 30,
          side = "right",
        },
        renderer = {
          group_empty = true,
          highlight_diagnostics = "all",
        },
        filters = {
          dotfiles = false,
        },
        update_focused_file = {
          -- enables the feature
          enable = true,
          -- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory
          -- only relevant when `update_focused_file.enable` is true
          update_cwd = true,
          -- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory
          -- only relevant when `update_focused_file.update_cwd` is true and `update_focused_file.enable` is true
          ignore_list = {},
        },
      })
    end,
  },
}
