{ config, lib, pkgs, ... }: let
  inherit (lib) mkDefault;
in {

  programs.mosh.enable = true;
  programs.neovim.enable = true;

}
