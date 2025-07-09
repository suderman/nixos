{
  pkgs,
  flake,
  ...
}: let
  inherit (flake.lib) nmap tmap imap vmap;
in {
  # Navigate seamlessly between tmux panes and neovim windows
  vim.lazy.plugins.vim-tmux-navigator = {
    package = pkgs.vimPlugins.vim-tmux-navigator;
  };

  # Disable tmux navigator when zooming the Vim pane
  vim.globals.tmux_navigator_disable_when_zoomed = 1;

  # Create our own mappings
  vim.globals.tmux_navigator_no_mappings = 1;

  vim.keymaps = [
    # Navigate window focus. Alt-[h,j,k,l]
    (nmap "<M-h>" ":TmuxNavigateLeft<CR>" "Navigate focus left")
    (nmap "<M-j>" ":TmuxNavigateDown<CR>" "Navigate focus down")
    (nmap "<M-k>" ":TmuxNavigateUp<CR>" "Navigate focus up")
    (nmap "<M-l>" ":TmuxNavigateRight<CR>" "Navigate focus right")
    (nmap "<M-;>" ":TmuxNavigatePrevious<CR>" "Navigate focus previous")

    # Escape terminal insert mode. Alt-[h,j,k,l]
    (tmap "<M-h>" "<C-\\><C-n>" "Terminal normal mode")
    (tmap "<M-j>" "<C-\\><C-n>" "Terminal normal mode")
    (tmap "<M-k>" "<C-\\><C-n>" "Terminal normal mode")
    (tmap "<M-l>" "<C-\\><C-n>" "Terminal normal mode")
    (tmap "<M-;>" "<C-\\><C-n>" "Terminal normal mode")

    # Resize windows. Alt-[h,j,k,l]
    (nmap "<M-H>" "<c-w><" "Resize window left")
    (nmap "<M-J>" "<c-w>+" "Resize window down")
    (nmap "<M-K>" "<c-w>-" "Resize window up")
    (nmap "<M-L>" "<c-w>>" "Resize window right")

    # Resize windows in visual mode. Alt-[h,j,k,l]
    (vmap "<M-h>" "<c-w><" "Resize window left")
    (vmap "<M-j>" "<c-w>+" "Resize window down")
    (vmap "<M-k>" "<c-w>-" "Resize window up")
    (vmap "<M-l>" "<c-w>>" "Resize window right")

    # Cursor movement in command mode
    (imap "<M-h>" "<Left>" "Move cursor left")
    (imap "<M-j>" "<Down>" "Move cursor down")
    (imap "<M-k>" "<Up>" "Move cursor up")
    (imap "<M-l>" "<Right>" "Move cursor right")

    # Split windows
    (nmap "<leader>u" ":sp<CR>" "Split horizontal")
    (nmap "<leader>i" ":vs<CR>" "Split vertical")
    (nmap "<M-u>" ":sp<CR>" "Split horizontal")
    (nmap "<M-i>" ":vs<CR>" "Split vertical")
    (nmap "<M-U>" ":sp<CR>" "Split horizontal")
    (nmap "<M-I>" ":vs<CR>" "Split vertical")
    (nmap "gu" ":sp<CR>" "Split horizontal")
    (nmap "gi" ":vs<CR>" "Split vertical")

    # Quit split (window)
    (nmap "<leader>q" ":q<CR>" "Quit split")
    (nmap "<M-q>" ":q<CR>" "Quit split")
  ];

  vim.options.splitbelow = true; # horizontal splits will be below
  vim.options.splitright = true; # vertical splits will be to the right
  vim.options.splitkeep = "screen"; # reduce scroll during window split
}
