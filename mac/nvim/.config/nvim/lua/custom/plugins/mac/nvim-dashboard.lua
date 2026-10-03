local kevin = require('custom.kevin')

local center = {
  {
    icon = ' ',
    icon_hl = 'DiagnosticHint',
    desc = 'New File           ',
    desc_hl = 'DiagnosticHint',
    key = 'n',
    key_format = ' %s', -- remove default surrounding `[]`
    action = 'ene',
  },
  {
    icon = ' ',
    icon_hl = 'DiagnosticHint',
    desc = 'Recent Files       ',
    desc_hl = 'DiagnosticHint',
    key = 'r',
    key_format = ' %s', -- remove default surrounding `[]`
    action = 'require("fzf-lua").oldfiles()',
  },
  {
    icon = ' ',
    icon_hl = 'DiagnosticHint',
    desc = 'Open Projects      ',
    desc_hl = 'DiagnosticHint',
    key = 'p',
    key_format = ' %s', -- remove default surrounding `[]`
    action = kevin.editCfg.openProjects,
  },
  {
    icon = ' ',
    icon_hl = 'DiagnosticHint',
    desc = 'Edit Config        ',
    desc_hl = 'DiagnosticHint',
    key = 'e',
    key_format = ' %s', -- remove default surrounding `[]`
    action = kevin.editCfg.editCfg,
  },
  {
    icon = " ",
    icon_hl = 'DiagnosticHint',
    desc = 'Edit Plugins',
    desc_hl = 'DiagnosticHint',
    key = 'u',
    key_format = ' %s', -- remove default surrounding `[]`
    action = kevin.editCfg.editPlugins
  },
  {
    icon = " ",
    icon_hl = 'DiagnosticHint',
    desc = 'Edit Config (Kevin)',
    desc_hl = 'DiagnosticHint',
    key = 'k',
    key_format = ' %s', -- remove default surrounding `[]`
    action = kevin.editCfg.editKevin,
  },
  {
    icon = ' ',
    icon_hl = 'DiagnosticHint',
    desc = 'Quit               ',
    desc_hl = 'DiagnosticHint',
    key = 'q',
    key_format = ' %s', -- remove default surrounding `[]`
    action = 'quit',
  },
}

return {
 {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
   require('dashboard').setup {
    theme = 'doom',
    config = {
     header = vim.split(
            [[
                                                                    
     *****                                                          
  ******                                         *                  
 **   *  *    **                  **            ***                 
*    *  *   **** *                **             *                  
    *  *     ****                  **    ***                        
   ** **    * **           ***      **    ***  ***     ***  ****    
   ** **   *              * ***     **     ***  ***     **** **** * 
   ** *****              *   ***    **      **   **      **   ****  
   ** ** ***            **    ***   **      **   **      **    **   
   ** **   ***          ********    **      **   **      **    **   
   *  **    ***         *******     **      **   **      **    **   
      *       ***       **          **      *    **      **    **   
  ****         ***      ****    *    *******     **      **    **   
 *  *****        ***  *  *******      *****      *** *   ***   ***  
*    ***           ***    *****                   ***     ***   *** 
*                                                                   






]],
      '\n'
     ),
     center = center,
     footer = function()
		local stats = require("lazy").stats()
		local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
		return {
			"",
			"",
			"",
			"",
			"",
			"Startup Time: " .. ms .. " ms",
			"Plugins: " .. stats.loaded .. " loaded / " .. stats.count .. " installed",
		}
     end,
    },
   }
  end,
 },
}
