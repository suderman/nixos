" Disable tmux navigator when zooming the Vim pane
let g:tmux_navigator_disable_when_zoomed = 1

" Create our own mappings
let g:tmux_navigator_no_mappings = 1

nnoremap <silent> <M-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <M-j> :TmuxNavigateDown<cr>
nnoremap <silent> <M-k> :TmuxNavigateUp<cr>
nnoremap <silent> <M-l> :TmuxNavigateRight<cr>
nnoremap <silent> <M-\> :TmuxNavigatePrevious<cr>

if has('nvim')
  tnoremap <silent> <M-h> <C-\><C-n> :TmuxNavigateLeft<cr>
  tnoremap <silent> <M-j> <C-\><C-n> :TmuxNavigateDown<cr>
  tnoremap <silent> <M-k> <C-\><C-n> :TmuxNavigateUp<cr>
  tnoremap <silent> <M-l> <C-\><C-n> :TmuxNavigateRight<cr>
  tnoremap <silent> <M-\> <C-\><C-n> :TmuxNavigatePrevious<cr>
endif
