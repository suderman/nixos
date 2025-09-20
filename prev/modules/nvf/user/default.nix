# programs.neovim.enable = true;
{ config, lib, pkgs, inputs, ... }: let

  # cfg = config.programs.nvf;
  # inherit (pkgs) fetchFromGitHub;
  # inherit (lib) mkIf ls;
  #
  # plugins = {
  #   hyprland-vim-syntax = pkgs.vimUtils.buildVimPlugin {
  #     name = "hyprland-vim-syntax";
  #     src = pkgs.fetchFromGitHub {
  #       owner = "theRealCarneiro";
  #       repo = "hyprland-vim-syntax";
  #       rev = "71760fe0cad972070657b0528f48456f7e0027b2";
  #       sha256 = "hleDvq6lbP3KBzu6trV86hZqu8EnAJUatF2USnBQlyI=";
  #     };
  #   };
  #   goose-nvim = pkgs.vimUtils.buildVimPlugin rec {
  #     pname = "goose.nvim";
  #     version = "5a72d3b3f7a2a01d174100c8c294da8cd3a2aeeb";
  #     doCheck = false;
  #     src = pkgs.fetchFromGitHub {
  #       owner = "azorng";
  #       repo = pname;
  #       rev = version;
  #       sha256 = "sha256-jVWggPmdINFNVHJSCpbTZq8wKwGjldu6PNSkb7naiQE=";
  #     };
  #   };
  # };

in {

  # imports = [ inputs.nvf.homeManagerModules.default ] 
  #   ++ ls ./plugins;
  #
  # config = mkIf cfg.enable {
  #
  #   programs.nvf.settings.vim = {
  #     viAlias = false;
  #     vimAlias = true;
  #
  #     # theme = {
  #     #   enable = true;
  #     #   name = "catppuccin";
  #     #   style = "mocha";
  #     #   transparent = true;
  #     # };
  #
  #     extraPlugins = {
  #       hyprland-vim-syntax = {
  #         package = plugins.hyprland-vim-syntax;
  #         # setup = "require('hyprland-vim-syntax').setup {}";
  #       };
  #       # goose-nvim = {
  #       #   package = plugins.goose-nvim;
  #       #   setup = "require('goose').setup {}";
  #       # };
  #     };
  #
  #     goose.enable = true;
  #
  #     spellcheck.enable = true;
  #     autocomplete.nvim-cmp.enable = true;
  #     statusline.lualine.enable = true;
  #     # statusline.lualine.theme = "catppuccin";
  #
  #     withPython3 = true;
  #     lsp.enable = true;
  #     lsp.trouble.enable = true;
  #
  #     startPlugins = [
  #       "plenary-nvim"
  #     ];
  #
  #     languages = {
  #       nix.enable = true;
  #       php = {
  #         enable = true;
  #         lsp.enable = true;
  #         treesitter.enable = true;
  #       };
  #       python = {
  #         enable = true;
  #         lsp.enable = true;
  #         format.enable = true;
  #         format.type = "ruff";
  #         treesitter.enable = true;
  #       };
  #     };
  #
  #
  #     clipboard = {
  #       enable = true;
  #       providers.xclip.enable = true;
  #       providers.wl-copy.enable = true;
  #       registers = "unnamed";
  #     };
  #
  #     options = {
  #       shiftwidth = 2;
  #       tabstop = 2;
  #     };
  #
  #     keymaps = [
  #       {
  #         mode = "n";
  #         silent = true;
  #         key = ";";
  #         action = ":";
  #       }
  #     ];
  #
  #   };
  #
  #   # programs.neovim = {
  #   #
  #   #   viAlias = true;
  #   #   vimAlias = true;
  #   #
  #   #   extraLuaConfig = ''
  #   #     require("goose").setup({})
  #   #   '';
  #   #   # anti_conceal = { enabled = false },
  #   #
  #   #   package = pkgs.unstable.neovim-unwrapped;
  #   #
  #   #   plugins = with pkgs.unstable.vimPlugins; [ 
  #   #     { plugin = vim-sensible; config = builtins.readFile ./init.vim; }
  #   #     { plugin = ale; config = builtins.readFile ./ale.vim; }
  #   #     { plugin = lightline-vim; config = builtins.readFile ./lightline.vim; }
  #   #     { plugin = gruvbox-nvim; config = builtins.readFile ./gruvbox.vim; }
  #   #     { plugin = nightfox-nvim; config = builtins.readFile ./nightfox.vim; }
  #   #     { plugin = bufexplorer; config = builtins.readFile ./bufexplorer.vim; }
  #   #     { plugin = vim-unimpaired; config = builtins.readFile ./unimpaired.vim; }
  #   #     # { plugin = nerdtree; config = builtins.readFile ./nerdtree.vim; }
  #   #     { plugin = nvim-tree-lua; config = builtins.readFile ./nvim-tree.vim; }
  #   #     { plugin = neoscroll-nvim; config = builtins.readFile ./neoscroll.vim; }
  #   #     { plugin = vim-tmux-navigator; config = builtins.readFile ./vim-tmux-navigator.vim; }
  #   #     { plugin = fzf-lua; config = builtins.readFile ./fzf-lua.vim; }
  #   #     { plugin = orgmode; config = builtins.readFile ./orgmode.vim; }
  #   #     { plugin = render-markdown-nvim; }
  #   #
  #   #     align
  #   #     delimitMate
  #   #     nerdtree-git-plugin
  #   #     nvim-web-devicons
  #   #     ron-vim
  #   #     tcomment_vim
  #   #     todo-txt-vim
  #   #     vim-endwise
  #   #     vim-lastplace 
  #   #     vim-nix 
  #   #     vim-parinfer
  #   #     vim-repeat
  #   #     vim-surround
  #   #     yuck-vim
  #   #     plenary-nvim
  #   #
  #   #     (pkgs.vimUtils.buildVimPlugin {
  #   #       name = "hyprland-vim-syntax";
  #   #       src = pkgs.fetchFromGitHub {
  #   #         owner = "theRealCarneiro";
  #   #         repo = "hyprland-vim-syntax";
  #   #         rev = "71760fe0cad972070657b0528f48456f7e0027b2";
  #   #         sha256 = "hleDvq6lbP3KBzu6trV86hZqu8EnAJUatF2USnBQlyI=";
  #   #       };
  #   #     })
  #   #
  #   #     (pkgs.vimUtils.buildVimPlugin rec {
  #   #       pname = "goose.nvim";
  #   #       version = "5a72d3b3f7a2a01d174100c8c294da8cd3a2aeeb";
  #   #       doCheck = false;
  #   #       src = pkgs.fetchFromGitHub {
  #   #         owner = "azorng";
  #   #         repo = pname;
  #   #         rev = version;
  #   #         sha256 = "sha256-jVWggPmdINFNVHJSCpbTZq8wKwGjldu6PNSkb7naiQE=";
  #   #       };
  #   #     })
  #   #
  #   #   ]; 
  #   #
  #   # };
  #   #
  #   # # ALso make default editor
  #   # home.sessionVariables.EDITOR = "nvim";
  #   # home.packages = [ pkgs.goose-cli ];
  #
  # };

}
