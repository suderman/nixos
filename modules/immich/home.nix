# programs.immich.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.immich;
  inherit (lib) mkIf mkOption options types mkWebApp urlToClass slugify;

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
      "${slugify (urlToClass cfg.url)}" = {};
    };

  };

}
