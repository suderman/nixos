# programs.lunasea.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.lunasea;
  inherit (lib) mkIf mkOption options types mkWebApp chromeClass;

in {

  options.programs.lunasea = {
    enable = options.mkEnableOption "lunasea"; 
    url = mkOption { type = types.str; default = "http://lunasea"; };
    platform = mkOption { type = types.str; default = "wayland"; };
  };

  config = mkIf cfg.enable {

    # Web App
    xdg.desktopEntries = mkWebApp {
      name = "LunaSea";
      icon = ./lunasea.png; 
      inherit (cfg) url platform;
    };

    # Keyboard shortcuts
    services.keyd.windows = {
      "${chromeClass cfg.url}" = {};
    };

  };

}
