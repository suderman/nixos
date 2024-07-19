# programs.gimp.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.gimp;
  inherit (lib) mkIf;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "gimp-2.99";

in {

  options.programs.gimp = {
    enable = lib.options.mkEnableOption "gimp"; 
  };

  config = mkIf cfg.enable {

    services.flatpak = {
      enable = true;
      beta = [ "org.gimp.GIMP" ]; # https://www.gimp.org/downloads/devel
    };

    xdg.desktopEntries."${class}" = {
      name = "GIMP"; 
      icon = "org.gimp.GIMP"; 
      noDisplay = true;
    };

    services.keyd.windows."${mkClass class}" = {};

    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [];
    };

  };

}
