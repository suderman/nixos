" let mapleader = ","

call plug#begin('~/.local/share/nvim/site/plugged')

 " Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Any valid git URL is allowed
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Smooth scrolling
Plug 'karb94/neoscroll.nvim'

" Colorscheme
Plug 'morhetz/gruvbox'
Plug 'arcticicestudio/nord-vim'
Plug 'flazz/vim-colorschemes'

" Status line
Plug 'itchyny/lightline.vim'

" Quickly switch between buffers
Plug 'jlanzarotta/bufexplorer'

" Vim/Tmux integration
Plug 'christoomey/vim-tmux-navigator'
" Plug 'roxma/vim-tmux-clipboard'
" Plug 'jabirali/vim-tmux-yank'
Plug 'ojroques/vim-oscyank', {'branch': 'main'}

" Git
Plug 'tpope/vim-git'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'gregsexton/gitv'
Plug 'airblade/vim-gitgutter'

" Nerd Tree file management
Plug 'scrooloose/nerdtree'
Plug 'taiansu/nerdtree-ag'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'

" Fuzzy Finder
Plug 'junegunn/fzf.vim'

" Tim Pope's good stuff
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-obsession'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-repeat'

" Ruby/Rails 
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-bundler'

" Toml
Plug 'cespare/vim-toml', { 'branch': 'main' }

" Auto-close brackets, quotes, etc
Plug 'Raimondi/delimitMate'

" Command line mode mappings
Plug 'vim-utils/vim-husk'

" Find and Replace
Plug 'brooth/far.vim'

" Silver Searcher
Plug 'rking/ag.vim'

" Grep
Plug 'mhinz/vim-grepper'

" Easier cursor movement
Plug 'justinmk/vim-sneak'
Plug 'bkad/CamelCaseMotion'
Plug 'henrik/vim-indexed-search'

" Code commenter
Plug 'tomtom/tcomment_vim'

" Auto cd to project root
Plug 'airblade/vim-rooter'

" :Align
Plug 'tsaleh/vim-align'

" Syntax errors
Plug 'vim-syntastic/syntastic'

Plug 'mbbill/undotree'

" Syntax colors
Plug 'othree/html5.vim'
Plug 'blueyed/smarty.vim'
Plug 'lumiliet/vim-twig'
Plug 'vim-scripts/jade.vim'
Plug 'kchmck/vim-coffee-script'
Plug 'lchi/vim-toffee'
Plug 'vim-scripts/jQuery'
Plug 'hail2u/vim-css3-syntax'
Plug 'groenewege/vim-less'
Plug 'ekalinin/Dockerfile.vim'
Plug 'bwangel23/nginx-vim-syntax'
Plug 'vim-scripts/openvpn'
Plug 'othree/yajs.vim'
Plug 'othree/javascript-libraries-syntax.vim'
Plug 'mxw/vim-jsx'
Plug 'LnL7/vim-nix'
if has('Python')
  call minpac#add('valloric/MatchTagAlways')
endif

Plug 'jceb/vim-orgmode'



" Initialize plugin system
call plug#end()


" Basic stuff
set encoding=utf-8                     " always use the good encoding
set mouse=a                            " allow the mouse to be used
set title                              " set the window's title to the current filename
set visualbell                         " no more beeping from Vim
set cursorline                         " highlight current line
set fillchars=vert:│                   " Solid line for vsplit separator
set showmode                           " show what mode (Insert/Normal/Visual) is currently on
set timeoutlen=500
set number                             " show line numbers
set wildmode=list:longest,list:full
set redrawtime=10000

" Wrapped lines goes down/up to next row, rather than next line in file.
noremap j gj
noremap k gk

" Remap ; to : in visual mode
nnoremap ; :

" LightLine displays mode
set noshowmode
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head'
      \ },
      \ }

" Whitespace
set nowrap
set tabstop=2                           " number of visual spaces per tab
set softtabstop=2                       " number of spaces in tab when editing
set expandtab                           " tabs are spaces!
set shiftwidth=2                        " how many spaces to indent/outdent

" F5 will remove trailing whitespace and tabs
nnoremap <silent> <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl<CR>:retab<CR>

" Use modeline overrides
set modeline
set modelines=10

" Colors
try 
  colorscheme gruvbox
  set background=dark
  catch
endtry

" Remember last location in file
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g'\"" | endif

lua require('neoscroll').setup({ easing_function = "quadratic" })


" Visual shifting (builtin-repeat)
vmap < <gv
vmap > >gv

" Better visual block selecting
set virtualedit+=block
set virtualedit+=insert
set virtualedit+=onemore

" Hide buffers or auto-save?
set hidden       " allow unsaved buffers to be hidden

" Alt-tab between buffers
nnoremap <leader><leader> <C-^>

" Make 'Y' follow 'D' and 'C' conventions'
nnoremap Y y$

" sudo & write if you forget to sudo first
cmap w!! w !sudo tee % >/dev/null

" Let split windows be different sizes
set noequalalways

" Rewrap paragraph
noremap Q gqip

" :Man pages in Vim
runtime! ftplugin/man.vim

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

" If in Visual Mode, resize window instead of changing focus. Ctrl-[h,j,k,l]
vnoremap <c-j> <c-w>+
vnoremap <c-k> <c-w>-
vnoremap <c-h> <c-w><
vnoremap <c-l> <c-w>>

vnoremap <M-j> <c-w>+
vnoremap <M-k> <c-w>-
vnoremap <M-h> <c-w><
vnoremap <M-l> <c-w>>

" Let directional keys work in Insert Mode. Ctrl-[h,j,k,l]
inoremap <c-j> <Down>
inoremap <c-k> <Up>
inoremap <c-h> <Left>
inoremap <c-l> <Right>

" Cursor movement in command mode
cnoremap <c-j> <Down>
cnoremap <c-k> <Up>
cnoremap <c-h> <Left>
cnoremap <c-l> <Right>
cnoremap <c-x> <Del>
cnoremap <c-z> <BS>
cnoremap <c-v> <c-r>"

" Searching
set hlsearch
set ignorecase
set smartcase
set gdefault

" Clear search with comma-space
noremap <leader><space> :noh<CR>:match none<CR>:2match none<CR>:3match none<CR>

" fzf fuzzy finder
set rtp+=/work/.local/share/fzf
nnoremap <C-t> <ESC>:Files<CR>
" nnoremap <M-k> <ESC>:Buffers<CR>
nnoremap <C-M-t> <ESC>:Lines<CR>

" Find and Replace
nnoremap <M-f> <ESC>:Farp<CR>

" Use Ag instead of Grep when available
if executable("ag")
  set grepprg=ag\ -H\ --nogroup\ --nocolor
  nnoremap <leader>a :Ag ""<left>
endif

nnoremap <leader>g :Grepper<cr>
let g:grepper = { 'next_tool': '<leader>g' }

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

" Vim-Sneak (type s followed by two characters)
let g:sneak#label = 1
let g:sneak#s_next = 1

" Unimpaired - see all mappings at :help unimpaired
" cob bgcolor cow softwrap, coc cursorline, cou cursorcolumn, con number, cor relativenumber
" yp yP yo YO yI YA paste with paste toggled on
" []x encode xml, []u encode url, []y encode C string
" []b buffers, []f files, []<Space> blank lines
" []e bubble multiple lines, visual mode mappings below:
vmap _ [egv
vmap + ]egv

" syntastic
if exists("*SyntasticStatuslineFlag")
  set statusline+=%#warningmsg#
  set statusline+=%{SyntasticStatuslineFlag()}
  set statusline+=%*
  let g:syntastic_always_populate_loc_list = 1
  let g:syntastic_auto_loc_list = 1
  let g:syntastic_check_on_open = 1
  let g:syntastic_check_on_wq = 0
  " let g:syntastic_enable_signs=1
  " let g:syntastic_quiet_messages = {'level': 'warnings'}
endif

" git
autocmd BufReadPost fugitive://* set bufhidden=delete
autocmd User fugitive
  \ if fugitive#buffer().type() =~# '^\%(tree\|blob\)$' |
  \   nnoremap <buffer> .. :edit %:h<CR> |
  \ endif
let g:Gitv_DoNotMapCtrlKey = 1

" NERDTree toggles with ,d
map <Leader>d :NERDTreeToggle \| :silent NERDTreeMirror<CR>
map <Leader>] :NERDTreeToggle \| :silent NERDTreeMirror<CR>
map <Leader>dd :NERDTreeFind<CR>
map <Leader>]] :NERDTreeFind<CR>
let NERDTreeIgnore=['\.rbc$', '\~$', '\.xmark\.']
let NERDTreeDirArrows=1
let NERDTreeMinimalUI=1
let NERDTreeShowHidden=1

" https://github.com/ojroques/vim-oscyank
let g:oscyank_max_length = 1000000
let g:oscyank_silent = v:true
let g:oscyank_term = 'default'
autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | execute 'OSCYankReg "' | endif


" Local config
if filereadable("/usr/local/share/nvim/local.vim")
  source /usr/local/share/nvim/local.vim
endif
