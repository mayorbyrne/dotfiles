local kevin = require('custom.kevin')

return {
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
    action = 'Telescope oldfiles',
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
