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
     center = require 'custom.plugins.dashboard_center',
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
