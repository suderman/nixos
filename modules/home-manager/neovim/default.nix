# programs.neovim.enable = true;
{ config, lib, pkgs, ... }: 

let

  inherit (pkgs.vimUtils) buildVimPluginFrom2Nix;
  inherit (pkgs) fetchFromGitHub;

in {

  config = lib.mkIf config.programs.neovim.enable {

    programs.neovim = {

      package = pkgs.unstable.neovim-unwrapped;

      viAlias = true;
      vimAlias = true;

      plugins = with pkgs.unstable.vimPlugins; [ 
        { plugin = vim-sensible; config = builtins.readFile ./init.vim; }
        { plugin = ale; config = builtins.readFile ./ale.vim; }
        { plugin = lightline-vim; config = builtins.readFile ./lightline.vim; }
        { plugin = gruvbox-nvim; config = builtins.readFile ./gruvbox.vim; }
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

        # buildVimPluginFrom2Nix {
        (pkgs.vimUtils.buildVimPlugin {
          name = "hyprland-vim-syntax";
          src = pkgs.fetchFromGitHub {
            owner = "theRealCarneiro";
            repo = "hyprland-vim-syntax";
            rev = "254df6b476db5784bc6bfe3f612129b73dfc43b5";
            sha256 = "sx1NWPrZeA2J7D3k69GweeubqFSloytktAKd4eGiV6c=";
          };
        })

        # { plugin = vim-plug; config = builtins.readFile ./vim-plug.vim; }
      ]; 

    };

    # ALso make default editor
    home.sessionVariables.EDITOR = "nvim";

  };

}
