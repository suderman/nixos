# programs.immich.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.immich;
  inherit (lib) mkIf mkOption options types mkWebApp chromeClass;

in {

  options.programs.immich = {
    enable = options.mkEnableOption "immich"; 
    url = mkOption { type = types.str; default = "http://immich"; };
    platform = mkOption { type = types.str; default = "wayland"; };
  };

  config = mkIf cfg.enable {

    # Web App
    xdg.desktopEntries = mkWebApp {
      name = "Immich";
      icon = ./immich.png; 
      inherit (cfg) url platform;
    };

    # Keyboard shortcuts
    services.keyd.windows = {
      "${chromeClass cfg.url}" = {};
    };

  };

}
