# programs.bluebubbles.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.bluebubbles;
  inherit (lib) mkIf;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "bluebubbles";

in {

  options.programs.bluebubbles = {
    enable = lib.options.mkEnableOption "bluebubbles"; 
  };

  config = mkIf cfg.enable {

    services.flatpak = {
      enable = true;
      apps = [ "app.bluebubbles.BlueBubbles" ];
    };

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "super.c" = "C-c";
      "super.v" = "C-v";
    };

    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [];
    };

  };

}
