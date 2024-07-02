# programs.lunasea.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.lunasea;
  inherit (lib) mkIf mkOption options types mkWebApp urlToClass slugify;

in {

  options.programs.lunasea = {
    enable = options.mkEnableOption "lunasea"; 
    url = mkOption { type = types.str; default = "http://lunasea"; };
  };

  config = mkIf cfg.enable {

    # Web App
    xdg.desktopEntries = mkWebApp {
      name = "LunaSea";
      icon = ./lunasea.png; 
      inherit (cfg) url;
    };

    # Keyboard shortcuts
    services.keyd.applications = {
      "${slugify (urlToClass cfg.url)}" = {};
    };

  };

}
