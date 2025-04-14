# programs.silverbullet.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.silverbullet;
  inherit (lib) mkIf mkOption options types;
  inherit (config.programs.chromium.lib) mkClass mkWebApp;

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
    services.keyd.windows = {
      "${mkClass cfg.url}" = {
        "super.o" = "C-k"; # page picker
        "super.p" = "C-slash"; # command pallete
        "super.r" = "C-A-r"; # reload system
        "super.t" = "C-S-f"; # search space
        "super.[" = "A-left"; # back 
        "super.]" = "A-right"; # forward 
      };
    };

  };

}
