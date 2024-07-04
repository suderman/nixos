# programs.neovim.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.neovim;
  inherit (pkgs) fetchFromGitHub;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {
    programs.neovim = {

      viAlias = true;
      vimAlias = true;

      package = pkgs.unstable.neovim-unwrapped;

      plugins = with pkgs.unstable.vimPlugins; [ 
        { plugin = vim-sensible; config = builtins.readFile ./init.vim; }
        { plugin = ale; config = builtins.readFile ./ale.vim; }
        { plugin = lightline-vim; config = builtins.readFile ./lightline.vim; }
        { plugin = gruvbox-nvim; config = builtins.readFile ./gruvbox.vim; }
        { plugin = nightfox-nvim; config = builtins.readFile ./nightfox.vim; }
        { plugin = bufexplorer; config = builtins.readFile ./bufexplorer.vim; }
        { plugin = vim-unimpaired; config = builtins.readFile ./unimpaired.vim; }
        # { plugin = nerdtree; config = builtins.readFile ./nerdtree.vim; }
        { plugin = nvim-tree-lua; config = builtins.readFile ./nvim-tree.vim; }
        { plugin = neoscroll-nvim; config = builtins.readFile ./neoscroll.vim; }
        { plugin = vim-tmux-navigator; config = builtins.readFile ./vim-tmux-navigator.vim; }
        { plugin = fzf-lua; config = builtins.readFile ./fzf-lua.vim; }
        nerdtree-git-plugin
        nvim-web-devicons
        vim-surround
        vim-endwise
        vim-repeat
        vim-lastplace 
        vim-nix 
        vim-parinfer
        yuck-vim
        ron-vim
        delimitMate
        tcomment_vim
        align

        (pkgs.vimUtils.buildVimPlugin {
          name = "hyprland-vim-syntax";
          src = pkgs.fetchFromGitHub {
            owner = "theRealCarneiro";
            repo = "hyprland-vim-syntax";
            rev = "254df6b476db5784bc6bfe3f612129b73dfc43b5";
            sha256 = "sx1NWPrZeA2J7D3k69GweeubqFSloytktAKd4eGiV6c=";
          };
        })

      ]; 

    };

    # ALso make default editor
    home.sessionVariables.EDITOR = "nvim";

  };

}
