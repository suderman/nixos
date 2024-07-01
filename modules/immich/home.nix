# programs.immich.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.immich;
  inherit (builtins) toString;
  inherit (lib) mkIf mkOption options types strings mkBefore mkWebApp toKeydClass;

in {

  options.programs.immich = {
    enable = options.mkEnableOption "immich"; 
    url = mkOption { type = types.str; default = "http://immich"; };
  };

  config = mkIf cfg.enable {

    # Web App
    xdg.desktopEntries = mkWebApp {
      name = "Immich";
      icon = ./immich.png; 
      inherit (cfg) url;
    };

    # Keyboard shortcuts
    services.keyd.applications = {
      "${toKeydClass cfg.url}" = {};
    };

  };

}
