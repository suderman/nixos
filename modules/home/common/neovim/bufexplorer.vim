" Shift-K toggles buffexplorer
command! BufExplorerBuffers call s:Buffers()
function! s:Buffers()
  let l:title = expand("%:t")
  if (l:title == '[BufExplorer]')
    :b#
  else
    :silent BufExplorer
  endif
endfunction
nmap <S-k> :BufExplorer<CR>
