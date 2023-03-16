# programs.neovim.enable = true;
{ config, lib, pkgs, ... }: {

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
        { plugin = nerdtree; config = builtins.readFile ./nerdtree.vim; }
        { plugin = nvim-tree-lua; config = builtins.readFile ./nvim-tree.vim; }
        { plugin = neoscroll-nvim; config = builtins.readFile ./neoscroll.vim; }
        nerdtree-git-plugin
        nvim-web-devicons
        vim-surround
        vim-endwise
        vim-repeat
        vim-lastplace 
        vim-nix 
        delimitMate
        tcomment_vim
        align
        nvim-fzf
      ]; 

    };

    # ALso make default editor
    home.sessionVariables.EDITOR = "nvim";

  };

}
