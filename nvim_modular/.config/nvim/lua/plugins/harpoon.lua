return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup({})

			vim.keymap.set("n", "<leader>ha", function()
				harpoon:list():add()
			end, { desc = "Add current file to harpoon" })
			vim.keymap.set("n", "<leader>hq", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Toggle harpoon list" })

			-- Toggle previous & next buffers stored within Harpoon list
			vim.keymap.set("n", "<leader>hp", function()
				harpoon:list():prev()
			end, { desc = "Go to previous harpoon buffer" })
			vim.keymap.set("n", "<leader>hn", function()
				harpoon:list():next()
			end, { desc = "Go to next harpoon buffer" })
		end,
	},
}
