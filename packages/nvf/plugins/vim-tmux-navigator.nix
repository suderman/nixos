{ config, lib, pkgs, ...}: let

  inherit (lib) mkIf;
  cfg = config.vim.vim-tmux-navigator;

  # https://github.com/christoomey/vim-tmux-navigator
  package = pkgs.vimUtils.buildVimPlugin rec {
    pname = "vim-tmux-navigator";
    version = "412c474e97468e7934b9c217064025ea7a69e05e";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "christoomey";
      repo = pname;
      rev = version;
      sha256 = "sha256-czhzY1bauNd472osfUZSzsOEoGv9QhQBriF3ULkKNpY=";
    };
  };

  keymap = mode: key: action: {
    inherit mode key action;
    silent = true;
  };

in {

  options.vim = {
    vim-tmux-navigator.enable = lib.options.mkEnableOption "vim-tmux-navigator";
  };

  config.vim = mkIf cfg.enable {

    extraPlugins.vim-tmux-navigator = {
      inherit package;
    };

    # Disable tmux navigator when zooming the Vim pane
    globals.tmux_navigator_disable_when_zoomed = 1;

    # Create our own mappings
    globals.tmux_navigator_no_mappings = 1;

    keymaps = [

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

    ];

  };
}
