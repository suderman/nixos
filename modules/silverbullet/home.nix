# programs.silverbullet.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.silverbullet;
  inherit (lib) mkIf mkOption options types mkWebApp urlToClass slugify;

in {

  options.programs.silverbullet = {
    enable = options.mkEnableOption "silverbullet"; 
    url = mkOption { type = types.str; default = "http://silverbullet"; };
  };

  config = mkIf cfg.enable {

    # Web App
    xdg.desktopEntries = mkWebApp {
      name = "SilverBullet";
      icon = ./silverbullet.png; 
      inherit (cfg) url;
    };

    # Keyboard shortcuts
    services.keyd.applications = {
      "${slugify (urlToClass cfg.url)}" = {
        "super.o" = "C-k"; # page picker
        "super.slash" = "C-slash"; # command pallete
      };
    };

  };

}
