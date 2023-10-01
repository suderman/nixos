# modules.gnome.enable = true;
{ config, lib, pkgs, ... }:

let 

  cfg = config.modules.gnome;
  inherit (lib) mkIf;

in {

  options.modules.gnome = {
    enable = lib.options.mkEnableOption "gnome"; 
  };

  config = mkIf cfg.enable { };

}
