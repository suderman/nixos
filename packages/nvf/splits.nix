{ lib, pkgs, ...}: let

  keymap = mode: key: action: {
    inherit mode key action;
    silent = true;
  };

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
    (keymap "n" "<M-h>" ":TmuxNavigateLeft<CR>")
    (keymap "n" "<M-j>" ":TmuxNavigateDown<CR>")
    (keymap "n" "<M-k>" ":TmuxNavigateUp<CR>")
    (keymap "n" "<M-l>" ":TmuxNavigateRight<CR>")
    (keymap "n" "<M-;>" ":TmuxNavigatePrevious<CR>")

    # Escape terminal insert mode. Alt-[h,j,k,l]
    (keymap "t" "<M-h>" "<C-\\><C-n>")
    (keymap "t" "<M-j>" "<C-\\><C-n>")
    (keymap "t" "<M-k>" "<C-\\><C-n>")
    (keymap "t" "<M-l>" "<C-\\><C-n>")
    (keymap "t" "<M-;>" "<C-\\><C-n>")

    # Resize windows. Alt-[h,j,k,l]
    (keymap "n" "<M-H>" "<c-w><")
    (keymap "n" "<M-J>" "<c-w>+")
    (keymap "n" "<M-K>" "<c-w>-")
    (keymap "n" "<M-L>" "<c-w>>")

    # Resize windows in visual mode. Alt-[h,j,k,l]
    (keymap "v" "<M-h>" "<c-w><")
    (keymap "v" "<M-j>" "<c-w>+")
    (keymap "v" "<M-k>" "<c-w>-")
    (keymap "v" "<M-l>" "<c-w>>")

    # Cursor movement in command mode
    (keymap "i" "<M-h>" "<Left>")
    (keymap "i" "<M-j>" "<Down>")
    (keymap "i" "<M-k>" "<Up>")
    (keymap "i" "<M-l>" "<Right>")

    # Split windows
    (keymap "n" "<leader>u" ":sp<CR>")
    (keymap "n" "<leader>i" ":vs<CR>")
    (keymap "n" "<M-U>" ":sp<CR>")
    (keymap "n" "<M-I>" ":vs<CR>")

  ];

  vim.options.splitbelow = true; # horizontal splits will be below
  vim.options.splitright = true; # vertical splits will be to the right
  vim.options.splitkeep = "screen"; # reduce scroll during window split

}
