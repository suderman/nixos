# programs.neovim.enable = true;
{ config, lib, pkgs, ... }: 

let
  cfg = config.programs.neovim;

in {

  config = lib.mkIf cfg.enable {

    programs.neovim = {

      viAlias = true;
      vimAlias = true;


      plugins = with pkgs.vimPlugins; [ 

        {
          plugin = vim-sensible;
          config = ''
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

            " Whitespace
            set nowrap
            set tabstop=2                           " number of visual spaces per tab
            set softtabstop=2                       " number of spaces in tab when editing
            set expandtab                           " tabs are spaces!
            set shiftwidth=2                        " how many spaces to indent/outdent

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
        
            " Use modeline overrides
            set modeline
            set modelines=10

            " Remap ; to : in visual mode
            nnoremap ; :

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
          '';
        }

        {
          plugin = ale;
          config = ''
            highlight ALEError ctermfg=Black ctermbg=Red
            highlight ALEWarning cterm=reverse
            let g:ale_sign_column_always = 1
            set mouse=a
            set mousemodel=popup_setpos
            nmap <silent> <C-k> <Plug>(ale_previous_wrap)
            nmap <silent> <C-j> <Plug>(ale_next_wrap
          '';
        }

        {
          plugin = lightline-vim;
          config = ''
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
          '';
        }

        {
          plugin = gruvbox-nvim;
          config = ''
            try 
              colorscheme gruvbox
              set background=dark
              catch
            endtry
          '';
        }

        {
          plugin = neoscroll-nvim;
          config = ''
            lua require('neoscroll').setup({ easing_function = "quadratic" })
          '';
        }

        {
          plugin = bufexplorer;
          config = ''
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
          '';
        }

        {
          plugin = vim-unimpaired;
          config = ''
            " Unimpaired - see all mappings at :help unimpaired
            " cob bgcolor cow softwrap, coc cursorline, cou cursorcolumn, con number, cor relativenumber
            " yp yP yo YO yI YA paste with paste toggled on
            " []x encode xml, []u encode url, []y encode C string
            " []b buffers, []f files, []<Space> blank lines
            " []e bubble multiple lines, visual mode mappings below:
            vmap _ [egv
            vmap + ]egv
          '';
        }

        {
          plugin = nerdtree;
          config = ''
            " NERDTree toggles with ,d
            map <Leader>d :NERDTreeToggle \| :silent NERDTreeMirror<CR>
            map <Leader>] :NERDTreeToggle \| :silent NERDTreeMirror<CR>
            map <Leader>dd :NERDTreeFind<CR>
            map <Leader>]] :NERDTreeFind<CR>
            let NERDTreeIgnore=['\.rbc$', '\~$', '\.xmark\.']
            let NERDTreeDirArrows=1
            let NERDTreeMinimalUI=1
            let NERDTreeShowHidden=1
          '';
        }

        nerdtree-git-plugin

        {
          plugin = nvim-tree-lua;
          config = ''
            lua << EOF
            -- disable netrw at the very start of your init.lua (strongly advised)
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            -- set termguicolors to enable highlight groups
            vim.opt.termguicolors = true

            -- empty setup using defaults
            require("nvim-tree").setup()
            EOF
          '';
        }

        nvim-web-devicons

        vim-surround
        vim-endwise
        vim-repeat
        vim-lastplace 
        vim-nix 
        delimitMate
        tcomment_vim
        align
        # syntastic
        nvim-fzf
      ]; 

      extraConfig = ''
        " F5 will remove trailing whitespace and tabs
        nnoremap <silent> <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl<CR>:retab<CR>

        " Clear search with comma-space
        noremap <leader><space> :noh<CR>:match none<CR>:2match none<CR>:3match none<CR>
      '';

    };

    # ALso make default editor
    # home.sessionVariables.EDITOR = lib.mkIf cfg.enable "vim";

  };

}
