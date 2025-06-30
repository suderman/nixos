{ flake, pkgs, inputs, ... }: let
  inherit (flake.lib) ls;
  inherit (inputs.nvf.lib) neovimConfiguration;
in (neovimConfiguration {
  inherit pkgs;
  modules = (ls ./plugins) ++ (ls ./config); 
}).neovim
