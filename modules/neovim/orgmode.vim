lua << EOF
require('orgmode').setup({
  org_agenda_files = {'~/Notes/*'},
  org_default_notes_file = '~/Notes/inbox.org',
})

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

EOF
